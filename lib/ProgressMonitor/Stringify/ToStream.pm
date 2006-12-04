package ProgressMonitor::Stringify::ToStream;

use warnings;
use strict;

use ProgressMonitor::State;

use constant BACKSPACE => "\b";
use constant SPACE     => ' ';

# Attributes:
#	backspaces (string)
#		Precomputed string with backspaces used to return to the beginning so as
# 		to wipe out the previous write.
#
use classes
  extends  => 'ProgressMonitor::Stringify::AbstractMonitor',
  new      => 'new',
  attrs_pr => ['backspaces',],
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	# initialize the rest
	#
	$self->{$ATTR_backspaces} = undef;

	return $self;
}

sub render
{
	my $self = shift;

	local $|;
	$| = 1;
	
	my $cfg    = $self->_get_cfg;
	my $stream = $cfg->get_stream;
	my $bs     = $self->{$ATTR_backspaces};
	if ($bs)
	{
		# We have rendered at least once before, so we need to print the backspaces
		#
		print $stream $bs;
	}
	else
	{
		# this is the first time we're called, just initialize the backspaces
		#
		$bs = $self->{$ATTR_backspaces} = BACKSPACE x $self->get_width;
	}

	# now render and print - unless it's the final call, and we should wipe it
	#
	if ($self->_get_state == STATE_DONE && $cfg->get_wipeAtEnd)
	{
		# first space it out, and then bs again to return
		#
		print $stream SPACE x $self->get_width;
		print $stream $bs;
	}
	else
	{
		print $stream $self->_toString;
	}

	return;
}

###

package ProgressMonitor::Stringify::ToStreamConfiguration;

use strict;
use warnings;

use Scalar::Util qw(openhandle);

# Attributes
#	stream (handle)
#		This is the stream to write to. Defaults to '\*STDOUT'.
#	wipeAtEnd (boolean)
#		If this is true, the rendered data will be cleared on completion
#
use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitorConfiguration',
  attrs   => ['stream', 'wipeAtEnd'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, stream => \*STDOUT, wipeAtEnd => 0};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues();

	X::Usage->throw("not an open handle") unless openhandle($self->get_stream);

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::ToStream - a monitor implementation that prints
stringified feedback to a stream.

=head1 SYNOPSIS

  ...
  # call someTask and give it a monitor that prints to stdout
  #
  someTask(ProgressMonitor::Stringify::ToStream->new({fields => [ ... ]}));
  
=head1 DESCRIPTION

This is a concrete implementation of a ProgressMonitor. It will send the stringified
feedback to a stream and backspace to continously overwrite. Optionally, it will
clear the feedback entirely, leaving the cursor where it was.

Note that this is probably most useful to send to either stdout/stderr. Sending to
a basic disk file probably won't many people happy...See ToCallback if you want to 
be more clever.

Also, this assumes that backspacing will work correctly which may not be true if
the width is so large that the terminal window starts on a new line. Use the inherited
configuration 'maxWidth' to limit the width if you have the necessary information.

Inherits from ProgressMonitor::Stringify::AbstractMonitor.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:
  stream (default => \*STDOUT)
    The stream to where the stringified feedback should go.
  wipeAtEnd (default => 0)
    Whether the feedback should be wiped at the end.
    
=back

=head1 AUTHOR

Kenneth Olwing, C<< <knth at cpan.org> >>

=head1 BUGS

I wouldn't be surprised! If you can come up with a minimal test that shows the
problem I might be able to take a look. Even better, send me a patch.

Please report any bugs or feature requests to
C<bug-progressmonitor at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=ProgressMonitor>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find general documentation for this module with the perldoc command:

    perldoc ProgressMonitor

=head1 ACKNOWLEDGEMENTS

Thanks to my family. I'm deeply grateful for you!

=head1 COPYRIGHT & LICENSE

Copyright 2006 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::Stringify::ToStream
