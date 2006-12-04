use strict;
use warnings;

use lib('t');
use _driver;

use ProgressMonitor::Stringify::Fields::Counter;

runtest(
		ProgressMonitor::Stringify::Fields::Counter->new,
		10, 10, [0, 0, 0], 0,
		[
		 '00000/?????', '00000\\?????', '00000/?????', '00000\\?????', '00000/?????', '00000\\?????',
		 '00000/?????', '00000\\?????', '00000/?????', '00000\\?????', '00000/?????', '00000/00010',
		 '00001/00010', '00002/00010',  '00003/00010', '00004/00010',  '00005/00010', '00006/00010',
		 '00007/00010', '00008/00010',  '00009/00010', '00010/00010',  '00010/00010',
		]
	   );
