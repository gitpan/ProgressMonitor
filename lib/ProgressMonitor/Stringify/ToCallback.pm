package ProgressMonitor::Stringify::ToCallback;

use warnings;
use strict;

use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitor',
  new     => 'new',
  ;

sub new
{
	my $class = shift;
	my $cfg   = shift;

	my $self = $class->SUPER::_new($cfg, $CLASS);

	return $self;
}

sub render
{
	my $self = shift;

	my $cancel = &{$self->_get_cfg->get_callback}($self->_toString);
	$self->setCanceled($cancel) unless $self->isCanceled;

	return;
}

###

package ProgressMonitor::Stringify::ToCallbackConfiguration;

use strict;
use warnings;

# Attributes:
#	callback (code ref)
#		The callback will be called with the rendered string and should return a
# 		boolean, which will be used to set the cancellation status with.
use classes
  extends => 'ProgressMonitor::Stringify::AbstractMonitorConfiguration',
  attrs   => ['callback'],
  ;

sub defaultAttributeValues
{
	my $self = shift;

	return {%{$self->SUPER::defaultAttributeValues()}, callback => sub { X::Usage->throw("missing callback"); 1; },};
}

sub checkAttributeValues
{
	my $self = shift;

	$self->SUPER::checkAttributeValues();

	X::Usage->throw("callback is not a code ref") unless ref($self->get_callback) eq 'CODE';

	return;
}

############################

=head1 NAME

ProgressMonitor::Stringify::ToCallback - a monitor implementation that provides
stringified feedback to a callback.

=head1 SYNOPSIS

  ...
  # call someTask and give it a monitor to call us back
  # on callback, just do something unimaginative (print it...:-) and return 0 (don't cancel)
  #
  someTask(ProgressMonitor::Stringify::ToCallback->new({fields => [ ... ], callback => sub { print "GOT: ", shift(), "\n"; 0; });
  
=head1 DESCRIPTION

This is a concrete implementation of a ProgressMonitor. It will send the stringified
feedback to a callback (code ref) supplied by the user.

Inherits from ProgressMonitor::Stringify::AbstractMonitor.

=head1 METHODS

=over 2

=item new( $hashRef )

Configuration data:
  callback
    A code reference to an anonymous sub. For each rendering, it will be called
    with the rendered string as the argument. The return value will be used to 
    set the cancellation status.
    
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

1;    # End of ProgressMonitor::Stringify::ToCallback
