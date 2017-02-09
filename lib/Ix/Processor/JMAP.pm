use 5.20.0;
package Ix::Processor::JMAP;

use Moose::Role;
use experimental qw(signatures postderef);

use Safe::Isa;
use Try::Tiny;
use Time::HiRes qw(gettimeofday tv_interval);

use namespace::autoclean;

with 'Ix::Processor';

requires 'handler_for';

around handler_for => sub ($orig, $self, $method, @rest) {
  my $handler = $self->$orig($method, @rest);
  return $handler if $handler;

  my $h = $self->_dbic_handlers;
  return $h->{$method} if exists $h->{$method};

  return;
};

has _dbic_handlers => (
  is   => 'ro',
  lazy => 1,
  init_arg => undef,
  default => sub {
    my ($self) = @_;

    my %handler;

    my $source_reg = $self->schema_class->source_registrations;
    for my $moniker (keys %$source_reg) {
      my $rclass = $source_reg->{$moniker}->result_class;
      next unless $rclass->isa('Ix::DBIC::Result');
      my $key  = $rclass->ix_type_key;
      my $key1 = $rclass->ix_type_key_singular;

      # Wrap every call in a transaction; in the future we may
      # use stricter isolation levels...

      $handler{"get\u$key"} = sub ($self, $ctx, $arg = {}) {
        $ctx->schema->txn_do(sub {
          $ctx->schema->resultset($moniker)->ix_get($ctx, $arg);
        });
      };

      $handler{"get\u${key1}Updates"} = sub ($self, $ctx, $arg = {}) {
        $ctx->schema->txn_do(sub {
          $ctx->schema->resultset($moniker)->ix_get_updates($ctx, $arg);
        });
      };

      $handler{"set\u$key"} = sub ($self, $ctx, $arg) {
        # ix_set manages its own transactions. We cannot wrap it here.
        $ctx->schema->resultset($moniker)->ix_set($ctx, $arg);
      };

      if ($rclass->ix_get_list_enabled) {
        $handler{"get\u${key1}List"} = sub ($self, $ctx, $arg) {
          $ctx->schema->txn_do(sub {
            $ctx->schema->resultset($moniker)->ix_get_list($ctx, $arg);
          });
        };
        $handler{"get\u${key1}ListUpdates"} = sub ($self, $ctx, $arg) {
          $ctx->schema->txn_do(sub {
            $ctx->schema->resultset($moniker)->ix_get_list_updates($ctx, $arg);
          });
        };
      }
    }

    return \%handler;
  }
);

sub process_request ($self, $ctx, $calls) {
  my @results;

  my $call_start;

  CALL: for my $call (@$calls) {
    # On one hand, I am tempted to disallow ambiguous cids here.  On the other
    # hand, the spec does not. -- rjbs, 2016-02-11
    $call_start = [ gettimeofday ];

    my ($method, $arg, $cid) = @$call;

    my $handler = $self->handler_for( $method );

    unless ($handler) {
      push @results, [ error => { type => 'unknownMethod' }, $cid ];
      next CALL;
    }

    my @rv = try {
      $self->$handler($ctx, $arg);
    } catch {
      if ($_->$_DOES('Ix::Error')) {
        return $_;
      } else {
        warn $_;
        die $_;
      }
    };

    RV: for my $i (0 .. $#rv) {
      local $_ = $rv[$i];
      push @results, $_->$_DOES('Ix::Result')
                   ? [ $_->result_type, $_->result_arguments, $cid ]
                   : [ error => { type => 'garbledResponse' }, $cid ];

      if ($results[-1][0] eq 'error' && $i < $#rv) {
        # In this branch, we have a potential return value like:
        # (
        #   [ valid => ... ],
        #   [ error => ... ],
        #   [ valid => ... ],
        # );
        #
        # According to the JMAP specification ("§ Errors"), we shouldn't be
        # getting anything after the error.  So, remove it, but also file an
        # exception report. -- rjbs, 2016-02-11
        #
        # TODO: file internal error report -- rjbs, 2016-02-11
        last RV;
      }
    }
  } continue {
    my $call_end = [ gettimeofday ];

    # Just elapsed time for now
    $ctx->record_call_info($call->[0], {
      elapsed_seconds => tv_interval($call_start, $call_end),
    });
  }

  return \@results;
}

1;
