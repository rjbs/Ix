package Bakesale::Entity::Cake;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Entity::Instance', {
  rclass => 'Bakesale::Schema::Result::Cake',
};

1;
