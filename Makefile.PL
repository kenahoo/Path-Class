    use ExtUtils::MakeMaker;
    WriteMakefile
      ('DISTNAME' => 'Path-Class',
       'VERSION' => '0.03_01',
       'PL_FILES' => {},
       'INSTALLDIRS' => 'site',
       'PREREQ_PM' => {
			'File::Spec::Mac' => '1.3',
			'File::Spec' => '0',
			'overload' => '0',
		      },
      );
