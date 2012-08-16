package Bio::KBase::AuthClient;

use strict;
use warnings;
use Object::Tiny::RW qw { user logged_in error_message oauth_cred};
use Bio::KBase::Auth;
use Bio::KBase::AuthUser;
use MIME::Base64;
use Bio::KBase::AuthDirectory;
use JSON;
use Net::OAuth;
use Digest::MD5 qw(md5_base64);
use Data::Dumper;

# Location of the file where we're storing the authentication
# credentials
# It is a JSON formatted file with the following
# {"oauth_key":"consumer_key_blahblah",
#  "oauth_token":"token_blah_blah",
#  "oauth_secret":"consumer_secret_blahblah"
# }
#

our $auth_rc = "~/.kbase-auth";



sub new {
    my $class = shift @_;
    my %params = @_;

    my $self = $class->SUPER::new(
        'user'       => Bio::KBase::AuthUser->new,
        'oauth_creds' => {},
        'logged_in'  => 0,
        'error_message'  => "",
        @_
    );

    # Try calling login to see if creds defined

    eval {
	my @x = glob( $auth_rc);
	my $auth_rc = shift @x;
	if (exists($params{ consumer_key})) {
	    $self->login( %params);
	    unless ($self->{logged_in}) {
		die( "Authentication failed: " . $self->error_message);
	    }
	} elsif (-e $auth_rc && -r $auth_rc) {
	    if (-e $auth_rc && -r $auth_rc) {
		open RC, "<", $auth_rc or die "Could not open $auth_rc : $!";
		my @rc = <RC>;
		close RC;
		chomp( @rc);
		my $creds = from_json( join( '',@rc));
		unless ( defined( $creds->{'oauth_key'})) {
		    die "No oauth_key found in $auth_rc";
		}
		unless ( defined( $creds->{'oauth_secret'})) {
		    die "No oauth_secret found in $auth_rc";
		}
		unless ($self->login( $creds->{'oauth_key'},$creds->{'oauth_secret'})) {
		    # login failed, pass the error message along. Redundant for now, but
		    # we don't want later code possibly stomping on this result
		    die "auth_rc credentials failed login: " . $self->error_message;
		}
	    }
	}
    };
    if ($@) {
	$self->error_message($@);
    }
    return $self;
}

sub login {
    my $self = shift;
    my %p = @_;
    my $creds;
    my $creds2;

    $self->{logged_in} = 0;
    eval {
	my @x = glob( $auth_rc);
	my $auth_rc = shift @x;
        if ( $p{consumer_key} && $p{consumer_secret}) {
            $creds->{'oauth_key'} = $p{consumer_key};
            $creds->{'oauth_secret'} = $p{consumer_secret};
        } elsif ($auth_rc && -r $auth_rc) {
            open RC, "<", $auth_rc;
            my @rc = <RC>;
            close RC;
            chomp( @rc);
            $creds = from_json( join( '',@rc));
        }

        unless ( defined( $creds->{'oauth_key'})) {
            die "No oauth_key found";
        }
        unless ( defined( $creds->{'oauth_secret'})) {
            die "No oauth_secret found";
        }

        # This is a not a production-ready way to perform logins, but
        # we're using it here for alpha testing,
        # and must be replaced with oauth protected login before
        # fetching user creds
        my $ad = new Bio::KBase::AuthDirectory;
        my $user = $ad->lookup_consumer( $creds->{'oauth_key'});
	unless (defined($user)) {
	  die "Could not retrieve user: ".$ad->error_message;
	}
        unless ( defined($user->oauth_creds()->{$creds->{'oauth_key'}})) {
            die "Could not find matching oauth_key in user database";
        }
        $creds2 = $user->oauth_creds()->{$creds->{'oauth_key'}};
        unless ( $creds2->{'oauth_secret'} eq $creds->{'oauth_secret'}) {
            die "oauth_secret does not match";
        }
        $self->{user} =  $user;
        $self->{oauth_cred} = $creds2;
        $self->{logged_in} = 1;
    };
    if ($@) {
	    $self->error_message("Local credentials invalid: $@");
    	return 0;
    } else {
    	return 1;
    }
}

sub sign_request {
    my $self = shift;
    my $request = shift;

    # setup the request method and URL

    # Create the appropriate authorization header with the auth_token
    # call and then push it into the request envelope
    my $authz_hdr = $self->auth_token( request_url => $request->uri->as_string,
				       request_method => $request->method);

    $request->header( Authorization => $authz_hdr);

    return 1;
}

