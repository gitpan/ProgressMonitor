package ProgressMonitor::Stringify::AbstractMonitor;

use warnings;
use strict;

use ProgressMonitor::Exceptions;

require ProgressMonitor::AbstractStatefulMonitor if 0;

# Attributes:
#	width
#		The final width the field(s) this monitor manages will occupy
use classes
  extends       => 'ProgressMonitor::AbstractStatefulMonitor',
  class_methods => ['_new'],
  attrs_ro      => ['width',],
  attrs_pr      => ['msgto'],
  throws        => ['X::ProgressMonitor::InsufficientWidth',],
  ;

sub _new
{
	my $class  = shift;
	my $cfg    = shift;
	my $cfgPkg = shift;

	# get the instance from the super class
	#
	my $self = $class->SUPER::_new($cfg, $cfgPkg);

	# retrieve the configuration for easy reference
	#
	$cfg = $self->_get_cfg;

	# what max width has the user asked for?
	#
	my $maxWidth = $cfg->get_maxWidth;

	my $allFields = $cfg->get_fields;

	# what is the minimum combined width needed to begin with?
	#
	my $wsum = 0;
	$wsum += $_->get_width for (@$allFields);
	X::ProgressMonitor::InsufficientWidth->throw($wsum) if $wsum > $maxWidth;

	# in a round robin fashion, try to fairly give dynfields
	# extra width until all are full, or width is exhausted
	#

	# first make a separate list of the dynamic fields
	#
	my @dynFields;
	for (@$allFields)
	{
		push(@dynFields, $_) if $_->isDynamic;
	}

	# begin with the width we have left to give out
	# and loop while there is any width left and there are any dynamic fields
	# that are 'still hungry'...
	#
	my $remainingWidth = $maxWidth - $wsum;
	while ($remainingWidth && @dynFields)
	{
		my $dynFieldCount = @dynFields;

		# make a list with the current width we have fairly distributed
		#
		my @allotments;
		$allotments[$_ % $dynFieldCount]++ for (0 .. ($remainingWidth - 1));

		# now iterate over the list and give the corresponding dynfield the
		# width it has been allotted.
		# it will report how much it 'used' (due to its own constraints, if any)
		# and we can disseminate remains in the next loop
		#
		for (0 .. (@allotments - 1))
		{
			my $allottedExtraWidth = $allotments[$_];
			my $unusedExtraWidth   = $dynFields[$_]->grabExtraWidth($allottedExtraWidth);
			$remainingWidth -= $allottedExtraWidth - $unusedExtraWidth;
		}

		# now recalculate the list with dynfields (any fields that have
		# reached their max width are no longer (dynamic')
		#
		@dynFields = ();
		for (@$allFields)
		{
			push(@dynFields, $_) if $_->isDynamic;
		}
	}

	# finally set the width we've actually used
	#
	$self->{$ATTR_width} = $maxWidth - $remainingWidth;

	return $self;
}

sub setMessage
{
	my $self = shift;
	my $msg  = shift;

	$self->{$ATTR_msgto} = undef;

	return $self->SUPER::setMessage($msg);
}

### protected

sub _get_message
{
	my $self = shift;

	my $now = time;
	if (defined($self->{$ATTR_msgto}))
	{
		$self->setMessage(undef) if ($self->{$ATTR_msgto} <= $now);
	}
	else
	{
		my $to = $self->_get_cfg->get_messageTimeout;
		$self->{$ATTR_msgto} = time + $to if $to >= 0;
	}

	return $self->SUPER::_get_message;
}

# helper method to call each field and render a complete line
#
sub _toString
{
	my $self            = shift;
	my $considerMessage = shift();

	$considerMessage = 1 unless defined($considerMessage);

	my $state      = $self->_get_state;
	my $ticks      = $self->_get_ticks;
	my $totalTicks = $self->_get_totalTicks;

	my $cfg       = $self->_get_cfg;
	my $rendition = '';
	my $allFields = $cfg->get_fields;
	for (@$allFields)
	{
		# ask each field to render itself but ensure the result is exactly the width is
		# what its supposed to be
		#
		my $fr = $_->render($state, $ticks, $totalTicks);
		my $fw = $_->get_width;
		$rendition .= sprintf("%*.*s", $fw, $fw, $fr);
	}

	if ($considerMessage)
	{
		my $ms  = $cfg->get_messageStrategy;
		my $msg = $self->_get_message;
		if ($msg && $ms ne 'none')
		{
			my $w = $self->{$ATTR_width};

			if ($ms eq 'newline')
			{
				$msg .= $cfg->get_messageFiller x ($w - length($msg)) if ($w > length($msg));
				$rendition = sprintf("%*.*s\n%s", $w, $w, $msg, $rendition);
				$self->setMessage(undef);
			}
			else
			{
				# overlay
				#
				my $start_ovrfld = $cfg->get_messageOverlayStartField;
				my $end_ovrfld   = $cfg->get_messageOverlayEndField;
				my $start_ovrpos;
				my $end_ovrpos;
				my $offset = 0;
				for (1 .. @$allFields)
				{
					$start_ovrpos = $offset if $start_ovrfld == $_;
					$offset += $allFields->[$_ - 1]->get_width;
					$end_ovrpos = $offset if $end_ovrfld == $_;
					last if ($start_ovrpos && $end_ovrpos);
				}
				my $mf = $cfg->get_messageFiller;
				my $len = $mf ? $end_ovrpos - $start_ovrpos : length($msg);
				$msg .= $cfg->get_messageFiller x ($len - length($msg)) if ($len > length($msg));
				substr($rendition, $start_ovrpos, $len) = $msg;
			}
		}
	}

	return $rendition;
}

