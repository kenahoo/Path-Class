use Test;
use strict;
BEGIN { plan tests => 23 };
use Path::Class qw(file dir foreign_file foreign_dir);
ok(1);


my $file = Path::Class::File->new_foreign('Unix', 'dir', 'foo.txt');
ok $file, 'dir/foo.txt';

ok $file->as_foreign('Win32'), 'dir\foo.txt';
ok $file->as_foreign('Mac'), ':dir:foo.txt';
ok $file->as_foreign('OS2'), 'dir/foo.txt';

if ($^O eq 'VMS') {
  ok $file->as_foreign('VMS'), '[.dir]foo.txt';
} else {
  skip "skip Can't test VMS code on other platforms", 1;
}

$file = foreign_file('Mac', ':dir:foo.txt');
ok $file, ':dir:foo.txt';
ok $file->as_foreign('Unix'), 'dir/foo.txt';
ok $file->dir, ':dir:';


my $dir = Path::Class::Dir->new_foreign('Unix', 'dir/subdir');
ok $dir, 'dir/subdir';
ok $dir->as_foreign('Win32'), 'dir\subdir';
ok $dir->as_foreign('Mac'),  ':dir:subdir:';
ok $dir->as_foreign('OS2'),   'dir/subdir';

# Note that "\\" and '\\' are each a single backslash
$dir = foreign_dir('Win32', 'C:\\');
ok $dir, 'C:\\';
$dir = foreign_dir('Win32', 'C:/');
ok $dir, 'C:\\';
ok $dir->subdir('Program Files'), 'C:\\Program Files';

if ($^O eq 'VMS') {
  ok $dir->as_foreign('VMS'), '[.dir.subdir]';
} else {
  skip "skip Can't test VMS code on other platforms", 1;
}

$dir = foreign_dir('Mac', ':dir:subdir:');
ok $dir, ':dir:subdir:';
ok $dir->subdir('foo'),   ':dir:subdir:foo:';
ok $dir->file('foo.txt'), ':dir:subdir:foo.txt';
ok $dir->parent,          ':dir:';

$dir = foreign_dir('Mac', ':dir::dir2:subdir');
ok $dir, ':dir::dir2:subdir:';
ok $dir->as_foreign('Unix'), 'dir/../dir2/subdir';
