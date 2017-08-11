use v5.24.0;
package Ix::Crunk::Entity;

use MooseX::Role::Parameterized;
use experimental qw(lexical_subs signatures);
use namespace::autoclean;

# I'm pretty sure we can get one from the other without a schema object.
# -- rjbs, 2017-08-10
parameter resultset_name => (required => 0);
parameter rclass         => (required => 1);

role {
  my $param   = shift;
  my $rclass  = $param->rclass;

  my $name;
  unless ($name = $param->resultset_name) {
    ($name) = $rclass =~ /([^:]+)\z/;
  }

  method resultset_name => sub { $name };

  method collection_name => sub { $rclass->ix_type_key };

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

  for my $column (keys $rclass->ix_property_info->%*) {
    method $column => sub {
      Carp::croak("Cannot assign a value to a read-only accessor") if @_ > 1;
      return  $_[0]->_properties->{$column};
    };
  }
};

1;
