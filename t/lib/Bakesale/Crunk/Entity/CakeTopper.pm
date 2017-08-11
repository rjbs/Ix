package Bakesale::Crunk::Entity::CakeTopper;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk::Entity', {
  rclass => 'Bakesale::Schema::Result::CakeTopper',
};

1;
