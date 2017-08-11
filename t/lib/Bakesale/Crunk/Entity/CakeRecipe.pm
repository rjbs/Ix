package Bakesale::Crunk::Entity::CakeRecipe;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk::Entity', {
  rclass => 'Bakesale::Schema::Result::CakeRecipe',
};

1;
