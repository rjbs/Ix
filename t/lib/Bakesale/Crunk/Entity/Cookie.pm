package Bakesale::Crunk::Entity::Cookie;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Entity::Instance', {
  rclass => 'Bakesale::Schema::Result::Cookie',
};

1;