sub auth_token {
    my $self = shift;
    my %auth_params = @_;

    unless ( defined( $self->{oauth_cred})) {
    	carp( "No oauth_cred defined in AuthClient object\n");
	    return;
    }
    my $oauth = Net::OAuth->request('consumer')->new(
	consumer_key => $self->{oauth_cred}->{oauth_key},
	consumer_secret => $self->{oauth_cred}->{oauth_secret},
	request_url => $auth_params{request_url},
	request_method => $auth_params{request_method},
	timestamp => time,
	signature_method => 'HMAC-SHA1',
	nonce => md5_base64( map { rand() } (0..4)));
    $oauth->sign;

    return $oauth->to_authorization_header();
}


# Normalize the request header on the client side - not finished yet!

sub normalized_request_url {
    my $self = shift;
    my $req = shift;
    
    my ($proto) = $req->protocol =~ /([a-zA-Z]+)/;
    $proto = lc( $proto);
    my $host = $req->headers->{host};
    my $path = $req->uri->path;
    if (( $proto eq "https") && ($host =~ /:443$/)) {
	$host =~ s/:443$//;
    } elsif (( $proto eq "http") && ($host =~ /:80$/)) {
	$host =~ s/:80$//;
    }
    return( sprintf( '%s://%s%s', $proto, $host, $path));
    
}


sub new_consumer {
    my $self = shift @_;
    my $ad = Bio::KBase::AuthDirectory->new();

    unless ( $self->{logged_in}) {
	    carp("No user currently logged in");
    	return;
    }
    my $oauth = $ad->new_consumer( $self->{user}->{user_id});
    return $oauth;
}

sub logout {
    my $self = shift @_;
    
    if ( $self->{logged_in} ) {
	$self->{user} = Bio::KBase::AuthUser->new();
	$self->{logged_in} = 0;
	$self->{oauth_cred} = {};
	return(1);
    } else {
	$self->{error_message} = "Not logged in";
	return(0);
    }

}

1;

__END__

=pod

=head1 Bio::KBase::AuthClient

   Client libraries that handle KBase authentication.

=head2 Examples:

=over

=item Conventional OAuth usage with Authorization header in http header:

    my $ua = LWP::UserAgent->new();
    my $req = HTTP::Request->new( GET => $server. "someurl" );

    # Create a KBase client and attach the authorization headers to the
    # request object. Use a "key" and "secret" as the secret
    my $ac = Bio::KBase::AuthClient->new(consumer_key => 'key', consumer_secret => 'secret');
    unless ($ac->{logged_in}) {
        die "Client: Failed to login with credentials!";
    }
    unless ($ac->sign_request( $req)) {
        die "Client: Failed to sign request";
    }
    my $res = $ua->request( $req);
    print $res->content

=item Embedding a non-standard OAuth token within JSON-RPC message body:

    # The arguments to the method call
    #
    my @args = ("arg1", "arg2");

    my $wrapped_params = {
        args => \@args,
    };

    #
    # The JSONRPC protocol data.
    #
    my $jsonrpc_params = {
        method => "module.server_call",
        params => [$wrapped_params],
    };

    # Use the oauth libraries to create an oauth token using "jsonrpc" as
    # the method, and a digest hash of rpc call parameters as the 'url'
    # this construction isn't recognized anywhere outside of KBase
    # On the server side, to validate the request, you would extract
    # all the components and compute the md5_base64 hash of the
    # contents of $json_call, and then make a call like this
    # $as = Bio::KBase::AuthServer
    # $inf{request_method} = "jsonrpc";
    # $inf{request_url} = $param_hash
    # if ( $as->validate_auth_header( $token, %inf)) {
    #         good stuff
    # } else {
    #         bad stuff
    # }
    my $json_call = to_json( $jsonrpc_params);
    my $param_hash = md5_base64( $json_call);

    my $token = $ac->auth_token( request_method => 'jsonrpc',
                                 request_url => $param_hash );
    my $wrapped = { params => [$json_call, $token],
                    version => 1.1,
                    method => "module.method_name" };

    $req->content( to_json( $wrapped));

    # Sign the http request for oauth
    unless ($ac->sign_request( $req)) {
        die "Client: Failed to sign request";
    }
     my $res = $ua->request( $req);
    printf "Client: Recieved a response: %s\n", $res->content;

=back

=head2 Environment

   User home directories can contain $auth_rc, which is a JSON formatted file with declarations for authentication information (similar to a ~/.netrc file)
   It should be in the following format:

