package Bio::KBase::AuthDirectory;

use strict;
use warnings;
use Object::Tiny::RW qw{ error_message };
use Bio::KBase::AuthUser;
use Bio::KBase::Auth;
use JSON;
use REST::Client;
use Digest::SHA;
use MIME::Base64;
use Email::Valid;

our $rest = undef;
our $verbose_warnings = 0;

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(
        'error_message' => '',
    @_);

    unless ( defined $rest) {
        $rest = new REST::Client( host => $Bio::KBase::Auth::AuthSvcHost);
    }

    return $self;
}

sub lookup_user {
    my $self= shift;
    my $user_id = shift;
    my $json;
    my $newuser;
    my $query;
    my @attrs;

    if ($user_id) {
        eval {
            $query = '/profiles/'.$user_id;
            $rest->GET($query);
            unless ( ($rest->responseCode() < 300) && ($rest->responseCode() >=200)) {
	      die $rest->responseCode() . ":" . $rest->responseContent();
            }
            $json = from_json( $rest->responseContent());
            unless ( exists($json->{$user_id})) {
                die "User not found";
            }
            # Need to wedge the json response into an authuser object
            $newuser = new Bio::KBase::AuthUser;
            @attrs = ( 'user_id','consumer_key','consumer_secret','token',
                   'error_message','enabled','last_login_time','last_login_ip',
                   'roles','groups','oauth_creds','name','given_name','family_name',
                   'middle_name','nickname','profile','picture','website','email',
                   'verified','gender','birthday','zoneinfo','locale','phone_number',
                   'address','updated_time');
            foreach  (@attrs) {
            $newuser->{$_} = $json->{$user_id}->{$_};
            }
            $self->_SquashJSONBool($newuser)
        };
        if ($@) {
            print STDERR "Error while fetching user: $@" if $verbose_warnings;
            $self->error_message($@);
            return;
        }
	    return $newuser;
    } else {
    	print STDERR "Did not find user_id" if $verbose_warnings;
	    return;
    }
}

sub lookup_consumer {
    my $self= shift;
    my $consumer_key = shift;
    my $json;
    my $newuser;
    my $query;
    my @attrs;
    my $user_id;

    if ($consumer_key) {
	eval {
	    $query = '/oauthkeys/'.$consumer_key;
	    $rest->GET($query);
	    unless ( ($rest->responseCode() < 300) && ($rest->responseCode() >=200)) {
	      die "AuthServer Error ".$rest->responseCode() . ":" . $rest->responseContent();
            }
	    $json = from_json( $rest->responseContent());
	};
	if ($@) {
	  print STDERR "Error while fetching user: $@" if $verbose_warnings;
	  $self->error_message("Error while fetching user: $@");
	  return;
	}
	if ($json->{$consumer_key}->{'user_id'}) {
	    $user_id = $json->{$consumer_key}->{'user_id'};
	    return $self->lookup_user( $user_id);
	} else {
	    print STDERR "Did not find consumer_key $consumer_key" if $verbose_warnings;
	    $self->error_message("Did not find consumer_key $consumer_key");
	    return;
	}
    } else {
    	print STDERR "Must specify consumer key" if $verbose_warnings;
	    $self->error_message("Must specify consumer key");
	return;
    }

}

sub lookup_oauth2_token {
    my $self= shift;
    my $oauth_token = shift;
    my $json;
    my $newuser;
    my $query;
    my @attrs;
    my $oauth_key_id;

    if ($oauth_token) {
	eval {
	    $query = '/oauthtokens/'.$oauth_token;
	    $rest->GET($query);
	    $json = from_json( $rest->responseContent());
	};
	if ($@) {
	    print STDERR "Error while fetching oauth token: $@" if $verbose_warnings;
	    return;
	}
	if ($json->{$oauth_token}->{'oauth_key'}) {
	    $oauth_key_id = $json->{$oauth_token}->{'oauth_key'};
	    return $self->lookup_consumer( $oauth_key_id);
	} else {
	    print STDERR "Did not find oauth_token $oauth_token" if $verbose_warnings;
	    return;
	}
    } else {
	print STDERR "Must specify oauth token $oauth_token" if $verbose_warnings;
	return;
    }
}

sub _validate_user {
    my $self = shift;
    my $user = shift;

    if (ref $user ne "Bio::KBase::AuthUser") {
    	$self->error_message("User object required parameter");
    	return;
    }

    # perform basic validation of required fields
    my %valid = (
        'user_id'=> '^\w{3,}$',
        'name'   => '^[-\w\' \.]{2,}$',
	);
    my @bad = grep { ! defined $user->$_() || $user->$_() !~ m/$valid{$_}/ } sort keys %valid;

    if (! Email::Valid->address($user->email)) {
        push @bad, 'email';
        @bad = sort @bad;
    }

    if ( @bad ) {
    	$self->error_message("These fields failed validation: " . join( ",", @bad ) );
	    return;
    }
    else {
        return 1;
    }
}

