use v5.24.0;
package Ix::Crunk::Collection;

use Moose;
use experimental qw(lexical_subs signatures);

has crunk => (is => 'ro', required => 1);
has collection_name => (is => 'ro', required => 1);

sub create ($self, $properties) {
  my $col_name = $self->collection_name;

  my $res = $self->crunk->request([
    [ "set\u$col_name" => { create => { item => $properties } } ],
  ]);

  my $res_arg = $res->single_sentence("${col_name}Set")->arguments;

  # TODO This all needs to be re-done in terms of create_batch from
  # previous arg. -- rjbs, 2017-08-10
  my $created     = $res_arg->{created};
  my $not_created = $res_arg->{notCreated};

  return $created->{item}     if $created->{item};
  return $not_created->{item} if $not_created->{item};

  Carp::confess("not created and not not created!");
}

1;
