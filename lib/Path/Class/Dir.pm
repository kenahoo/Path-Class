package Path::Class::Dir;

use strict;
use Path::Class::File;
use Path::Class::Entity;
use Carp();
use base qw(Path::Class::Entity);

use IO::Dir ();
use File::Path ();

sub new {
  my $self = shift->SUPER::new();
  my $s = $self->_spec;
  
  my $first = (@_ == 0     ? $s->curdir :
	       $_[0] eq '' ? (shift, $s->rootdir) :
	       shift()
	      );
  
  ($self->{volume}, my $dirs) = $s->splitpath( $s->canonpath($first) , 1);
  $self->{dirs} = [$s->splitdir($s->catdir($dirs, @_))];

  return $self;
}

sub is_dir { 1 }

sub as_foreign {
  my ($self, $type) = @_;

  my $foreign = do {
    local $self->{file_spec_class} = $self->_spec_class($type);
    $self->SUPER::new;
  };
  
  # Clone internal structure
  $foreign->{volume} = $self->{volume};
  my ($s, $fs) = ($self->_spec, $foreign->_spec);
  $foreign->{dirs} = [ map {$_ eq $s->updir ? $fs->updir : $_} @{$self->{dirs}}];
  return $foreign;
}

sub stringify {
  my $self = shift;
  my $s = $self->_spec;
  return $s->catpath($self->{volume},
		     $s->catdir(@{$self->{dirs}}),
		     '');
}

sub volume { shift()->{volume} }

sub file {
  local $Path::Class::Foreign = $_[0]->{file_spec_class} if $_[0]->{file_spec_class};
  return Path::Class::File->new(@_);
}

