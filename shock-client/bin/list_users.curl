
use strict;
use vars qw($user $password $base_url);
use Getopt::Long;
use lib ("$ENV{HOME}/local/dev/shock/shock-client/lib");
use Bio::KBase::AuthToken;

# parse and validate command line params
GetOptions (
			'u=s'      => \$user,
			'p=s'      => \$password,
			'url=s'    => \$base_url,
);
usage("url not specified")            unless $base_url;
usage("user not specified")           unless $user;
usage("password not specified")       unless $password;

# get an OAuth token
my $auth_token = Bio::KBase::AuthToken->new(user_id => $user,
					    password => $password);

# build the command
my $cmd  = " curl -s -X GET ";
unless ($auth_token->token() ) {
  print STDERR "could not get kbase auth token, reverting to basic auth\n";
  print STDERR $auth_token->error_message();
  print STDERR "will try without authorization\n";
}
else {
  $cmd .= " --header \"Authorization: OAuth " . $auth_token->token() . '"';
}
$cmd .= " http://$base_url/user";
$cmd =~ s/[\&\?]$//;

# run the command
print STDERR "command: $cmd\n";
system ($cmd);

sub usage {
print @_, "\n" if @_;

print<<END;
GetOptions (
	'u=s'      => \$user,
	'p=s'      => \$password,
	'url=s'    => \$base_url,
	'id=s'     => \$id,
);


NOTE: not sure id is required.


END
exit;
}
