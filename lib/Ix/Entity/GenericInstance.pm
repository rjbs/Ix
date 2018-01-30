use v5.24.0;
package Ix::Entity::GenericInstance;

use MooseX::Role::Parameterized;
use experimental qw(lexical_subs signatures);
use namespace::autoclean;

parameter property_names => (required => 1);

role {
  my $param   = shift;

  requires 'collection_name';

  has collection => (is => 'ro', required => 1);

  has accountId => (is => 'ro', required => 1);

  has properties => (
    reader    => '_properties',
    isa       => 'HashRef',
    required  => 1,
    traits    => [ 'Hash' ],
    handles   => {
      properties => 'elements',
    },
  );

  for my $column ($param->property_names->@*) {
    method $column => sub {
      Carp::croak("Cannot assign a value to a read-only accessor") if @_ > 1;
      return  $_[0]->_properties->{$column};
    };
  }
};

1;
