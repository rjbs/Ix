package Bakesale::Entity::CakeRecipe;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Entity::Instance', {
  rclass => 'Bakesale::Schema::Result::CakeRecipe',
};

1;
