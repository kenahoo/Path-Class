package Path::Class::Entity;

use strict;
use File::Spec;

use overload
  (
   q[""] => 'stringify',
   fallback => 1,
  );

sub new { bless {}, shift() }

sub _spec { $_[0]->{file_spec_class} || 'File::Spec' }
  
sub is_absolute { $_[0]->_spec->file_name_is_absolute($_[0]) }

sub cleanup {
  my $self = shift;
  my $cleaned = ref($self)->new( $self->_spec->canonpath($self) );
  %$self = %$cleaned;
  return $self;
}

sub absolute {
  my $self = shift;
  return $self if $self->is_absolute;
  return ref($self)->new($self->_spec->rel2abs($self));
}

sub relative {
  my $self = shift;
  return $self unless $self->is_absolute;
  return ref($self)->new($self->_spec->abs2rel($self));
}

1;
