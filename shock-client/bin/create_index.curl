
use strict;
use vars qw($user $password $base_url $id $index);
use Getopt::Long;
use lib ("$ENV{HOME}/local/dev/shock/shock-client/lib");
use Bio::KBase::AuthToken;

# parse and validate command line params
GetOptions (
			'u=s'      => \$user,
			'p=s'      => \$password,
			'url=s'    => \$base_url,
			'id=s'     => \$id,
			'index=s'  => \$index,
);
usage("url or id not specified") unless $base_url && $id;
usage("index not specified")     unless $index;

# get an oauth token
my $auth_token = Bio::KBase::AuthToken->new(user_id => $user,
					    password => $password);

# build the command
my $cmd  = " curl -s -X PUT ";
unless ($auth_token->token() ) {
  print STDERR "could not get kbase auth token, reverting to basic auth\n";
  print STDERR $auth_token->error_message();
  print STDERR "will try without authorization\n";
}
else {
  $cmd .= " --header \"Authorization: OAuth " . $auth_token->token() . '"';
}
$cmd .= " http://$base_url/node/$id?";
$cmd .= "&index=$index&";
$cmd =~ s/[\&\?]$//;

# run the command
print STDERR "command: $cmd\n";
system ($cmd);

sub usage {
print @_, "\n" if @_;

print<<END;
GetOptions (
	'u=s'      => \$user,		# optional, if provided consumer_key => $user
	'p=s'      => \$password,	# optional, if provided consumer_secret => $password
	'url=s'    => \$base_url,	# required
	'id=s'     => \$id,		# required
	'index=s'  => \$index,		# requiurd
);


Modify:

    - Once the file or attributes of a node are set they are immutiable.
    - Accepts multipart/form-data encoded
    - To set attributes include file field named "attributes" containing a json
      file of attributes 
    - To set file include file field named "file" containing
      any file


END
exit;
}
