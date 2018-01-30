use 5.24.0;
package Ix::Entity::CollectionLibrary;

use Moose;

use experimental qw(signatures);

require Ix::Entity::Collection;

has collections => (
  is        => 'ro',
  required  => 1,
);

sub _cc_for_me ($self, @names) {
  require Module::Runtime;
  my $pkg = caller;

  my $col_for = {};
  my $cc = $self->new({
    collections => $col_for,
  });

  for my $name (@names) {
    my $class = join q{::}, $pkg, 'Entity', $name;
    Module::Runtime::require_module($class);

    my $col_name = $class->collection_name;
    Carp::confess("something already handling $col_name")
      if $col_for->{$col_name};

    $col_for->{ $col_name } = Ix::Entity::Collection->new({
      # We will need a weak reference from collections back to the
      # collection collection for letting a Thing create a Subthing.  But not
      # yet. But that's why we have this convoluted thing where we've made
      # the object and are operating directly on a reference inside it.
      # Later, we'll need to have the object here to pass to the collection
      # constructor, or we'll maybe call ->register_collection or something.
      # -- rjbs, 2018-01-29
      entity_class => $class,
    });
  }

  return $cc;
}

sub collection ($self, $name) {
  my $col = $self->collections->{ $name };
  return $col if $col;
  Carp::confess("no collection for $name");
}

1;
