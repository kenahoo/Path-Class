
use Module::Build;

my $b = Module::Build->new
  (
   module_name => 'Path::Class',
   requires => {
		'File::Spec' => 0,
		'File::Spec::Mac' => 1.3,
		'overload' => 0,
	       },
  );

$b->create_build_script;
