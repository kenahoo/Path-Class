
use strict;
use Test;
use Path::Class;

plan tests => 42;
ok 1;

my $file = file('t', 'testfile');
ok $file;

{
  my $fh = $file->open('w');
  ok $fh;
  
  ok print $fh "Foo\n";
}

ok -e $file;

{
  my $fh = $file->open;
  ok <$fh>, "Foo\n";
}

{
  my $stat = $file->stat;
  ok $stat;
  ok $stat->mtime > time() - 20;  # Modified within last 20 seconds
}

ok unlink $file;

my $dir = dir('t', 'testdir');
ok $dir;

ok mkdir($dir, 0777);
ok -d $dir;

$file = $dir->file('foo');
$file->open('w');  # touch
ok -e $file;

{
  my $dh = $dir->open;
  ok $dh;

  my @files = readdir $dh;
  ok @files, 3;
  ok grep { $_ eq 'foo' } @files;
}

ok $dir->rmtree;
ok !-e $dir;

{
  $dir = dir('t', 'foo', 'bar');
  ok $dir->mkpath;
  ok -d $dir;
  
  $dir = $dir->parent;
  ok $dir->rmtree;
  ok !-e $dir;
}

{
  $dir = dir('t', 'foo');
  ok $dir->mkpath;
  ok $dir->subdir('dir')->mkpath;
  ok -d $dir->subdir('dir');
  
  ok $dir->file('file')->open('w');
  ok $dir->file('0')->open('w');
  my @contents;
  while (my $file = $dir->next) {
    push @contents, $file;
  }
  ok @contents, 5;

  my $joined = join ' ', map $_->basename, sort grep {-f $_} @contents;
  ok $joined, '0 file';
  
  my ($subdir) = grep {$_ eq $dir->subdir('dir')} @contents;
  ok $subdir;
  ok -d $subdir, 1;

  my ($file) = grep {$_ eq $dir->file('file')} @contents;
  ok $file;
  ok -d $file, '';
  
  ok $dir->rmtree;
  ok !-e $dir;
}

{
  my $file = file('t', 'slurp');
  ok $file;
  
  my $fh = $file->open('w') or die "Can't create $file: $!";
  print $fh "Line1\nLine2\n";
  close $fh;
  ok -e $file;
  
  my $content = $file->slurp;
  ok $content, "Line1\nLine2\n";
  
  my @content = $file->slurp;
  ok @content, 2;
  ok $content[0], "Line1\n";
  ok $content[1], "Line2\n";

  unlink $file;
  ok -e $file, undef;
}
