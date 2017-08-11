package Bakesale::Crunk::Entity::Cake;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk::Entity', {
  rclass => 'Bakesale::Schema::Result::Cake',
};

1;
