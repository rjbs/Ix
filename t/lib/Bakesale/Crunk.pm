use v5.24.0;
package Bakesale::Crunk;

# We need this loaded before the entity classes go crawling around the rclasses
# for property lists! -- rjbs, 2017-08-10
use Bakesale::Schema;

require Ix::Crunk;

my $cc = Ix::Crunk::CC->_cc_for_me(qw(
  Cake CakeRecipe CakeTopper Cookie User
));

sub collection {
  $cc->collection($_[1]);
}

1;
