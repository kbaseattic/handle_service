package Bio::KBase::HandleService;
use strict;

use Bio::KBase::AbstractHandle::Client;
use Bio::KBase::AuthToken;

use LWP::UserAgent;
use HTTP::Request::Common; # qw($DYNAMIC_FILE_UPLOAD);

use JSON;
use Data::Dumper;
use File::Basename;

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
	# a AbstractHandle client object. It reflects the
	# server that the AbstractHandleImpl is running on.

	$self->{url} = $url;
	$self->{ua} = LWP::UserAgent->new;
	$self->{ua}->env_proxy;
	
	if( defined $self->{url} ) {
	  $self->{dsi} =
	    Bio::KBase::AbstractHandle::Client->new($url);
	}
	else {
	  # print "creating client with default endpoint\n";
	  $self->{dsi} =
	    Bio::KBase::AbstractHandle::Client->new();
	}

	return $self;
}

=over

=item C<upload>

Uploads the file. Calls the AbstractHandle new_handle method, then uses the node id and the url in the new handle to upload the file.

=back

=cut

sub upload {
	my $self = shift;

	# implement here
	my $infile = shift or die "infle not passed";
	-e $infile         or die "$infile does not exist";

	my $handle =
	  $self->new_handle()
	    or die "could not get new handle";

	my $tok = Bio::KBase::AuthToken->new();

	my $url = $handle->{url} . "/node/" . $handle->{id};
	my $auth_header;
	$auth_header = "-H 'Authorization: OAuth $tok->{token}'" if $tok->{token};
	my $cmd = "curl -s $auth_header -X PUT -F upload=\@$infile $url";

	my $json = `$cmd 2> /dev/null`;
	die "failed to run: $cmd\n$!" if $? == -1;

	my $ref = decode_json $json;
	my $remote_md5 =
	  $ref->{data}->{file}->{checksum}->{md5};
	my $remote_sha1 =
	  $ref->{data}->{file}->{checksum}->{sha1};
	
	die "looks like upload failed with command: $cmd\n" ,
	  "no md5 returned from remote server"
	    unless $remote_md5;


	$handle->{remote_md5} = $remote_md5;
	$handle->{remote_sha1} = $remote_sha1;
	$handle->{file_name} = basename ($infile);

	$self->persist_handle($handle);
	return $handle;
}

=over

=item C<download>

Downloads the file associated with the handle. The download method takes two
parameters. The first is the handle, the second is the name of the file to
put the downloaded data into.

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

	my($filename, $path) = fileparse($outfile);
	die "$path is not writable" unless -d $path && -w $path && -x $path;
	die "$outfile already exists" if -e $outfile;

	my $tok = Bio::KBase::AuthToken->new();

	my $url = $handle->{url} . "/node/" . $handle->{id};
	my @auth_header;
	@auth_header = ("-H", "Authorization: OAuth $tok->{token}")  if $tok->{token};

	my @cmd = ("curl", "-s", @auth_header, '-o', $outfile, '-X', 'GET', "$url/?download");
	my $rc = system(@cmd);

	die "failed to run: @cmd\n$!" if $rc != 0;

	return;
}

sub new_handle {
        my $self = shift;	
        $self->{dsi}->new_handle(@_);
}

sub localize_handle {
	my $self = shift;
	$self->{dsi}->localize_handle(@_);
}

sub initialize_handle {
	my $self = shift;
	$self->{dsi}->initialize_handle(@_);
}

sub persist_handle {
	my $self = shift;
	$self->{dsi}->persist_handle(@_);
}

sub upload_metadata {
	my $self = shift;
	my $handle = shift;
	my $infile = shift;

	die "first arg to upload_metatdata not a hash" unless ref $handle eq "HASH";
	die "second arg to upload_metadata not a file" unless -e $infile;

        my $id  = $handle->{id}  or die "no id in handle";
        my $url = $handle->{url} or die "no url in handle";

        my $tok = Bio::KBase::AuthToken->new();

        if($handle->{type} eq "shock") {
		my $url = $handle->{url} . "/node/" . $handle->{id};
		my $auth_header;
		$auth_header = "-H 'Authorization: OAuth $tok->{token}'"  if $tok->{token};
		my $cmd = "curl -s $auth_header -X PUT -F attributes=\@$infile $url > /dev/null 2>&1";
		!system $cmd or die "could not execute curl in upload_metadata\n$cmd";
        }
        else {
               die "invalid handle type: $handle->{type}";
        }
	return;
}

sub download_metadata {
        my $self = shift;

        # implementation here
        my $handle = shift;
        my $outfile = shift;

        ref $handle eq "HASH" or die "handle not a hash ref";
        $handle->{id}         or die "no id in handle";
        $handle->{url}        or die "no url in handle";
        defined $outfile      or die "outfile not defined";

        my($filename, $path) = fileparse($outfile);
        die "$path is not writable" unless -d $path && -w $path && -x $path;
        die "$outfile already exists" if -e $outfile;

        my $tok = Bio::KBase::AuthToken->new();

        my $url = $handle->{url} . "/node/" . $handle->{id};
        my $auth_header;
        $auth_header = "-H 'Authorization: OAuth $tok->{token}'"  if $tok->{token};
        my $cmd = "curl -s $auth_header -X GET $url";

        my $json = `$cmd 2> /dev/null`;
        die "failed to run: $cmd\n$!" if $? == -1;

	my $ref = decode_json($json);
	my $meta = encode_json $ref->{data}->{attributes};
	open my $f, ">$outfile";
	print $f $meta;
	close $f;

        return;
}

sub list_handles {
	my $self = shift;
	$self->{dsi}->list_handles(@_);
}

sub are_readable {
	my $self = shift;
	$self->{dsi}->are_readable(@_);
}

sub is_readable {
	my $self = shift;
	$self->{dsi}->is_readable(@_);
}

sub hids_to_handles {
	my $self = shift;
	$self->{dsi}->hids_to_handles(@_);
}

sub ids_to_handles {
	my $self = shift;
	$self->{dsi}->ids_to_handles(@_);
}
=head1 Authors

Tom Brettin

=cut

1;
