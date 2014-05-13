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

	!system("curl $default_shock") or die "appears shock is unavailable at $default_shock";
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

The new_handle function returns a Handle object with a url and a
node id. The new_handle function invokes the localize_handle
method first to set the url and then invokes the initialize_handle
function to get an ID.

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
           created. This function should not be called directly.

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

The initialize_handle returns a Handle object with an ID. This
function should not be called directly

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

	my $auth_header;
	$auth_header = "-H 'Authorization: OAuth " . $ctx->{token} . "'" if $ctx->{token};

        my $cmd = "curl -s $auth_header -X POST $default_shock/node";
	DEBUG $cmd;
        my $json_node = capture($cmd);
        my $ref = decode_json $json_node;

        $h2->{id} = $ref->{data}->{id} or die "could not find node id in $json_node";

	$self->persist_handle( $h2 );

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




=head2 persist_handle

  $obj->persist_handle($h)

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

The persist_handle writes the handle to a persistent store
that can be later retrieved using the list_handles
function.

=back

=cut

sub persist_handle
{
    my $self = shift;
    my($h) = @_;

    my @_bad_arguments;
    (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h\" (value was \"$h\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to persist_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'persist_handle');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN persist_handle

	my (@fields, @values);
        foreach my $field (keys %$h) {
                if(defined $h->{$field}) {
                        push @fields, $field;
                        push @values, $self->{get_dbh}->()->quote($h->{$field});
                }
        }

	push @fields, 'created_by';
	push @values, $self->{get_dbh}->()->quote($ctx->{user_id});

        my $sql = " INSERT INTO Handle ";
        $sql   .= " (" . join( ", ", @fields) .  ") ";
        $sql   .= " values ";
        $sql   .= " (" . join( ", ", @values) .  ") ";


	my @pairs = ();
	foreach my $field (keys %$h) {
		push @pairs, "$field=" . $self->{get_dbh}->()->quote($h->{$field});
	}
	$sql  .= "ON DUPLICATE KEY UPDATE ";
	$sql  .= join(", ", @pairs);


	DEBUG $sql;
        my $sth = $self->{get_dbh}->()->prepare($sql)
                or die "could not prepare $sql, $DBI::errstr";
        $sth->execute()
                or die "could not execute $sql, $DBI::errstr";


    #END persist_handle
    return();
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

The upload and download functions  provide an empty
implementation that must be provided in a client. If a concrete
implementation is not provided an error is thrown. These are
the equivelant of abstract methods, with runtime rather than
compile time inforcement.
        
[client_implemented]

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
	die "upload cannot be called on AbstractHandle";
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

The upload and download functions  provide an empty
implementation that must be provided in a client. If a concrete
implementation is not provided an error is thrown. These are
the equivelant of abstract methods, with runtime rather than
compile time inforcement.

[client_implemented]

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
	die "download called on AbstractHandle";
    #END download
    return();
}




=head2 upload_metadata

  $obj->upload_metadata($h, $infile)

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

The upload_metadata function uploads metadata to an existing
handle. This means that the data that the handle represents
has already been uploaded. Uploading meta data before the data
has been uploaded is not currently supported.

[client_implemented]

=back

=cut

sub upload_metadata
{
    my $self = shift;
    my($h, $infile) = @_;

    my @_bad_arguments;
    (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h\" (value was \"$h\")");
    (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument \"infile\" (value was \"$infile\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to upload_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'upload_metadata');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN upload_metadata
	die "upload_metadata should not be called on AbstractHandle";
    #END upload_metadata
    return();
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

The download_metadata function downloads metadata associated
with the data handle and writes it to a file.

[client_implemented]

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
	die "Cannot call download_metadata on AbstractHandle";
    #END download_metadata
    return();
}




=head2 list_handles

  $l = $obj->list_handles()

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

The list function returns the set of handles that were
created by the user.

=back

=cut

sub list_handles
{
    my $self = shift;

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    my($l);
    #BEGIN list_handles

	my $user = 'NULL';
	$user = $ctx->{user_id} if $ctx->{user_id}; 
	DEBUG Dumper $ctx;
	$user = $self->{get_dbh}->()->quote($user);

	my $sql  = "SELECT * FROM Handle WHERE created_by = $user";
	if ( $user eq "'NULL'" ) {
		$sql = "SELECT * FROM Handle WHERE created_by is NULL";
	}
        DEBUG $sql;

        my $sth = $self->{get_dbh}->()->prepare($sql)
                or die "could not prepare $sql, $DBI::errstr";
        $sth->execute()
                or die "could not execute $sql, $DBI::errstr";

	$l = $sth->fetchall_arrayref();

    #END list_handles
    my @_bad_returns;
    (ref($l) eq 'ARRAY') or push(@_bad_returns, "Invalid type for return variable \"l\" (value was \"$l\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to list_handles:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'list_handles');
    }
    return($l);
}




=head2 delete_handles

  $obj->delete_handles($l)

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

The delete_handles function takes a list of handles
and deletes them on the handle service server.

=back

=cut

sub delete_handles
{
    my $self = shift;
    my($l) = @_;

    my @_bad_arguments;
    (ref($l) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument \"l\" (value was \"$l\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to delete_handles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'delete_handles');
    }

    my $ctx = $Bio::KBase::AbstractHandle::Service::CallContext;
    #BEGIN delete_handles
    #END delete_handles
    return();
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
