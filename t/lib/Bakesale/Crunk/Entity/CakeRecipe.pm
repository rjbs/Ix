package Bakesale::Crunk::Entity::CakeRecipe;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk::Entity';

sub collection_name { 'cakeRecipes' }

1;
