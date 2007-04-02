use strict;
use warnings;

use 5.8.0;

use ExtUtils::MakeMaker;

my $tsData = $^O eq 'MSWin32' ? ['Win32', '0.207'] : ['Unix', '0.204'];

WriteMakefile(
			  NAME          => 'ProgressMonitor',
			  AUTHOR        => 'Kenneth Olwing <knth@cpan.org>',
			  VERSION_FROM  => 'lib/ProgressMonitor.pm',
			  ABSTRACT_FROM => 'lib/ProgressMonitor.pm',
			  PREREQ_PM     => {
							'Test::More' => 0.64,
							'classes'    => 0.943,
							"Term::Size::$tsData->[0]" => $tsData->[1],
						   },
			  dist  => {TARFLAGS => '-c -v --mode=777 -f', COMPRESS => 'gzip -9f', SUFFIX => 'gz',},
			  clean => {FILES    => 'ProgressMonitor-*'},
			 );
