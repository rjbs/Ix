use v5.24.0;
package Ix::Entity::Instance;

use MooseX::Role::Parameterized;
use experimental qw(lexical_subs signatures);
use namespace::autoclean;

parameter rclass  => (required => 1);

role {
  my $param   = shift;
  my $rclass  = $param->rclass;

  method collection_name => sub { $rclass->ix_type_key };

  with 'Ix::Entity::GenericInstance' => {
    property_names => [ keys $rclass->ix_property_info->%* ]
  };
};

1;
