package Bakesale::Crunk::Entity::CakeTopper;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Entity::Instance', {
  rclass => 'Bakesale::Schema::Result::CakeTopper',
};

1;