{ "oauth_key":"consumer_key_blahblah",
  "oauth_token":"token_blah_blah",
  "oauth_secret":"consumer_secret_blahblah"
 }

=head2 Instance Variables

=over

=item B<user> (Bio::KBase::AuthUser)

Contains information about the user using the client. Also the full set of oauth credentials available for this user

=item B<oauth_cred> (hash)

Contains the hashref to specific oauth credential used for authentication. It is a hash of the same structure as the oauth_creds entries in the Bio::KBase::AuthUser

=item B<logged_in> (boolean)

Did login() successfully return? If this is true then the entry in the user attribute is good.

=item B<error_message> (string)

Most recent error msg from call to instance method.

=back

=head2 Methods

=over

=item B<new>([consumer_key=>key, consumer_secret=>secret])

returns Bio::KBase::AuthClient

Class constructor. Create and return a new client authentication object. Optionally takes arguments that are used for a call to the login() method. By default will check ~/.kbase-auth file for declarations for the consumer_key and consumer_secret, and if found, will pull those in and perform a login(). Environment variables are also an option and should be discussed.

=item B<login>( [consumer_key=>key, consumer_secret=>secret] |
[user_id=>”someuserid”,[password=>’somepassword’] |
[conversation_callback => ptr_conversation_function] |
[return_url = async_return_url])>

returns boolean for login success/fail.

If no parameters are given then consumer (key,secret) will be populated automatically from ~/.kbase-auth. Environment variables are also an option.

When this is called, the client will attempt to connect to the back end server to validate the credentials provided.
The most common use case will be to pull the consumer_key and consumer_secret from the environment. You can also specify the user_id and password for authentication - this is only recommended for bootstrapping the use of consumer (key,secret).

If the authentication is a little more complicated there are 2 options
  - define a function that handles the login interaction (same idea as the PAM conversation function).
  - if we’re in a web app that needs oauth authentication, then the client browser will need to be redirected back and forth. A return url where control will pass once authentication has completed needs to be provided ( see this diagram for an example). If the return_url is provided, this function will not return.


=item B<sign_request>( HTTPRequest request_object,[Bio::KBase::AuthUser user])

returns boolean

Called to sign a http request object before submitting it. Will push authentication/authorization messages into the HTTP request headers for authentication on the server side. With OAuth 1.0(a) this will be one set of headers, and with OAuth 2.0 it should be a smaller, simpler set of headers
   This method must be called on a request object to “sign” the request header so that the server side can authenticate the request.
   Note that different authentication methods have different requirements for a request:
   1) username/password requires SSL/TLS for obvious reasons
   2) oauth1 uses shared secrets and cryptographic hashes, so the request can be passed in the clear
   3) oauth2 using MAC tokens use a shared secret, so the request can be in cleartext
   4) oauth2 using Bearer tokens uses a text string as a combination username/password, so it must be over SSL/TLS
   If the transport protocol violates the requirements of the authentication method, sign_request() will return false and not encode any information in the request header.
   We can simplify things if we simply settle on options 2 and 3, and rule out options 1 and 4. It is also possible to finesse #1 into a cleartext protocol as well. But #4 (oauth2 bearer tokens) *must* be SSL/TLS. My recommendation is to disallow #4 so that we do not have to require SSL/TLS.

=item B<auth_token>( string URL,[Bio::KBase::AuthUser user]) **not yet implemented** (user consumer key/secret for now)

returns string

Returns a base64 encoded authentication token (tentatively based on the XOauth SASL token) that can be used for a single session within a non-HTTP protocol. The URL passed in is used to identify the resource being accessed, and is used in the computation of the hash signature. The url passed to Bio::KBase::AuthServer::validate_auth_token() on the other end of the exchange must be identical. Authentication tokens are also timestamped and intended for a single use. The token is generated from the consumer key and secret, and should not be stored across sessions for re-use (at the very least, it should timeout even if token replay safeguards fail).

=item B<new_consumer()> returns hash { consumer_key => key, consumer_secret => secret}

This function requests a consumer (key,secret) pair from the user directory that can be used for subsequent authentication. The (key,secret) should be stored in the environment. Note that the key/secret are associated with the account when you generate it - please do not overuse and cause a proliferation of key/secret pairs.

=item B<logout>([return_url = async_return_url])

returns boolean

Wipe out the auth info, and perform related logout functions. If we are being called in a web app, provide an asynchronous call back URL that the client browser will be redirected to after logout is called - execution will not return if return_url is defined.


=back

=cut
