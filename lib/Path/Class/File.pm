package Path::Class::File;

use strict;
use Path::Class::Dir;
use Path::Class::Entity;
use base qw(Path::Class::Entity);

use IO::File ();
use File::stat ();

sub new {
  my $self = shift->SUPER::new;
  my $file = pop();
  my @dirs = @_;

  my ($volume, $dirs, $base) = $self->_spec->splitpath($file);
  
  if (length $dirs) {
    push @dirs, $self->_spec->catpath($volume, $dirs, '');
  }
  
  $self->{dir}  = @dirs ? Path::Class::Dir->new(@dirs) : undef;
  $self->{file} = $base;
  
  return $self;
}

sub as_foreign {
  my ($self, $type) = @_;
  local $Path::Class::Foreign = $self->_spec_class($type);
  my $foreign = ref($self)->SUPER::new;
  $foreign->{dir} = $self->{dir}->as_foreign($type) if defined $self->{dir};
  $foreign->{file} = $self->{file};
  return $foreign;
}

sub stringify {
  my $self = shift;
  return $self->{file} unless defined $self->{dir};
  return $self->_spec->catfile($self->{dir}->stringify, $self->{file});
}

sub dir {
  my $self = shift;
  return $self->{dir} if defined $self->{dir};
  return Path::Class::Dir->new($self->_spec->curdir);
}

sub volume {
  my $self = shift;
  return '' unless defined $self->{dir};
  return $self->{dir}->volume;
}

sub open  { IO::File->new(@_) }
sub stat  { File::stat::stat("$_[0]") }
sub lstat { File::stat::lstat("$_[0]") }

1;
__END__

=head1 NAME

Path::Class::File - Objects representing files

=head1 SYNOPSIS

  use Path::Class qw(file);  # Export a short constructor
  
  my $file = file('foo', 'bar.txt');  # Path::Class::File object
  my $file = Path::Class::Dir->new('foo', 'bar.txt'); # Same thing
  
  # Stringifies to 'foo/bar.txt' on Unix, 'foo\bar.txt' on Windows, etc.
  print "file: $file\n";
  
  if ($file->is_absolute) { ... }
  
  my $v = $file->volume; # Could be 'C:' on Windows, empty string
                         # on Unix, 'Macintosh HD:' on Mac OS
  
  $file->cleanup; # Perform logical cleanup of pathname
  
  my $dir = $file->dir;  # A Path::Class::Dir object
  
  my $abs = $file->absolute; # Transform to absolute path
  my $rel = $file->relative; # Transform to relative path

=head1 DESCRIPTION

The C<Path::Class::File> class contains functionality for manipulating
file names in a cross-platform way.

=head1 METHODS

=over 4

=item $file = Path::Class::Dir->new( <dir1>, <dir2>, ..., <file> )

=item $file = file( <dir1>, <dir2>, ..., <file> )

Creates a new C<Path::Class::File> object and returns it.  The
arguments specify the path to the file.  Any volume may also be
specified as the first argument, or as part of the first argument.
You can use platform-neutral syntax:

  my $dir = file( 'foo', 'bar', 'baz.txt' );

or platform-native syntax:

  my $dir = dir( 'foo/bar/baz.txt' );

or a mixture of the two:

  my $dir = dir( 'foo/bar', 'baz.txt' );

All three of the above examples create relative paths.  To create an
absolute path, either use the platform native syntax for doing so:

  my $dir = dir( '/var/tmp/foo.txt' );

or use an empty string as the first argument:

  my $dir = dir( '', 'var', 'tmp', 'foo.txt' );

If the second form seems awkward, that's somewhat intentional - paths
like C</var/tmp> or C<\Windows> aren't cross-platform concepts in the
first place, so they probably shouldn't appear in your code if you're
trying to be cross-platform.  The first form is perfectly fine,
because paths like this may come from config files, user input, or
whatever.

=item $file->stringify

This method is called internally when a C<Path::Class::File> object is
used in a string context, so the following are equivalent:

  $string = $file->stringify;
  $string = "$file";

=item $file->volume

Returns the volume (e.g. C<C:> on Windows, C<Macintosh HD:> on Mac OS,
etc.) of the object, if any.  Otherwise, returns the empty string.

=item $file->is_absolute

Returns true or false depending on whether the file refers to an
absolute path specifier (like C</usr/local/foo.txt> or C<\Windows\Foo.txt>).

=item $file->cleanup

Performs a logical cleanup of the file path.  For instance:

  my $file = file('/foo//baz/./foo.txt')->cleanup;
  # $file now represents '/foo/baz/foo.txt';

=item $dir = $file->dir

Returns a C<Path::Class::Dir> object representing the directory
containing this file.

=item $abs = $file->absolute

Returns a C<Path::Class::File> object representing C<$file> as an
absolute path.  An optional argument, given as either a string or a
C<Path::Class::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $rel = $file->relative

Returns a C<Path::Class::File> object representing C<$file> as a
relative path.  An optional argument, given as either a string or a
C<Path::Class::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $foreign = $file->as_foreign($type)

Returns a C<Path::Class::File> object representing C<$file> as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

Any generated objects (subdirectories, files, parents, etc.) will also
retain this type.

=item $foreign = Path::Class::File->new_foreign($type, @args)

Returns a C<Path::Class::File> object representing a file as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

The arguments in C<@args> are the same as they would be specified in
C<new()>.

=item $fh = $file->open($mode, $permissions)

Passes the given arguments, including C<$file>, to C<< IO::File->open
>> and returns the result as an C<IO::File> object.  If the opening
fails, C<undef> is returned and C<$!> is set.

=item $st = $file->stat()

Invokes C<< File::stat::stat() >> on this file and returns a
C<File::stat> object representing the result.

=item $st = $file->lstat()

Same as C<stat()>, but if C<$file> is a symbolic link, C<lstat()>
stats the link instead of the file the link points to.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 SEE ALSO

Path::Class, Path::Class::Dir, File::Spec

=cut
