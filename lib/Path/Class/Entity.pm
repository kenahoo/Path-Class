package Path::Class::Entity;

use strict;
use File::Spec;

use overload
  (
   q[""] => 'stringify',
   fallback => 1,
  );

sub new { bless {}, shift() }
  
sub is_absolute { File::Spec->file_name_is_absolute(shift) }

sub cleanup {
  my $self = shift;
  my $cleaned = ref($self)->new( File::Spec->canonpath($self) );
  %$self = %$cleaned;
  return $self;
}

sub absolute {
  my $self = shift;
  return $self if $self->is_absolute;
  return ref($self)->new(File::Spec->rel2abs($self));
}

sub relative {
  my $self = shift;
  return $self unless $self->is_absolute;
  return ref($self)->new(File::Spec->abs2rel($self));
}

1;
