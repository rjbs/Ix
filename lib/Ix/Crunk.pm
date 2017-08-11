use 5.24.0;
package Ix::Crunk;

use Moose::Role;

use experimental qw(lexical_subs signatures);

use Ix::Crunk::Collection;

requires 'request_callback';
requires 'collection';

sub request ($self, $calls) {
  my $cb = $self->request_callback;
  $self->$cb($calls);
}

package Ix::Crunk::Util {
  my %entities_for;

  sub load_crunk_plugins ($self, @names) {
    require Module::Runtime;
    my $pkg = caller;

    Carp::confess("already loaded plugins for $pkg") if $entities_for{$pkg};

    my $cache = $entities_for{$pkg} = {};

    for my $name (@names) {
      my $class = join q{::}, $pkg, 'Entity', $name;
      Module::Runtime::require_module($class);

      my $col_name = $class->collection_name;
      Carp::confess("something already handling $col_name")
        if $cache->{$col_name};

      $cache->{ $col_name } = $class;
    }

    return;
  }

  sub setup_collection_loader ($self) {
    my $pkg = caller;

    Carp::confess("doesn't seem like you ran load_crunk_plugins for $pkg")
      unless my $cache = $entities_for{$pkg};

    $pkg->meta->add_attribute(_collections => (
      is   => 'ro',
      lazy => 1,
      default => sub {  {}  },
    ));

    $pkg->meta->add_method(collection => sub ($self, $name) {
      my $col_col = $self->_collections;
      return $col_col->{ $name } if $col_col->{ $name };

      my $class = $cache->{$name};
      Carp::confess("no collection for $name") unless $class;

      my $col = Ix::Crunk::Collection->new({
        crunk => $self,
        entity_class => $class,
      });

      $col_col->{$name} = $col;
      Scalar::Util::weaken($col_col->{$name});

      return $col;
    });
  }
}

1;
