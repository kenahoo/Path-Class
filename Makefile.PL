
use ExtUtils::MakeMaker;

my $module = 'Path::Class';
my ($file, $dir);
($file = $module) =~ s{::}{\/}g; $file = "lib/$file.pm";
($dir  = $module) =~ s/::/-/g;

WriteMakefile
  (
   'NAME'       => $module,
   'VERSION_FROM' => $file, # finds $VERSION
   'dist' => { COMPRESS=>"gzip",
               SUFFIX=>"gz",
               PREOP=>('rm -f README; '.
                       "pod2text -80 < $file > README; ".
                       "cp -f README $dir-\$(VERSION); "
                      ),
             },
   # 'clean' => {FILES => "t/httpd.conf t/error_log t/httpd"},
   'PREREQ_PM' => {
		   File::Spec => 0,
		   overload => 0,
		  },
   ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
    (ABSTRACT_FROM => $file, # retrieve abstract from module
     AUTHOR     => 'Ken Williams <ken@mathforum.org>') : 
    ()
   ),
  );

