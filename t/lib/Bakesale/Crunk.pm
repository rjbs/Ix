use v5.24.0;
package Bakesale::Crunk;

use Moose;
use experimental qw(lexical_subs signatures);

with 'Ix::Crunk';

sub collection;
Ix::Crunk::Util->load_crunk_plugins(qw( CakeRecipe ));
Ix::Crunk::Util->setup_collection_loader;

sub request_callback;
has request_callback => (is => 'ro', isa => 'CodeRef', required => 1);

1;
