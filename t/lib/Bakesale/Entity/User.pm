package Bakesale::Entity::User;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Entity::Instance', {
  rclass => 'Bakesale::Schema::Result::User',
};

1;
