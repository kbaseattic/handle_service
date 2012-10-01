package AuthUtil;
use lib qw(/Users/brettin/local/dev/auth/Bio-KBase-Auth/lib);
use Bio::KBase::AuthClient;
@ISA = qw(Exporter);
@EXPORT = qw(oauth_token); 

=head1 Description

This library contains a small set of functions that help with using the
Bio::Kbase::AuthClient module.

=head1 Synopsis

# reads from ~./.auth-kbase
$token = oauth_token(request_url => $base_url)

# uses method params
$token = oauth_token(request_url => $base_url, consumer_key => "key1", consumer_secret=>"secret1");

# use basic authentication, consumer_key becomes $user and consumer_secret becomes $password
$token = oauth_token(consumer_key => "key1', consumer_secret=>"secret1", auth_method => "basic");

=cut

# usage:
# oauth_token(request_url => $base_url)
# oauth_token(request_url => $base_url, consumer_key => "key1", consumer_secret=>"secret1")
sub oauth_token {

  my %params = @_;
  my $ac;
  my $base_url = $params{request_url};

  if (defined $params->{consumer_key} and defined $params->{consumer_secret}) {
    $ac = Bio::KBase::AuthClient->new($params);
  }
  else {
    # assumes your ~/.kbase-auth file is in place
    $ac = Bio::KBase::AuthClient->new();
  }
  
  die "do some error handling" unless defined $ac or $ac->error_message;
  my $oauth_token = $ac->auth_token(request_method => 'GET',
				    request_url => $base_url );
  return $oauth_token;
}




1;
