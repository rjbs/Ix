package Bakesale::Crunk::Entity::User;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk::Entity', {
  rclass => 'Bakesale::Schema::Result::User',
};

1;
