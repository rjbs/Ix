use 5.20.0;
use warnings;
use utf8;
use experimental qw(lexical_subs signatures postderef refaliasing);

use lib 't/lib';

use Bakesale;
use Bakesale::App;
use Bakesale::Schema;
use JSON;
use Test::Deep;
use Test::Deep::JType;
use Test::More;
use Unicode::Normalize;
use Data::Dumper;
use Process::Status;

my $ti = Bakesale::TestInstance->new;

\my %account = Bakesale::Test->load_trivial_account($ti->schema);

my $jmap_tester = $ti->authenticated_tester($account{users}{rjbs});

# For a different account
my $jmap_tester2 = JMAP::Tester->new({
  api_uri => $jmap_tester->api_uri,
});

$jmap_tester2->_set_cookie('bakesaleUserId', $account{users}{alh});

my %children;
my $parent_pid = $$;

# Each child needs to send us a different signal or we may miss a
# signal if more than one child sends it to us at the same time
my @SIGNALS = qw(USR1 USR2 TERM HUP);

my $signaled = 0;

for my $sig (@SIGNALS) {
  $SIG{$sig} = sub { $signaled++; };
}

sub with_child ($code) :prototype(&) {
  my $sig = shift @SIGNALS;

  my $res = fork;
  if ($res) {
    $children{$res} = 1;

    return $res;
  }

  # Let parent know we started
  kill $sig => $parent_pid;

  # unblock_child() will take us passed this
  sleep 30;

  $code->();

  # Signal our parent we're done
  kill $sig => $parent_pid;

  exit;
}

sub unblock_child ($child) {
  kill 'USR1' => $child;
}

sub end_child ($child) {
  kill 'KILL' => $child;
}

END {
  for my $k (keys %children) {
    waitpid($k, 0);
  }

  # Clean up $? or our test reports a failure
  exit;
}

# Get some initial state
my $res = $jmap_tester->request([
  [
    setCookies => {
      create => { raw => { type => 'dough', baked_at => undef } },
    },
  ],
]);

cmp_deeply(
  $res->single_sentence->arguments,
  superhashof({
    created => {
      raw => {
        id => re(qr/\S/),
        expires_at => ignore(),
        delicious => ignore(),
        external_id => ignore(),
        batch => ignore(),
      },
    },
  }),
  "created a cookie",
) or diag(explain($jmap_tester->strip_json_types( $res->as_pairs )));

my $state = $res->single_sentence->arguments->{newState};
ok(defined($state), 'got new state');

# Start 3 processes, 2 with the same accountId. Of the latter 2, have one
# do a setCakes then setCookies, and the other the reverse. This makes
# sure we don't deadlock by holding onto a lock for too long. All calls
# should succeed and the state should be bumped twice in the one account.

my $lock = with_child {
  my $schema = $ti->schema;

  $schema->txn_do(sub {
    $schema->storage->dbh->do("LOCK TABLE states IN ACCESS EXCLUSIVE MODE");

    # Let parent know we have the lock
    kill 'USR1' => $parent_pid;

    # main proc will take us passed this
    sleep 60;
  });
};

while (!$signaled) {
  note("waiting for locker to start up\n");
  sleep 1;
}

$signaled = 0;

unblock_child($lock);

while (!$signaled) {
  note("waiting for locker to lock\n");
  sleep 1;
}

$signaled = 0;

# Our first set cookies
my $child1 = with_child {
  my $res = $jmap_tester->request([
    [
      setCookies => {
        create => { raw => { type => 'first', baked_at => undef } },
      },
    ],
    [
      setCakes   => {
        create => { raw => { type => 'first', layer_count => 4, recipeId => $account{recipes}{1} } },
      },
    ],
  ]);

  if (! $res->sentence(0)->arguments->{created}) {
    die "Bad response: " . Dumper($res->as_stripped_struct);
  }
  if (! $res->sentence(1)->arguments->{created}) {
    die "Bad response: " . Dumper($res->as_stripped_struct);
  }
};

# Our second set cookies
my $child2 = with_child {
  my $res = $jmap_tester->request([
    [
      setCakes   => {
        create => { raw => { type => 'second', layer_count => 4, recipeId => $account{recipes}{1} } },
      },
    ], [
      setCookies => {
        create => { raw => { type => 'second', baked_at => undef } },
      },
    ],
  ]);

  if (! $res->sentence(0)->arguments->{created}) {
    die "Bad response: " . Dumper($res->as_stripped_struct);
  }
  if (! $res->sentence(1)->arguments->{created}) {
    die "Bad response: " . Dumper($res->as_stripped_struct);
  }
};

# A set cookies in a different account, should not be affected
my $child3 = with_child {
  my $res = $jmap_tester2->request([
    [
      setCookies => {
        create => { raw => { type => 'other', baked_at => undef } },
      },
    ],
    [
      setCakes   => {
        create => { raw => { type => 'other', layer_count => 4, recipeId => $account{recipes}{1} } },
      },
    ],
  ]);

  if (! $res->sentence(0)->arguments->{created}) {
    die "Bad response: " . Dumper($res->as_stripped_struct);
  }
  if (! $res->sentence(1)->arguments->{created}) {
    die "Bad response: " . Dumper($res->as_stripped_struct);
  }
};

while ($signaled != 3) {
  note("Waiting for our children to start up");
  sleep 1;
}

for my $child ($child1, $child2, $child3) {
  unblock_child($child);
}

note 'children are blocked on our lock, waiting a second and releasing';

sleep 1;

$signaled = 0;

end_child($lock);

my %exits;

# These have been freed up when we released the lock and should
# do their thing then exit
for my $pid ($child1, $child2, $child3) {
  ok(waitpid($pid, 0), "child exited");
}

# And they should have signaled us before exiting
is($signaled, 3, 'children report they are complete');

# This should give us two cookies, state increased by 1
$res = $jmap_tester->request([
  [ getCookieUpdates => {
    sinceState   => $state,
  } ],
]);

my $new_state = $res->sentence(0)->arguments->{newState};
is($new_state, $state + 2, "state bumped twice");

my @changed = $res->sentence(0)->arguments->{changed}->@*;
is (@changed, 2, 'two cookies created')
  or diag explain $res->as_stripped_struct;

# This should give us one cookie, state increased by 1
$res = $jmap_tester->request([
  [ getCookieUpdates => {
    sinceState  => $state + 1,
  } ],
]);

$new_state = $res->sentence(0)->arguments->{newState};
is($new_state, $state + 2, "state bumped twice");

@changed = $res->sentence(0)->arguments->{changed}->@*;
is (@changed, 1, 'one cookie created')
  or diag explain $res->as_stripped_struct;

done_testing;
