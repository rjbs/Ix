package Bakesale::Crunk::Entity::Cookie;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk::Entity', {
  rclass => 'Bakesale::Schema::Result::Cookie',
};

1;