sub create_user {
    my $self= shift;
    my $newuser = shift;

    $self->_validate_user($newuser) or return;

    # convert the hash into a json string and POST it
    my $unblessed = {%$newuser};
    # get rid of oauth_creds hashref
    delete $unblessed->{oauth_creds};

    my $json = to_json( $unblessed );
    my $res = $rest->POST("/profiles/", $json, {'Content-Type' => 'application/json'});
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
	$self->error_message($rest->responseCode() . " : " . $rest->responseContent());
	return;
    }
    # Otherwise fetch the entry and return it


    my $loaded_user = $self->lookup_user( $newuser->user_id());
    @{$newuser}{keys %$loaded_user} = values %$loaded_user;
    return $newuser;
}

sub update_user {
    my $self= shift;
    my $newuser = shift;

    $self->_validate_user($newuser) or return;

    # make sure the user exists
    unless ( $self->lookup_user( $newuser->user_id())) {
	$self->error_message("User does not exist");
	return;
    }

    # convert the hash into a json string and POST it
    my $unblessed = {%$newuser};
    # get rid of oauth_creds hashref
    delete $unblessed->{oauth_creds};

    my $json = to_json( $unblessed );
    my $res = $rest->PUT("/profiles/".$newuser->user_id(), $json, {'Content-Type' => 'application/json'});
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
	$self->error_message($rest->responseCode() . " : " . $rest->responseContent());
	return;
    }
    # Otherwise fetch the entry and return it

    my $loaded_user = $self->lookup_user( $newuser->user_id());
    @{$newuser}{keys %$loaded_user} = values %$loaded_user;
    return $newuser;
}

sub delete_user {
    my $self= shift;
    my $user_id = shift;

    unless ($user_id) {
        $self->error_message("Cannot delete_user w/o user_id");
        return;
    }

    my $res = $rest->DELETE("/profiles/".$user_id);
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
    	$self->error_message($rest->responseCode() . " : " . $rest->responseContent());
	    return;
    }

    return 1;
}

sub enable_user {
    my $self= shift;
    my $user_id = shift;

    unless ($user_id) {
        $self->error_message("Cannot enable_user w/o user_id");
        return;
    }

    my $json = to_json( { enabled => JSON::true });
    my $res = $rest->PUT("/profiles/" . $user_id, $json, {'Content-Type' => 'application/json'});
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
	$self->error_message($rest->responseCode() . " : " . $rest->responseContent());
	return;
    }

    return $self->lookup_user( $user_id) ;
}

sub disable_user {
    my $self= shift;
    my $user_id = shift;

    unless ($user_id) {
        $self->error_message("Cannot disable_user w/o user_id");
        return;
    }

    my $json = to_json( { enabled => JSON::false });
    my $res = $rest->PUT("/profiles/" . $user_id, $json, {'Content-Type' => 'application/json'});
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
	$self->error_message($rest->responseCode() . " : " . $rest->responseContent());
    	return;
    }

    return $self->lookup_user( $user_id) ;
}

sub new_consumer {
    my $self= shift;
    my $user_id = shift;
    my $key = shift;
    my $secret = shift;

    unless ( $self->lookup_user( $user_id)) {
	    $self->error_message("User not found");
    	return;
    }

    srand (time ^ $$ ^ unpack "%L*", `ps axww | gzip -f`);

    # check to see if we have been given a key, if so, lets
    # make sure it isn't a duplicate - if it is, return a fail.

    if ( $key ) {
	if ( $self->lookup_consumer( $key)) {
	    $self->error_message("Duplicate consumer key");
	    return( undef );
	}
    } else {
	# generate one based on username and hex numbers
	$key = $user_id . sprintf( "_%x", (time() + rand())*1000);
    }

    # do the same for the secret, generate a pseudo-random secret
    #
    unless ($secret) {
	$secret = Digest::SHA::sha512_base64(join( '', time(),  map { rand() } (0..10)));
    }

    # push the new consumer key into the profile service
    my $json = to_json( { oauth_key => $key,
			  oauth_secret => $secret,
			  user_id => $user_id});
    my $res = $rest->POST("/oauthkeys/", $json, {'Content-Type' => 'application/json'});
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
	    $self->error_message($rest->responseCode() . " : " . $rest->responseContent());
    	return;
    }

    return
        {
            'oauth_key'    => $key,
	        'oauth_secret' => $secret
	    };
}

