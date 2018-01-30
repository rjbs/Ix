use 5.24.0;
package Ix::Crunk::Agent;

use Moose::Role;

use experimental qw(lexical_subs signatures);

requires 'request_callback';

sub request ($self, $calls) {
  my $cb = $self->request_callback;
  $self->$cb($calls);
}

1;
