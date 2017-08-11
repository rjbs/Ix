use v5.24.0;
package Ix::Crunk::Collection;

use Moose;
use experimental qw(lexical_subs signatures);

has crunk => (is => 'ro', required => 1);
has entity_class => (is => 'ro', required => 1);

sub create ($self, $properties) {
  my $col_name = $self->entity_class->collection_name;

  my $res = $self->crunk->request([
    [ "set\u$col_name" => { create => { item => $properties } } ],
  ]);

  my $res_arg = $res->single_sentence("${col_name}Set")->arguments;

  # TODO This all needs to be re-done in terms of create_batch from
  # previous arg. -- rjbs, 2017-08-10
  my $created     = $res_arg->{created};
  my $not_created = $res_arg->{notCreated};

  return $not_created->{item} if $not_created->{item};

  if ($created->{item}) {
    return $self->entity_class->new({
      collection => $self,
      accountId  => undef, # XXX
      properties => $created->{item},
    });
  }

  Carp::confess("not created and not not created!");
}

sub retrieve ($self, $id) {
  my $col_name = $self->entity_class->collection_name;

  my $res = $self->crunk->request([
    [ "get\u$col_name" => { ids => [ $id ] } ],
  ]);

  my $res_arg = $res->single_sentence("${col_name}")->arguments;

  # TODO This all needs to be re-done in terms of create_batch from
  # previous arg. -- rjbs, 2017-08-10
  my $got       = $res_arg->{list};
  my $not_found = $res_arg->{notFound};

  if ($got && @$got) {
    return $self->entity_class->new({
      collection => $self,
      accountId  => undef, # XXX
      properties => $got->[0],
    });
  }

  return if $not_found && @$not_found && $not_found->[0] eq $id;

  Carp::confess("not found and not not found!");
}

1;
