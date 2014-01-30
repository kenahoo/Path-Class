BEGIN {
  $^O = 'Unix'; # Test in Unix mode
}

use strict;

use Path::Class;
use Test::More;

my @tests = (
    {
        line => __LINE__,
        file => 'file.txt',
        uri  => 'file.txt',
    },

    {
        line => __LINE__,
        file => '/file.txt',
        uri  => 'file:///file.txt',
    },

    {
        line => __LINE__,
        file => '/foo/file.txt',
        uri  => 'file:///foo/file.txt',
    },

    {
        line => __LINE__,
        dir  => '/foo/bar',
        uri  => 'file:///foo/bar',
    },

    {
        line => __LINE__,
        dir  => '/foo/bar/',
        uri  => 'file:///foo/bar',
    },
);

foreach my $test (@tests) {

    my $type = (exists $test->{file}) ? 'file' : 'dir';
    my $method = __PACKAGE__->can($type);
    my $name   = $test->{$type};

    ok(my $obj = $method->($name), "${type}('${name}')");

    can_ok($obj, 'as_uri');

    my $uri = $obj->as_uri;

    isa_ok($uri, 'URI::file');

    is($uri, $test->{uri}, "URI::file");
}

done_testing;
