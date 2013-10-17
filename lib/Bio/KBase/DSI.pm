package Bio::KBase::DSI;
use strict;
use Bio::KBase::DataStoreInterface::Client;
use LWP::UserAgent;
use JSON;
use Data::Dumper;

=head1 Methods

=over

=item C<new>

This creates a new data store interface object. It takes as an optional parameter a url on which the data store interface is running in the unlikely event you want to connect to a non-standard data store interface server.

=cut

sub new {
	my $class = shift;
	my $url   =  @_ ? shift : undef;

	my $self  = bless {}, $class;

	# if a url is passed in, this is the url to instanciate
	# a DataStoreInterface client object. It reflects the
	# server that the DataStoreInterfaceImpl is running on.

	$self->{url} = $url;
	$self->{ua} = LWP::UserAgent->new;
	$self->{ua}->env_proxy;
	
	if( defined $self->{url} ) {
	  print "creating client with endpoint: $self->{url}\n";
	  $self->{dsi} =
	    Bio::KBase::DataStoreInterface::Client->new($url);
	}
	else {
	  print "creating client with default endpoint\n";
	  $self->{dsi} =
	    Bio::KBase::DataStoreInterface::Client->new();
	}

	return $self;
}

=over

=item C<upload>

Uploads the file. Calls the DataStoreInterface new_handle method, then uses the node id and the url in the new handle to upload the file.

=back

=cut

sub upload {
	my $self = shift;

	# implement here
	my $infile = shift or die "infle not passed";
	-e $infile         or die "$infile does not exist";

	my $handle;
	if ( defined $self->{url} ) {
	  $handle =
	    $self->new_handle( $self->{url} )
		or die "could not get new handle";
	}
	else {
	  $handle =
	    $self->new_handle()
		or die "could not get new handle";
	}
	

	# not implemented yet
	warn "WARNING: upload not implemented";
}

=over

=item C<download>

Downloads the file associated with the handle.

=back

=cut

sub download {
	my $self = shift;

	# implementation here
	my $handle = shift;
	my $outfile = shift;

	ref $handle eq "HASH" or die "handle not a hash ref";
	$handle->{id}         or die "no id in handle";
	$handle->{url}        or die "no url in handle";
	defined $outfile      or die "outfile not defined";

	# not implemented yet
	warn "WARNING: download not implemented";
}

sub new_handle {
        my $self = shift;	
        $self->{dsi}->new_handle(@_);
}

sub locate {
	my $self = shift;
	$self->{dsi}->new()->locate(@_);
}

sub initialize_handle {
	my $self = shift;
	$self->{dsi}->initialize_handle(@_);
}

=head1 Authors

Tom Brettin

=cut

1;
