package Path::Class::Dir;

use strict;
use File::Spec;
use Path::Class::File;
use Path::Class::Entity;
use base qw(Path::Class::Entity);

sub new {
  my $self = shift->SUPER::new();
  
  my $first = (@_ == 0     ? File::Spec->curdir :
	       $_[0] eq '' ? (shift, File::Spec->rootdir) :
	       shift()
	      );
  
  my ($volume, $dirs) = File::Spec->splitpath($first, 1);
  my @dirs = File::Spec->splitdir($dirs);
  push @dirs, map File::Spec->splitdir($_), @_;

  $self->{dirs} = \@dirs;
  $self->{volume} = $volume;

  return $self;
}

sub stringify {
  my $self = shift;
  return File::Spec->catpath($self->{volume},
			     File::Spec->catdir(@{$self->{dirs}}),
			     '');
}

sub volume { shift()->{volume} }

sub file {
  return Path::Class::File->new(@_);
}

sub subdir {
  my $self = shift;
  return ref($self)->new($self, @_);
}

sub parent {
  my $self = shift;
  my $class = ref($self);
  my $dirs = $self->{dirs};
  my ($curdir, $updir) = (File::Spec->curdir, File::Spec->updir);

  if ($self->is_absolute) {
    my $parent = $class->new($self);
    pop @{$parent->{dirs}};
    return $parent;

  } elsif ($self eq $curdir) {
    return $class->new($updir);

  } elsif (!grep {$_ ne $updir} @$dirs) {  # All updirs
    return $class->new($self, $updir); # Add one more

  } elsif (@$dirs == 1) {
    return $class->new($curdir);

  } else {
    my $parent = $class->new($self);
    pop @{$parent->{dirs}};
    return $parent;
  }
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
first place, so they probably shouldn't appear in your code if you're
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
absolute path.

=item $rel = $dir->relative

Returns a C<Path::Class::Dir> object representing C<$dir> as a
relative path.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 SEE ALSO

Path::Class, Path::Class::File, File::Spec

=cut