###

package ProgressMonitor::Stringify::AbstractMonitorConfiguration;

use strict;
use warnings;

use Scalar::Util qw(blessed);

# Attributes:
#	maxWidth
#		The maximum width this monitor can occupy altogether.
#	fields
#		An array of fields (or a single field if only one) that should be used
#		A field instance can not be reused in the list!
#   messageStrategy
#       Determines the strategy to use when displaying messages.
#       'none'   : doesn't display messages
#       'overlay': requires 'messageOverlaysFields' to be set
#       'newline': renders it with a newline at the end, in effect pushing the
#                  other fields 'down'.
#   messageOverlayStartfield
#       The field on which message overlay should start. Defaults to 0.
#   messageOverlayEndfield
#       The field on which message overlay should end. Defaults to last field.
#   messageFiller
#       The character for filling out the length of the message if
#       is not long enough to overlay the full length of the field(s)
#       it is set to overlay.
#   messageTimeout
#       The time in seconds before the message is cleared automatically. This
#       is only relevant for overlay (for newline, it only appears once).
#       Defaults to 3 seconds. Set to -1 for 'no timeout'.
#
use classes
  extends => 'ProgressMonitor::AbstractStatefulMonitorConfiguration',
  attrs   => ['maxWidth', 'fields', 'messageStrategy', 'messageOverlayStartField', 'messageOverlayEndField', 'messageFiller',
			'messageTimeout'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			maxWidth                 => 0,
			fields                   => [],
			messageStrategy          => 'newline',
			messageOverlayStartField => 1,
			messageOverlayEndField   => undef,
			messageFiller            => ' ',
			messageTimeout           => 3,
		   };
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues;

	my $maxWidth = $self->get_maxWidth;
	X::Usage->throw("invalid maxWidth: $maxWidth") unless $maxWidth >= 0;

	my $fields = $self->get_fields;
	if (ref($fields) ne 'ARRAY')
	{
		$fields = [$fields];
		$self->set_fields($fields);
	}

	my %seenFields;
	for (@$fields)
	{
		X::Usage->throw("not a field: $_") unless (blessed($_) && $_->isa("ProgressMonitor::Stringify::Fields::AbstractField"));
		X::Usage->throw("same instance of field used more than once: $_") if $seenFields{$_};
		$seenFields{$_} = 1;
	}

	my $ms = $self->get_messageStrategy;
	X::Usage->throw("invalid value for messageStrategy: $ms") unless $ms =~ /^(?:none|overlay|newline)$/;

	if ($ms eq 'overlay')
	{
		my $maxFieldNum = @$fields;
		$self->set_messageOverlayEndField($maxFieldNum) unless defined($self->get_messageOverlayEndField);

		my $start = $self->get_messageOverlayStartField;
		my $end   = $self->get_messageOverlayEndField;
		X::Usage->throw("illegal overlay start field: $start") if ($start < 1 || $start > $maxFieldNum);
		X::Usage->throw("illegal overlay end field: $end")
		  if ($end < 1 || $end > $maxFieldNum || $end < $start);
	}

	my $mf = $self->get_messageFiller;
	X::Usage->throw("messageFiller not a character: $mf") if length($mf) > 1;

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::AbstractMonitor - A reusable/abstract monitor implementation
that deals in stringified feedback.

=head1 DESCRIPTION

This is an abstract base class for monitors that will render their result as a string 
through the use of 'fields' (see the L<Fields> packages).

=head1 PROTECTED METHODS

=over 2

=item _new( $hashRef, $package )

Configuration data:

=over 2

=item maxWidth (default => 79)

The monitor should have this maxWidth. The actual width used may be less. This
depends on the fields it uses; specifically, if dynamic fields are used, they
will be given width until all is used or until the dynamic fields themselves 
have reached their maxWidth if any.

Throws X::ProgressMonitor::InsufficientWidth if the maxWidth is to small to 
handle the minimum requirements for all the fields.

=item fields (default => [])

An array ref with field instances.

=item messageStrategy (default => newline)

An identifiers that describes how messages should be inserted into the
rendition:

=over 2

=item none

Not surprisingly, this suppresses message presentation.

=item overlay

This will cause the message to overlay one or more of the other
fields, so as to keep things on one line. This setting will work
in conjunction with messageTimeout, messageOverlayStartField and
messageOverlayEndField.

=item newline

This will cause the message and a newline to be inserted in front
of the regular rendition, causing the running rendition to be
'pushed' forward.

=back

=item messageFiller (default => ' ')

If the message is too short for the allotted space, it will be filled with
this character. Can be set to the empty string or undef to skip filling,
causing a 'partial overlay', i.e. just as much as the string is, which 
obviously can give a confusing mixed message with the underlying field.

=item messageTimeout (default => 3 seconds)

This is only relevant for the 'overlay' strategy. If the code doesn't
explicitly set the message to undef/blank, the timeout will automatically
remove it. Set to -1 for infinite.

=item messageOverlayStartField, messageOverlayEndField (defaults => all fields)

Together these define the starting and ending field number that the message
should overlay. This defaults to 'all fields'.

=back

=item _toString

Contains the logic to assemble the fields into a current string.

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

Copyright 2006,2007 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::Stringify::AbstractMonitor
