package Bio::KBase::Auth;
#
# Common information across the apps
#
# sychan 4/24/2012
use strict;

$Bio::KBase::Auth::AuthSvcHost = "http://localhost/";

our $VERSION = 0.1;

1;

__END__

=pod

=head1 Bio::KBase::Auth

OAuth based authentication for Bio::KBase::* libraries.

This is a helper class that stores shared configuration information.

=head2 Class Variables

=over

=item B<$Bio::KBase::Auth::AuthSvcHost>

   This variable contains a URL that points to the authentication service that stores
user profiles. If this is not set properly, the libraries will be unable to reach
the centralized user database and authentication will not work at all.


=item B<$VERSION>

   The version of the libraries.

=back

=cut

