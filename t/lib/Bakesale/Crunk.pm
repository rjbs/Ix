use v5.24.0;
package Bakesale::Crunk;

use Moose;
use experimental qw(lexical_subs signatures);

# We need this loaded before the entity classes go crawling around the rclasses
# for property lists! -- rjbs, 2017-08-10
use Bakesale::Schema;

with 'Ix::Crunk';

sub collection;

Ix::Crunk::Util->load_crunk_plugins(qw(
  Cake CakeRecipe CakeTopper Cookie User
));

Ix::Crunk::Util->setup_collection_loader;

sub request_callback;
has request_callback => (is => 'ro', isa => 'CodeRef', required => 1);

1;
