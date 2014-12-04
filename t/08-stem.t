#!/usr/bin/perl

use Test::More tests => 40;
use Path::Class qw[ file dir ];

my $dir   = dir( qw[ path to some ] );
my %data = (
    perl  => +{ file => $dir->file( 'file.pl' ),  suffix => '.pl',  extension => 'pl' },
    pod   => +{ file => $dir->file( 'file.pod' ), suffix => '.pod', extension => 'pod' },
    bare  => +{ file => $dir->file( 'file' ),     suffix => '',     extension => undef },
    dotty => +{ file => $dir->file( 'file.' ),    suffix => '.',    extension => '' },
    double =>
      +{ file => $dir->file( 'file.foo.bar' ), stem => 'file.foo', suffix => '.bar', extension => 'bar' },
);

while ( my( $id => $data ) = each %data ) {
    my $basename = $data->{file}->basename;
    my $file = $data->{file};
    my $stem = $data->{stem} || 'file';
    is $file->stem, $stem, "stem of '$basename'";
    for my $suf ( qw[ suffix extension ] ) {
        is $file->$suf, $data->{extension}, "$suf of $basename";
    }
    is $file->stem . $data->{suffix}, $basename, "roundtrip $basename";
    for my $suf ( qw[ pl .pl ] ) {
        is $file->with_suffix( $suf ), $dir->file("$stem.pl"), "resuffix $file with $suf";
    }
    my $basefile = $file->basefile;
    isa_ok $basefile, ref($file), "class of $basename";
    is $basefile, $basename, "basefile eq $basename";
}

done_testing;
