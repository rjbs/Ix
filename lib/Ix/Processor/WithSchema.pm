use 5.20.0;
package Ix::Processor::WithSchema;

use Moose::Role;
use experimental qw(signatures postderef);

use Ix::Context;

use namespace::autoclean;

with 'Ix::Processor';

around handler_for => sub ($orig, $self, $method, @rest) {
  my $h = $self->_dbic_handlers;
  return $h->{$method} if exists $h->{$method};
  return $self->$orig($method, @rest);
};

requires 'schema_class';

sub context_class { 'Ix::Context' }

sub get_context ($self, $arg) {
  Ix::Context->new({
    accountId => $arg->{accountId},
    schema    => $self->schema_class->connect($arg->{connect_info}->@*),
  });
}

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

      $handler{"get\u$key"} = sub ($self, $ctx, $arg = {}) {
        $ctx->schema->resultset($moniker)->ix_get($ctx, $arg);
      };

      $handler{"get\u${key1}Updates"} = sub ($self, $ctx, $arg = {}) {
        $ctx->schema->resultset($moniker)->ix_get_updates($ctx, $arg);
      };

      $handler{"set\u$key"} = sub ($self, $ctx, $arg) {
        $ctx->schema->resultset($moniker)->ix_set($ctx, $arg);
      };

    }

    return \%handler;
  }
);

1;
