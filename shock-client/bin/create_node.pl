
use strict;
use vars qw($user $password $base_url $attr_file $data_file);
use lib "$ENV{HOME}/local/dev/shock/shock-client/lib";
use Bio::KBase::AuthToken;
use Getopt::Long;

# parse and validate command line params
GetOptions (
	'u=s'    => \$user,
	'p=s'    => \$password,
	'url=s'  => \$base_url,
	'attr=s' => \$attr_file,
	'data=s' => \$data_file,
);
usage() unless $base_url;

# get OAuth token
my $auth_token = Bio::KBase::AuthToken->new(user_id => $user,
					    password => $password);

# build the command
my $cmd  = " curl -s -X POST ";
unless ($auth_token->token() ) {
  print STDERR "could not get kbase auth token, reverting to basic auth\n";
  print STDERR $auth_token->error_message();
  print STDERR "will try without authorization\n";
}
else {
  $cmd .= " --header \"Authorization: OAuth " . $auth_token->token() . '"';
}
$cmd .= " -F \"attrubutes=\@$attr_file\" " if ($attr_file);
$cmd .= " -F \"file=\@$data_file\" "       if ($data_file);
$cmd .= " http://$base_url/node?";
$cmd =~ s/[\&\?]$//;

# run the command
print STDERR "running command: $cmd\n";
system ($cmd);

sub usage {
print<<END;
GetOptions (
	'u=s'    => \$user,
	'p=s'    => \$password,
	'url=s'  => \$base_url,
	'attr=s' => \$attr_file,
	'data=s' => \$data_file,
);
END
    exit;
}
