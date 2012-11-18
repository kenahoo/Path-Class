#!/usr/bin/env perl
use strict;
use warnings;
use Cwd;
use Test::More;
use File::Temp qw(tempdir);

plan tests => 4;

use_ok 'Path::Class';

my $cwd = getcwd;
my $tmp = dir(tempdir(CLEANUP => 1));

# Test ability to filter children before navigating down to them
#     a
#    / \
#   b*  c        * → inaccessible
#  / \   \
# d   e   f
#    / \   \
#   g   h   i*
(my $abe = $tmp->subdir(qw(a b e)))->mkpath;
(my $acf = $tmp->subdir(qw(a c f)))->mkpath;
$acf->file('i')->touch;
$abe->file('h')->touch;
$abe->file('g')->touch;
$tmp->file(qw(a b d))->touch;

# Drop permissions on b to make accessing it's contents problematic
chmod 0000, $tmp->subdir('a', 'b') or diag("Chmod failed, test results may be irrelevant");
chmod 0000, $tmp->subdir('a', 'c', 'f')->file('i') or diag("Chmod failed, test results may be irrelevant");;

my $a = $tmp->subdir('a');

my $nnodes = $a->traverse_if(
    sub {
        my ($child, $cont) = @_;
        #diag("I am in $child");
        return sum($cont->(), 1);
    },
    sub {
        my $child = shift;
        #diag("Checking whether to use $child: " . -r $child);
        return -r $child;
    }
);
is($nnodes, 3);

my $ndirs = $a->traverse_if(
    sub {
        my ($child, $cont) = @_;
        return sum($cont->(), ($child->is_dir ? 1 : 0));
    },
    sub {
        my $child = shift;
        return -r $child;
    }
   );
is($ndirs, 3);

my $max_depth = $a->traverse_if(
    sub {
        my ($child, $cont, $depth) = @_;
        return max($cont->($depth + 1), $depth);
    }, 
    sub {
        my $child = shift;
        return -r $child;
    },
    0);
is($max_depth, 2);

sub sum { my $total = 0; $total += $_ for @_; $total }
sub max { my $max = 0; for (@_) { $max = $_ if $_ > $max } $max }