sub delete_consumer {
    my $self= shift;
    my $consumer_key = shift;

    unless ( $self->lookup_consumer( $consumer_key)) {
	$self->error_message("Consumer key not found");
	return;
    }

    my $res = $rest->DELETE("/oauthkeys/".$consumer_key);
    # If we get something other than a 2XX code, flag an error
    if (($rest->responseCode() < 200) || ($rest->responseCode() > 299)) {
	$self->error_message($rest->responseCode() . " : " . $rest->responseContent());
	return;
    }

    return 1;
}

sub _SquashJSONBool {
    # Walk an object ref returned by from_json() and squash references
    # to JSON::XS::Boolean
    my $self = shift;
    my $json_ref = shift;
    my $type;

    foreach (keys %$json_ref) {
	$type = ref $json_ref->{$_};
	next unless ($type);
	if ( 'HASH' eq $type) {
	    _SquashJSONBool( $self, $json_ref->{$_});
	} elsif ( 'JSON::XS::Boolean' eq $type) {
	    $json_ref->{$_} = ( $json_ref->{$_} ? 1 : 0 );
	}
    }
    return $json_ref;
}
1;

__END__

=pod

=head1 Bio::KBase::AuthDirectory

Administrative API for manipulating users, keys and tokens on the profile server

=head2 Examples

use Bio::KBase::AuthDirectory;

$ad = new Bio::KBase::AuthDirectory;

# Lookup user records based on user_id, consumer key and token

$user = $ad->lookup_user('sychan');

$user = $ad->lookup_consumer('key1');

$user = $ad->lookup_oauth2_token('token1');

# Lets create a new user with minimal attributes and

# write it into the profile service

$user = new Bio::KBase::AuthUser;

$user->user_id('sychan2');

$user->name('s chan again');

$user->email('sychan2@lbl.gov');

$newuser = $ad->create_user( $user);

# Okay, lets delete them

$ad->delete_user($newuser->user_id);

=head2 Instance Variables

=over

=item B<error_message>

This is a string containing the last error generated by a call to an AuthDirectory method

=back

=head2 Methods

=over

=item B<new>([string registry URL],[TBD admin credentials])

returns Bio::KBase::AuthDirectory 

Optionally takes: (not yet implemented)
registry URL - a URL to a particular user registry. Will default to the standard registry, but can be used to connect to different ones
admin credentials - credentials for administrative access to the Registry

Administrative credentials allow updates and access to fields such as “consumer secret” and various tokens. Otherwise the registry allows lookups of users and their public information, but no ability to update the store, aside from the currently logged in user

=item B<lookup_user>(string user_id)

returns Bio::KBase::AuthUser

=item B<lookup_consumer>(string consumer_key)

returns Bio::KBase::AuthUser 

=item B<lookup_oauth2_token>(string token)

returns Bio::KBase::AuthUser

These three methods lookup user records based on user_id, consumer_key or token respectively. All return a single AuthUser object if successful, undef others.

=item B<create_user>( Bio::KBase::Authuser user)

returns Bio::KBase::AuthUser

When given a populated user object, will create a new user in the registry and return it. If there is an error will return null and set error_msg. Must have administrative privs to create new users

=item B<delete_user>( string user_id)

returns boolean

When given a user_id, will delete that user from the database

=item B<enable_user>( string user_id)

returns boolean 

Enables a user based on the user_id. This user will once again be able to login. Can only be used with admin privs

=item B<disable_user>( string user_id)

returns boolean

Disables a user based on user_id. This user will be unable to login. Can only be used with admin privs

=item B<new_consumer>( string user_id,[oauth_key, oauth_secret])

returns hash {oauth_key => key, oauth_secret => secret}

Creates a consumer (key,secret) pair and associates it with that user in the directory. Alternatively, if a (key,secret) is passed in, this new pair will be associated with the user’s profile. This pair can then be used to authenticate to the system. The key is guaranteed to be unique within the directory. The secret is not guaranteed to be unique, but it should an otherwise random value. There is some leeway in the consumer key - it can be a user readable, but unique string (for example username + sequence number) or just an opaque string such as a hash. The secret should be the base64 encoding of reasonably sound entropy source (256 bits from a well designed entropy source). It is important that the secret not pass over a cleartext channel.

=item B<delete_consumer>( string consumer_key)

returns boolean

Find the user record associated with the consumer_key and delete the consumer (key,secret) pair from their record. This pair can no longer be used to authenticate to the system.

=back


=cut