sub dir_list {
  my $self = shift;
  my $d = $self->{dirs};
  return @$d unless @_;
  
  my $offset = shift;
  if ($offset < 0) { $offset = $#$d + $offset + 1 }

  unless (@_) {
    return wantarray ? @$d[$offset .. $#$d] : $#$d - $offset;
  }

  my $length = shift;
  if ($length < 0) { $length = $#$d + $length + 1 - $offset }
  return wantarray ? @$d[$offset .. $length + $offset - 1] : $length;
}

sub subdir {
  my $self = shift;
  return $self->new($self, @_);
}

sub parent {
  my $self = shift;
  my $dirs = $self->{dirs};
  my ($curdir, $updir) = ($self->_spec->curdir, $self->_spec->updir);

  if ($self->is_absolute) {
    my $parent = $self->new($self);
    pop @{$parent->{dirs}};
    return $parent;

  } elsif ($self eq $curdir) {
    return $self->new($updir);

  } elsif (!grep {$_ ne $updir} @$dirs) {  # All updirs
    return $self->new($self, $updir); # Add one more

  } elsif (@$dirs == 1) {
    return $self->new($curdir);

  } else {
    my $parent = $self->new($self);
    pop @{$parent->{dirs}};
    return $parent;
  }
}

sub open  { IO::Dir->new(@_) }
sub mkpath { File::Path::mkpath(shift()->stringify, @_) }
sub rmtree { File::Path::rmtree(shift()->stringify, @_) }

sub next {
  my $self = shift;
  unless ($self->{dh}) {
    $self->{dh} = $self->open or Carp::croak( "Can't open directory $self: $!" );
  }
  
  my $next = $self->{dh}->read;
  unless (defined $next) {
    delete $self->{dh};
    return undef;
  }
  
  # Figure out whether it's a file or directory
  my $file = $self->file($next);
  $file = $self->subdir($next) if -d $file;
  return $file;
}

1;
__END__

=head1 NAME

Path::Class::Dir - Objects representing directories

=head1 SYNOPSIS

  use Path::Class qw(dir);  # Export a short constructor
  
  my $dir = dir('foo', 'bar');       # Path::Class::Dir object
  my $dir = Path::Class::Dir->new('foo', 'bar');  # Same thing
  
  # Stringifies to 'foo/bar' on Unix, 'foo\bar' on Windows, etc.
  print "dir: $dir\n";
  
  if ($dir->is_absolute) { ... }
  
  my $v = $dir->volume; # Could be 'C:' on Windows, empty string
                        # on Unix, 'Macintosh HD:' on Mac OS
  
  $dir->cleanup; # Perform logical cleanup of pathname
  
  my $file = $dir->file('file.txt'); # A file in this directory
  my $subdir = $dir->subdir('george'); # A subdirectory
  my $parent = $dir->parent; # The parent directory, 'foo'
  
  my $abs = $dir->absolute; # Transform to absolute path
  my $rel = $abs->relative; # Transform to relative path
  my $rel = $abs->relative('/foo'); # Relative to /foo
  
  print $dir->as_foreign('MacOS'); # :foo:bar:
  print $dir->as_foreign('Win32'); #  foo\bar

  # Iterate with IO::Dir methods:
  my $handle = $dir->open;
  while (my $file = $handle->read) {
    $file = $dir->file($file);  # Turn into Path::Class::File object
    ...
  }
  
  # Iterate with Path::Class methods:
  while (my $file = $dir->next) {
    # $file is a Path::Class::File or Path::Class::Dir object
    ...
  }


=head1 DESCRIPTION

The C<Path::Class::Dir> class contains functionality for manipulating
directory names in a cross-platform way.

=head1 METHODS

=over 4

=item $dir = Path::Class::Dir->new( <dir1>, <dir2>, ... )

=item $dir = dir( <dir1>, <dir2>, ... )

Creates a new C<Path::Class::Dir> object and returns it.  The
arguments specify names of directories which will be joined to create
a single directory object.  A volume may also be specified as the
first argument, or as part of the first argument.  You can use
platform-neutral syntax:

  my $dir = dir( 'foo', 'bar', 'baz' );

or platform-native syntax:

  my $dir = dir( 'foo/bar/baz' );

or a mixture of the two:

  my $dir = dir( 'foo/bar', 'baz' );

All three of the above examples create relative paths.  To create an
absolute path, either use the platform native syntax for doing so:

  my $dir = dir( '/var/tmp' );

or use an empty string as the first argument:

  my $dir = dir( '', 'var', 'tmp' );

If the second form seems awkward, that's somewhat intentional - paths
like C</var/tmp> or C<\Windows> aren't cross-platform concepts in the
first place (many non-Unix platforms don't have a notion of a "root
directory"), so they probably shouldn't appear in your code if you're
trying to be cross-platform.  The first form is perfectly natural,
because paths like this may come from config files, user input, or
whatever.

As a special case, since it doesn't otherwise mean anything useful and
it's convenient to define this way, C<< Path::Class::Dir->new() >> (or
C<dir()>) refers to the current directory (C<< File::Spec->curdir >>).
To get the current directory as an absolute path, do C<<
dir()->absolute >>.

=item $dir->stringify

This method is called internally when a C<Path::Class::Dir> object is
used in a string context, so the following are equivalent:

  $string = $dir->stringify;
  $string = "$dir";

=item $dir->volume

Returns the volume (e.g. C<C:> on Windows, C<Macintosh HD:> on Mac OS,
etc.) of the directory object, if any.  Otherwise, returns the empty
string.

=item $dir->is_dir

Returns a boolean value indicating whether this object represents a
directory.  Not surprisingly, C<Path::Class::File> objects always
return false, and C<Path::Class::Dir> objects always return true.

=item $dir->is_absolute

Returns true or false depending on whether the directory refers to an
absolute path specifier (like C</usr/local> or C<\Windows>).

=item $dir->cleanup

Performs a logical cleanup of the file path.  For instance:

  my $dir = dir('/foo//baz/./foo')->cleanup;
  # $dir now represents '/foo/baz/foo';

=item $file = $dir->file( <dir1>, <dir2>, ..., <file> )

Returns a C<Path::Class::File> object representing an entry in C<$dir>
or one of its subdirectories.  Internally, this just calls C<<
Path::Class::File->new( @_ ) >>.

=item $subdir = $dir->subdir( <dir1>, <dir2>, ... )

Returns a new C<Path::Class::Dir> object representing a subdirectory
of C<$dir>.

=item $parent = $dir->parent

Returns the parent directory of C<$dir>.  Note that this is the
I<logical> parent, not necessarily the physical parent.  It really
means we just chop off entries from the end of the directory list
until we cain't chop no more.  If the directory is relative, we start
using the relative forms of parent directories.

The following code demonstrates the behavior on absolute and relative
directories:

  $dir = dir('/foo/bar');
  for (1..6) {
    print "Absolute: $dir\n";
    $dir = $dir->parent;
  }
  
  $dir = dir('foo/bar');
  for (1..6) {
    print "Relative: $dir\n";
    $dir = $dir->parent;
  }
  
  ########### Output on Unix ################
  Absolute: /foo/bar
  Absolute: /foo
  Absolute: /
  Absolute: /
  Absolute: /
  Absolute: /
  Relative: foo/bar
  Relative: foo
  Relative: .
  Relative: ..
  Relative: ../..
  Relative: ../../..

=item $abs = $dir->absolute

Returns a C<Path::Class::Dir> object representing C<$dir> as an
absolute path.  An optional argument, given as either a string or a
C<Path::Class::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $rel = $dir->relative

Returns a C<Path::Class::Dir> object representing C<$dir> as a
relative path.  An optional argument, given as either a string or a
C<Path::Class::Dir> object, specifies the directory to use as the base
of relativity - otherwise the current working directory will be used.

=item $foreign = $dir->as_foreign($type)

Returns a C<Path::Class::Dir> object representing C<$dir> as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

Any generated objects (subdirectories, files, parents, etc.) will also
retain this type.

=item $foreign = Path::Class::Dir->new_foreign($type, @args)

Returns a C<Path::Class::Dir> object representing C<$dir> as it would
be specified on a system of type C<$type>.  Known types include
C<Unix>, C<Win32>, C<Mac>, C<VMS>, and C<OS2>, i.e. anything for which
there is a subclass of C<File::Spec>.

The arguments in C<@args> are the same as they would be specified in
C<new()>.

=item @list = $dir->dir_list([OFFSET, [LENGTH]])

Returns the list of strings internally representing this directory
structure.  Each successive member of the list is understood to be an
entry in its predecessor's directory list.  By contract, C<<
Path::Class->new( $dir->dir_list ) >> should be equivalent to C<$dir>.

The semantics of this method are similar to Perl's C<splice> or
C<substr> functions; they return C<LENGTH> elements starting at
C<OFFSET>.  If C<LENGTH> is omitted, returns all the elements starting
at C<OFFSET> up to the end of the list.  If C<LENGTH> is negative,
returns the elements from C<OFFSET> onward except for C<-LENGTH>
elements at the end.  If C<OFFSET> is negative, it counts backward
C<OFFSET> elements from the end of the list.  If C<OFFSET> and
C<LENGTH> are both omitted, the entire list is returned.

=item $fh = $dir->open()

Passes C<$dir> to C<< IO::Dir->open >> and returns the result as an
C<IO::Dir> object.  If the opening fails, C<undef> is returned and
C<$!> is set.

=item $dir->mkpath($verbose, $mode)

Passes all arguments, including C<$dir>, to C<< File::Path::mkpath()
>> and returns the result (a list of all directories created).

=item $dir->rmtree($verbose, $cautious)

Passes all arguments, including C<$dir>, to C<< File::Path::rmtree()
>> and returns the result (the number of files successfully deleted).

=item $dir_or_file = $dir->next()

A convenient way to iterate through directory contents.  The first
time C<next()> is called, it will C<open()> the directory and read the
first item from it, returning the result as a C<Path::Class::Dir> or
C<Path::Class::File> object (depending, of course, on its actual
type).  Each subsequent call to C<next()> will simply iterate over the
directory's contents, until there are no more items in the directory,
and then the undefined value is returned.  For example, to iterate
over all the regular files in a directory:

  while (my $file = $dir->next) {
    next unless -f $file;
    my $fh = $file->open('r') or die "Can't read $file: $!";
    ...
  }

If an error occurs when opening the directory (for instance, it
doesn't exist or isn't readable), C<next()> will throw an exception
with the value of C<$!>.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 SEE ALSO

Path::Class, Path::Class::File, File::Spec

=cut
