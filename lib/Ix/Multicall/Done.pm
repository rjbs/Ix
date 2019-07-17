package Ix::Multicall::Done;

use Moose;

sub execute {
  my ($self) = @_;

  return [ $self->result_cid_pairs ];
}

has call_ident => (
  is  => 'ro',
  isa => 'Str',
);

has result_cid_pairs => (
  isa => 'ArrayRef',
  traits   => [ 'Array' ],
  handles  => { result_cid_pairs => 'elements' },
  required => 1,
);

with 'Ix::Multicall';

no Moose;
__PACKAGE__->meta->make_immutable;
1;
