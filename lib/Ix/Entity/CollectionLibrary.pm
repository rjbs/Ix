use 5.24.0;
package Ix::Entity::CollectionLibrary;

use Moose;

use experimental qw(signatures);

require Ix::Entity::Collection;

has collections => (
  required  => 1,
  traits    => [ 'Hash' ],
  handles   => {
    get_collection => 'get',
  }
);

sub _build_library ($self, $arg) {
  require Module::Runtime;

  my $col_for = {};
  my $library = $self->new({
    collections => $col_for,
  });

  for my $name ($arg->{collection_names}->@*) {
    my $class = join q{::}, $arg->{class_prefix}, $name;
    Module::Runtime::require_module($class);

    my $col_name = $class->collection_name;
    Carp::confess("something already handling $col_name")
      if $col_for->{$col_name};

    $col_for->{ $col_name } = Ix::Entity::Collection->new({
      library      => $library,
      entity_class => $class,
    });
  }

  return $library;
}

sub collection ($self, $name) {
  my $col = $self->get_collection($name);
  return $col if $col;
  Carp::confess("no collection for $name");
}

1;
