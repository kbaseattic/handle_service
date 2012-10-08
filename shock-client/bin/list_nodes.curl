
use lib "$ENV{HOME}/local/dev/shock/shock-client/lib";
use Bio::KBase::AuthToken;
use Getopt::Long;

# parse and validate command line params
GetOptions (
	'u=s'    => \$user,
	'p=s'    => \$password,
	'url=s'  => \$base_url,
	'skip=i'  => \$skip,
	'limit=i' => \$limit,
	'query=s' => \$query,
);
usage() unless $base_url;

# get an OAuth token
my $auth_token = Bio::KBase::AuthToken->new(user_id => $user,
					    password => $password);

# build the command
$cmd  = " curl -s -X GET ";
unless ($auth_token->token() ) {
  print STDERR "could not get kbase auth token, reverting to basic auth\n";
  print STDERR $auth_token->error_message();
  print STDERR "will try without authorization\n";
}
else {
  $cmd .= " --header \"Authorization: OAuth " . $auth_token->token() . '"';
}
$cmd .= " http://$base_url/node?";
$cmd .= "skip=$skip\&" 				if (defined $skip);
$cmd .= "limit=$limit\&" 			if (defined $limit);
$cmd .= "query&$query" 				if (defined $query);
$cmd =~ s/[\&\?]$//;

# run the command
print STDERR "command: $cmd\n";
system ($cmd);

sub usage {
print<<END;
GetOptions (
	'u=s'     => \$user,
	'p=s'     => \$password,
	'url=s'   => \$base_url,
	'skip=i'  => \$skip,
	'limit=i' => \$limit,
	'query=s' => \query,
);

query must be in the form key=value where key is the name of a field in the
attributes and value is the value you are searching for.


by adding skip you get the nodes starting at $skip+1

by adding limit you get a maximum of $limit nodes returned


END
exit;
}
