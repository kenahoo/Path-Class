use Test;
use strict;
BEGIN { plan tests => 14 };
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

if ($^O eq 'VMS') {
  ok $dir->as_foreign('VMS'), '[.dir.subdir]';
} else {
  skip "skip Can't test VMS code on other platforms", 1;
}

