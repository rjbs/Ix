use v5.24.0;
package Bakesale::TestInstance;
use Moose;

use experimental qw(lexical_subs signatures);

use Bakesale;
use Bakesale::Schema;
use JMAP::Tester;
use Test::PgMonger;

my %TEST_DBS;

END { $_->cleanup for $TEST_DBS{$$}->@*; }

state $Monger = Test::PgMonger->new;

has bakesale_args => (
  is => 'ro',
  default => sub {  {}  },
);

has test_db => (
  is   => 'ro',
  lazy => 1,
  default => sub {
    $Monger //= Test::PgMonger->new;

    my $test_db = $Monger->create_database({
      extra_sql_statements => [
        "CREATE EXTENSION IF NOT EXISTS citext;",
      ],
    });

    push $TEST_DBS{$$}->@*, $test_db;

    return $test_db;
  },
);

has processor => (
  is   => 'ro',
  lazy => 1,
  default => sub ($self, @) {
    my $db = $self->test_db;
    my $processor = Bakesale->new({
      $self->bakesale_args->%*,
      connect_info => [ $db->connect_info ],
    });

    $self->_set_schema( $processor->schema_connection );
    $self->schema->deploy;

    return $processor;
  },
);

has schema => (
  is => 'ro',
  lazy => 1,
  clearer => 'clear_schema',
  writer  => '_set_schema',
  default => sub ($self, @) {
    $self->processor; # will cause the setter to be called -- rjbs, 2017-08-10
    return $self->schema;
  },
);

has app => (
  is => 'ro',
  lazy => 1,
  default => sub ($self, @) {
    return Bakesale::App->new({
      transaction_log_enabled => 1,
      processor => $self->processor,
    });
  },
);

has api_uri => (
  is   => 'ro',
  lazy => 1,
  default => sub ($self, @) {
    state $n;
    $n++;
    LWP::Protocol::PSGI->register(
      $self->app->to_app,
      host => 'bakesale.local:' . $n
    );
    return "http://bakesale.local:$n/jmap";
  },
);

sub tester ($self) {
  my $jmap_tester = JMAP::Tester->new({
    api_uri => $self->api_uri,
  });
}

1;
