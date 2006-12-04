package ProgressMonitor::Stringify::AbstractMonitor;

use warnings;
use strict;

use ProgressMonitor::Exceptions;

# Attributes:
#	width
#		The final width the field(s) this monitor manages will occupy
use classes
  extends       => 'ProgressMonitor::AbstractStatefulMonitor',
  class_methods => ['_new'],
  attrs_ro      => ['width',],
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

### protected

# helper method to call each field and render a complete line
#
sub _toString
{
	my $self = shift;

	my $state = $self->_get_state;
	my $ticks = $self->_get_ticks;
	my $totalTicks = $self->_get_totalTicks;

	my $rendition = '';
	for (@{$self->_get_cfg->get_fields})
	{
		# ask each field to render itself but ensure the result is exactly the width is
		# what its supposed to be
		#
		my $fr = $_->render($state, $ticks, $totalTicks);
		my $fw = $_->get_width;
		$rendition .= sprintf("%*.*s", $fw, $fw, $fr);
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
#		Defaults to 79 for lack of better value, to fit in 80 chars
#	fields
#		An array of fields (or a single field if only one) that should be used
#		A field instance can not be reused in the list!
#
use classes
  extends => 'ProgressMonitor::AbstractStatefulMonitorConfiguration',
  attrs   => ['maxWidth', 'fields',],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {
			%{$self->SUPER::defaultAttributeValues()},
			maxWidth => 79,
			fields   => [],
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
  maxWidth (default => 79)
    The monitor should have this maxWidth. The actual width used may be less. This
    depends on the fields it uses; specifically, if dynamic fields are used, they
    will be given width until all is used or until the dynamic fields themselves 
    have reached their maxWidth if any.
  fields (default => [])
    An array ref with field instances.
    
Throws X::ProgressMonitor::InsufficientWidth if the maxWidth is to small to 
handle the minimum requirements for all the fields.

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

Copyright 2006 Kenneth Olwing, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;    # End of ProgressMonitor::Stringify::AbstractMonitor
