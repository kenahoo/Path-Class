
use strict;
use Test;
use Path::Class qw(file dir);

plan tests => 22;
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
