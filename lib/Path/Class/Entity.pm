package Path::Class::Entity;

use strict;
use File::Spec;

use overload
  (
   q[""] => 'stringify',
   fallback => 1,
  );

sub new {
  my $from = shift;
  my $self;
  if (ref $from) {
    $self = bless {}, ref $from;
    $self->{file_spec_class} = $from->{file_spec_class} if $from->{file_spec_class};
  } else {
    $self = bless {}, $from;
    $self->{file_spec_class} = $Path::Class::Foreign if $Path::Class::Foreign;
  }
  return $self;
}

sub _spec_class {
  my ($class, $type) = @_;

  die "Invalid system type '$type'" unless ($type) = $type =~ /^(\w+)$/;  # Untaint
  my $spec = "File::Spec::$type";
  eval "require $spec; 1" or die $@;
  return $spec;
}

sub new_foreign {
  my ($class, $type) = (shift, shift);
  local $Path::Class::Foreign = $class->_spec_class($type);
  return $class->new(@_);
}

sub _spec { $_[0]->{file_spec_class} || 'File::Spec' }
  
sub is_absolute { $_[0]->_spec->file_name_is_absolute($_[0]) }

sub cleanup {
  my $self = shift;
  my $cleaned = $self->new( $self->_spec->canonpath($self) );
  %$self = %$cleaned;
  return $self;
}

sub absolute {
  my $self = shift;
  return $self if $self->is_absolute;
  return ref($self)->new($self->_spec->rel2abs($self, @_));
}

sub relative {
  my $self = shift;
  return $self unless $self->is_absolute;
  return ref($self)->new($self->_spec->abs2rel($self, @_));
}

1;
