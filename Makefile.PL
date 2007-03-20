use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
			  NAME          => 'ProgressMonitor',
			  AUTHOR        => 'Kenneth Olwing <knth@cpan.org>',
			  VERSION_FROM  => 'lib/ProgressMonitor.pm',
			  ABSTRACT_FROM => 'lib/ProgressMonitor.pm',
			  PREREQ_PM     => {
							'Test::More' => 0.64,
							'classes' => 0.943,
						   },
			  dist  => {COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
			  clean => {FILES    => 'ProgressMonitor-*'},
			 );
