
use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Path::Class',
   license => 'perl',
   requires => {
		'File::Spec' => 0,
		'File::Spec::Mac' => 1.3,
		'IO::Dir' => 0,
		'IO::File' => 0,
		'File::stat' => 0,
		'File::Path' => 0,
		'overload' => 0,
	       },
   create_makefile_pl => 'traditional',
  );

$b->create_build_script;
