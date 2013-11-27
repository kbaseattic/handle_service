package Bio::KBase::AbstractHandle::AbstractHandleImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

AbstractHandle

=head1 DESCRIPTION

The AbstractHandle module provides a programmatic
access to a remote file store.

=cut

#BEGIN_HEADER
use DBI;
use Data::Dumper;
use Config::Simple;
use IPC::System::Simple qw(capture);
use JSON;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($DEBUG);

our $cfg = {};
our ($default_shock, $mysql_user, $mysql_pass, $data_source);

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
        die "could not construct new Config::Simple object";
    $default_shock = $cfg->param('handle_service.default-shock-server');
    $mysql_user    = $cfg->param('handle_service.mysql-user');
    $mysql_pass    = $cfg->param('handle_service.mysql-pass');
    $data_source   = $cfg->param('handle_service.data-source');
    INFO "$$ reading config from $ENV{KB_DEPLOYMENT_CONFIG}";
    INFO "$$ using $default_shock as the default shock server";
}
else {
    die "could not find KB_DEPLOYMENT_CONFIG";
}
#END_HEADER

sub new
{
    my($class, @args) = @_;
    my $self = {
    };
    bless $self, $class;
    #BEGIN_CONSTRUCTOR

        # TODO need to solve the registry thing
        $self->{registry} = {};
        system("curl -h > /dev/null 2>&1") == 0  or
            die "curl not found, maybe you need to install it";

	my @connection = ($data_source, $mysql_user, $mysql_pass, {});
	$self->{dbh} = DBI->connect(@connection);
	# need some assurance that the handle is still connected. not 
	# totally sure this will work. needs to be tested.
	$self->{get_dbh} = sub {
		unless ($self->{dbh}->ping) {
			$self->{dbh} = DBI->connect(@connection); 
		} 
		return $self->{dbh};
	};


    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 new_handle

  $h = $obj->new_handle()

=over 4

=item Parameter and return types

=begin html

<pre>
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

new_handle returns a Handle object with a url and a node id

=back

=cut

sub new_handle
{
    my $self = shift;

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($h);
    #BEGIN new_handle

        $h->{file_name} = undef;
        $h->{id} = undef;
        $h = $self->localize_handle($h, ref $self);
        $h = $self->initialize_handle($h);

    #END new_handle
    my @_bad_returns;
    (ref($h) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"h\" (value was \"$h\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to new_handle:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'new_handle');
    }
    return($h);
}




=head2 localize_handle

  $h2 = $obj->localize_handle($h1, $service_name)

=over 4

=item Parameter and return types

=begin html

<pre>
$h1 is a Handle
$service_name is a string
$h2 is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h1 is a Handle
$service_name is a string
$h2 is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

The localize_handle function attempts to locate a shock server near
the service. The localize_handle function must be called before the
           Handle is initialized becuase when the handle is initialized, it is
           given a node id that maps to the shock server where the node was
           created.

=back

=cut

sub localize_handle
{
    my $self = shift;
    my($h1, $service_name) = @_;

    my @_bad_arguments;
    (ref($h1) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h1\" (value was \"$h1\")");
    (!ref($service_name)) or push(@_bad_arguments, "Invalid type for argument \"service_name\" (value was \"$service_name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to localize_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'localize_handle');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($h2);
    #BEGIN localize_handle

        $h2 = $h1;
        my ($url, $type);
        my $registry = $self->{registry};
        if (exists $registry->{$service_name}) {
                $type = $registry->{$service_name}->{type};
                $url = $registry->{$service_name}->{url};
        }
        else {
                $type = 'shock';
                $url = $default_shock;
        }
        unless (defined $h2->{url}) {
                $h2->{url} = $url;
                $h2->{type} = $type;
        }

    #END localize_handle
    my @_bad_returns;
    (ref($h2) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"h2\" (value was \"$h2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to localize_handle:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'localize_handle');
    }
    return($h2);
}




=head2 initialize_handle

  $h2 = $obj->initialize_handle($h1)

=over 4

=item Parameter and return types

=begin html

<pre>
$h1 is a Handle
$h2 is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h1 is a Handle
$h2 is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

initialize_handle returns a Handle object with an ID.

=back

=cut

sub initialize_handle
{
    my $self = shift;
    my($h1) = @_;

    my @_bad_arguments;
    (ref($h1) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h1\" (value was \"$h1\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to initialize_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'initialize_handle');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($h2);
    #BEGIN initialize_handle

        $h2 = $h1;

        my $cmd = "curl -s -H \'Authorization: OAuth " . $ctx->{token} . "\' -X POST $default_shock/node";
	DEBUG $cmd;
        my $json_node = capture($cmd);
        my $ref = decode_json $json_node;

        $h2->{id} = $ref->{data}->{id} or die "could not find node id in $json_node";

	my (@fields, @values);
	foreach my $field (keys %$h2) {
		if(defined $h2->{$field}) {
			push @fields, $field;
			push @values, $self->{dbh}->quote($h2->{$field});
		}
	}	

	my $sql = " INSERT INTO Handle ";
	$sql   .= " (", join @fields, ",", ") ";
	$sql   .= " values ";
	$sql   .= " (", join @values, ",", ") ";

	$self->{dbh}->prepare($sql)
		or die "could not prepare sql, $DBI::errstr";

    #END initialize_handle
    my @_bad_returns;
    (ref($h2) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"h2\" (value was \"$h2\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to initialize_handle:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'initialize_handle');
    }
    return($h2);
}




=head2 upload

  $h = $obj->upload($infile)

=over 4

=item Parameter and return types

=begin html

<pre>
$infile is a string
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$infile is a string
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

These provides an empty implementation so that if a concrete
implementation is not provided an error is thrown. These are
the equivelant of abstract methods, with runtime rather than
compile time inforcement.

=back

=cut

sub upload
{
    my $self = shift;
    my($infile) = @_;

    my @_bad_arguments;
    (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument \"infile\" (value was \"$infile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to upload:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'upload');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($h);
    #BEGIN upload
    #END upload
    my @_bad_returns;
    (ref($h) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"h\" (value was \"$h\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to upload:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'upload');
    }
    return($h);
}




=head2 download

  $obj->download($h, $outfile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is a Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h is a Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description



=back

=cut

sub download
{
    my $self = shift;
    my($h, $outfile) = @_;

    my @_bad_arguments;
    (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h\" (value was \"$h\")");
    (!ref($outfile)) or push(@_bad_arguments, "Invalid type for argument \"outfile\" (value was \"$outfile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to download:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'download');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN download
    #END download
    return();
}




=head2 upload_metadata

  $h = $obj->upload_metadata($infile)

=over 4

=item Parameter and return types

=begin html

<pre>
$infile is a string
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$infile is a string
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

Not sure if these should be abstract or concrete. If concete
then we don't have to hand roll an implemetation for the four
different supported languages. The cost is an extra network
hop. For now, I choose the extra network hop over implementing
the same method by hand in for different languages. I belive it
to be a safe assumption that the metadata won't exceed several
megabytes in size.

=back

=cut

sub upload_metadata
{
    my $self = shift;
    my($infile) = @_;

    my @_bad_arguments;
    (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument \"infile\" (value was \"$infile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to upload_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'upload_metadata');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($h);
    #BEGIN upload_metadata
    #END upload_metadata
    my @_bad_returns;
    (ref($h) eq 'HASH') or push(@_bad_returns, "Invalid type for return variable \"h\" (value was \"$h\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to upload_metadata:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'upload_metadata');
    }
    return($h);
}




=head2 download_metadata

  $obj->download_metadata($h, $outfile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is a Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h is a Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description



=back

=cut

sub download_metadata
{
    my $self = shift;
    my($h, $outfile) = @_;

    my @_bad_arguments;
    (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h\" (value was \"$h\")");
    (!ref($outfile)) or push(@_bad_arguments, "Invalid type for argument \"outfile\" (value was \"$outfile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to download_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'download_metadata');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN download_metadata
	my $id  = $h->{id} or die "no id in handle";
	my $url = $h->{url} or die "no url in handle";
	if($h->{type} eq "shock") {
		my $cmd = "curl -s -H \'Authorization: OAuth " . $ctx->{token} . "\' -o $outfile -X GET $default_shock/node/$id";
		INFO "cmd: $cmd";
		!system $cmd or die "could not execute curl in download_metadata";
	}
	else {
		die "invalid handle type: $h->{type}";
	}

    #END download_metadata
    return();
}




=head2 add_metadata

  $obj->add_metadata($h, $infile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is a Handle
$infile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h is a Handle
$infile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description



=back

=cut

sub add_metadata
{
    my $self = shift;
    my($h, $infile) = @_;

    my @_bad_arguments;
    (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h\" (value was \"$h\")");
    (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument \"infile\" (value was \"$infile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to add_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'add_metadata');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN add_metadata
	my $url = $h->{url} or die "no url in handle";
	my $id  = $h->{id} or die "no id in handle";
	my $type = $h->{type} or die "no type in handle";
	if ($type eq "shock") {
		my $cmd = "curl -s -H \'Authorization: OAuth " . $ctx->{token} . "\' -X PUT -F \'attributes=\@" . $infile . "\' $default_shock/node/$id";
		INFO "cmd: $cmd";
        	my $json_node = `$cmd`;
        	my $ref = decode_json $json_node;
		if ($ref->{error}) {
			ERROR "could not PUT metadata for id: $id";
			ERROR "error: $ref->{error}";
			ERROR "status: ref->{status}";
			die "failed to put metadata for id: $id";
		}
	}
	else {
		die "don't recognize type $type";
	}
    #END add_metadata
    return();
}




=head2 add_data

  $obj->add_data($h, $infile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is a Handle
$infile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$h is a Handle
$infile is a string
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description



=back

=cut

sub add_data
{
    my $self = shift;
    my($h, $infile) = @_;

    my @_bad_arguments;
    (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h\" (value was \"$h\")");
    (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument \"infile\" (value was \"$infile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to add_data:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'add_data');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN add_data
    #END add_data
    return();
}




=head2 list_all

  $l = $obj->list_all()

=over 4

=item Parameter and return types

=begin html

<pre>
$l is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$l is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

The list_all function returns a set of handles. If the user
is authenticated, it retuns the set of handles owned by the
user and those that are public or shared.

=back

=cut

sub list_all
{
    my $self = shift;

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($l);
    #BEGIN list_all
    #END list_all
    my @_bad_returns;
    (ref($l) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"l\" (value was \"$l\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_all:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_all');
    }
    return($l);
}




=head2 list_mine

  $l = $obj->list_mine()

=over 4

=item Parameter and return types

=begin html

<pre>
$l is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$l is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

The list function returns the set of handles that belong
to the user.

=back

=cut

sub list_mine
{
    my $self = shift;

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($l);
    #BEGIN list_mine
    #END list_mine
    my @_bad_returns;
    (ref($l) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"l\" (value was \"$l\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_mine:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_mine');
    }
    return($l);
}




=head2 list_ours

  $l = $obj->list_ours()

=over 4

=item Parameter and return types

=begin html

<pre>
$l is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string

</pre>

=end html

=begin text

$l is a reference to a list where each element is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string


=end text



=item Description

Just stubbing this one out for now. The idea here is that
ours is determined by way of user groups.

=back

=cut

sub list_ours
{
    my $self = shift;

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($l);
    #BEGIN list_ours
    #END list_ours
    my @_bad_returns;
    (ref($l) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"l\" (value was \"$l\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_ours:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_ours');
    }
    return($l);
}




=head2 version 

  $return = $obj->version()

=over 4

=item Parameter and return types

=begin html

<pre>
$return is a string
</pre>

=end html

=begin text

$return is a string

=end text

=item Description

Return the module version. This is a Semantic Versioning number.

=back

=cut

sub version {
    return $VERSION;
}

=head1 TYPES



=head2 Handle

=over 4



=item Description

Handle provides a unique reference that enables
access to the data files through functions
provided as part of the HandleService. In the case of using
shock, the id is the node id. In the case of using
shock the value of type is shock. In the future 
these values should enumerated. The value of url is
the http address of the shock server, including the
protocol (http or https) and if necessary the port.
The values of remote_md5 and remote_sha1 are those
computed on the file in the remote data store. These
can be used to verify uploads and downloads.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_name has a value which is a string
id has a value which is a string
type has a value which is a string
url has a value which is a string
remote_md5 has a value which is a string
remote_sha1 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_name has a value which is a string
id has a value which is a string
type has a value which is a string
url has a value which is a string
remote_md5 has a value which is a string
remote_sha1 has a value which is a string


=end text

=back



=cut

1;
