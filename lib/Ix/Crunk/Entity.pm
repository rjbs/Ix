use v5.24.0;
package Ix::Crunk::Entity;

use Moose::Role;
use experimental qw(lexical_subs signatures);

has collection => (is => 'ro', required => 1);

1;
