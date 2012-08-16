package Bio::KBase::AuthUser;

use strict;
use warnings;
# We use Object::Tiny::RW to generate getters/setters for the attributes
# and save ourselves some tedium
use Object::Tiny::RW qw {
    token
    error_message
    enabled
    last_login_time
    last_login_ip
    roles
    groups
    oauth_creds
    name
    given_name
    family_name
    middle_name
    nickname
    profile
    picture
    website
    email
    verified
    gender
    birthday
    zoneinfo
    locale
    phone_number
    address
    updated_time
};

sub new() {
    my $class = shift;

    # Don't bother with calling the Object::Tiny::RW constructor,
    # since it doesn't do anything except return a blessed empty hash
    my $self = $class->SUPER::new(
        'oauth_creds' => {},
        @_
    );

    return($self);
}

sub user_id {
    my $self = shift;
    my $user_id = shift;

    # If there is a user_id value set already, do not accept a new
    # value, just return the old value

    if ($user_id && !(exists $self->{user_id})) {
	$self->{'user_id'} = $user_id;
    }
    return( $self->{'user_id'});
}

1;

__END__

=pod

=head1 Bio::KBase::AuthUser

User object for KBase authentication. Stores user profile and authentication information, including oauth credentials.

This is a container for user attributes - creating, destroying them in the user database is handled by the Bio::KBase::AuthDirectory class.

=head2 Examples

   my $user = Bio::KBase::AuthUser->new()
   # Voila!

=head2 Instance Variables

=over


=item B<user_id> (string)

REQUIRED Identifier for the End-User at the Issuer.

=item B<error_message> (string)

contains error messages, if any, from most recent method call

=item B<enabled> (boolean)

Is this user allowed to login

=item B<last_login_time> (timestamp)

time of last login

=item B<last_login_ip> (ip address)

ip address of last login

=item B<roles> (string array)

An array of strings for storing roles that the user possesses

=item B<groups> (string array)

An array of strings for storing Unix style groups that the user is a member of

=item B<oauth_creds> (hash)

reference to hash array keyed on consumer_keys that stores keys, secrets, verifiers and tokens associated with this user

=item B<name> (string)

End-User's full name in displayable form including all name parts, ordered according to End-User's locale and preferences.

=item B<given_name> (string)

Given name or first name of the End-User.

=item B<family_name> (string)

Surname or last name of the End-User.

=item B<middle_name> (string)

Middle name of the End-User.

=item B<nickname> (string)

Casual name of the End-User that may or may not be the same as the given_name. For instance, a nickname value of Mike might be returned alongside a given_name value of Michael.

=item B<profile> (string)

URL of End-User's profile page.

=item B<picture> (string)

URL of the End-User's profile picture.

=item B<website> (string)

URL of End-User's web page or blog.

=item B<email> (string)

The End-User's preferred e-mail address.

=item B<verified> (boolean)

True if the End-User's e-mail address has been verified; otherwise false.

=item B<gender> (string)

The End-User's gender: Values defined by this specification are female and male. Other values MAY be used when neither of the defined values are applicable.

=item B<birthday> (string)

The End-User's birthday, represented as a date string in MM/DD/YYYY format. The year MAY be 0000, indicating that it is omitted.

=item B<zoneinfo> (string)

String from zoneinfo [zoneinfo] time zone database. For example, Europe/Paris or America/Los_Angeles.

=item B<locale> (string)

The End-User's locale, represented as a BCP47 [RFC5646] language tag. This is typically an ISO 639-1 Alpha-2 [ISO639‑1] language code in lowercase and an ISO 3166-1 Alpha-2 [ISO3166‑1] country code in uppercase, separated by a dash. For example, en-US or fr-CA. As a compatibility note, some implementations have used an underscore as the separator rather than a dash, for example, en_US; Implementations MAY choose to accept this locale syntax as well.

=item B<phone_number> (string)

The End-User's preferred telephone number. E.164 [E.164] is RECOMMENDED as the format of this Claim. For example, +1 (425) 555-1212 or +56 (2) 687 2400.

=item B<address> (JSON object)

The End-User's preferred address. The value of the address member is a JSON [RFC4627] structure containing some or all of the members defined in Section 2.4.2.1.

=item B<updated_time> (string)

Time the End-User's information was last updated, represented as a RFC 3339 [RFC3339] datetime. For example, 2011-01-03T23:58:42+0000.

=back

=head2 Methods

=over

=item B<new>()

returns a Bio::KBase::AuthUser reference

=back

=cut
