package Path::Class;

$VERSION = '0.03_01';
@ISA = qw(Exporter);
@EXPORT_OK = qw(file dir foreign_file foreign_dir);

use strict;
use Exporter;
use Path::Class::File;
use Path::Class::Dir;

sub file { Path::Class::File->new(@_) }
sub dir  { Path::Class::Dir ->new(@_) }
sub foreign_file { Path::Class::File->new_foreign(@_) }
sub foreign_dir  { Path::Class::Dir ->new_foreign(@_) }


1;
__END__

=head1 NAME

Path::Class - Cross-platform path specification manipulation

=head1 SYNOPSIS

  use Path::Class qw(file dir);  # Export a couple of short constructors
  
  my $dir  = dir('foo', 'bar');       # Path::Class::Dir object
  my $file = file('bob', 'file.txt'); # Path::Class::File object
  
  # Stringifies to 'bob/file.txt' on Unix, 'bob\file.txt' on Windows
  print "file: $file\n";
  
  # Stringifies to 'foo/bar' on Unix, 'foo\bar' on Windows
  print "dir: $dir\n";
  
  my $subdir  = $dir->subdir('baz');  # foo/bar/baz
  my $parent  = $subdir->parent;      # foo/bar
  my $parent2 = $parent->parent;      # foo
  
  my $dir2 = $file->dir;              # bob

  # Work with foreign paths
  use Path::Class qw(foreign_file foreign_dir);
  my $file = foreign_file('Mac', ':foo:file.txt');
  print $file->dir;                   # :foo:
  print $file->as_foreign('Win32');   # foo\file.txt

=head1 DESCRIPTION

C<Path::Class> is a module for manipulation of file and directory
specifications (strings describing their locations, like
C<'/home/ken/foo.txt'> or C<'C:\Windows\Foo.txt'>) in a cross-platform
manner.  It supports pretty much every platform Perl runs on,
including Unix, Windows, Mac, VMS, Epoc, Cygwin, OS/2, and NetWare.

The well-known module C<File::Spec> also provides this service, but
it's sort of awkward to use well, so people sometimes avoid it, or use
it in a way that won't actually work properly on platforms
significantly different than the ones they've tested their code on.

In fact, C<Path::Class> uses C<File::Spec> internally, wrapping all
the unsightly details so you can concentrate on your application code.
Whereas C<File::Spec> provides functions for some common path
manipulations, C<Path::Class> provides an object-oriented model of the
world of path specifications and their underlying semantics.
C<File::Spec> doesn't create any objects, and its classes represent
the different ways in which paths must be manipulated on various
platforms (not a very intuitive concept).  C<Path::Class> creates
objects representing files and directories, and provides methods that
relate them to each other.  For instance, the following C<File::Spec>
code:

 my $absolute = File::Spec->file_name_is_absolute(
                  File::Spec->catfile( @dirs, $file )
                );

can be written using C<Path::Class> as

 my $absolute = Path::Class::File->new( @dirs, $file )->is_absolute;

or even as 

 my $absolute = file( @dirs, $file )->is_absolute;

if you export the C<file> function into your namespace.  Similar
readability improvements should happen all over the place when using
C<Path::Class>.

Using C<Path::Class> can help solve real problems in your code too -
for instance, how many people actually take the "volume" (like C<C:>
on Windows) into account when writing C<File::Spec>-using code?  I
thought not.  But if you use C<Path::Class>, your directory objects
will know what volumes they refer to and do the right thing.

The guts of the C<Path::Class> code live in the C<Path::Class::File>
and C<Path::Class::Dir> modules, so please see those
modules' documentation for more details about how to use them.

=head2 EXPORT

The following functions can be exported upon request:

=over 4

=item file

A synonym for C<< Path::Class::File->new >>.

=item dir

A synonym for C<< Path::Class::Dir->new >>.

=item foreign_file

A synonym for C<< Path::Class::File->new_foreign >>.

=item foreign_dir

A synonym for C<< Path::Class::Dir->new_foreign >>.

=back

=head1 AUTHOR

Ken Williams, ken@mathforum.org

=head1 SEE ALSO

Path::Class::Dir, Path::Class::File, File::Spec

=cut
