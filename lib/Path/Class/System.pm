package Path::Class::System;

use strict;
use File::Spec;

sub new { return bless {}, shift }

sub tmpdir  { File::Spec->tmpdir  }
sub updir   { File::Spec->updir   }
sub rootdir { File::Spec->rootdir }
sub curdir  { File::Spec->curdir  }
sub case_tolerant { File::Spec->case_tolerant }

1;
