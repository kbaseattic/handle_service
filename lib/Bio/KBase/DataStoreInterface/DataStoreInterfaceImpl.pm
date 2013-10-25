package Bio::KBase::DataStoreInterface::DataStoreInterfaceImpl;
use strict;
use Bio::KBase::Exceptions;
# Use Semantic Versioning (2.0.0-rc.1)
# http://semver.org 
our $VERSION = "0.1.0";

=head1 NAME

DataStoreInterface

=head1 DESCRIPTION

The DataStoreInterface module provides a programmatic
access to a remote file store.

=cut

#BEGIN_HEADER
# read the config file into this package.
use Data::Dumper;
use Config::Simple;
use IPC::System::Simple qw(capture);
use JSON;
use Log::Log4perl qw(:easy);
Log::Log4perl->easy_init($INFO);

our $cfg = {};
our $default_shock;

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "could not construct new Config::Simple object";
    $default_shock = $cfg->param('data_store_interface.default-shock-server');
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
	# TODO need to solve this.
	$self->{registry} = {};
	system("curl -h > /dev/null 2>&1") == 0  or
		die "curl not found, maybe you need to install it";
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

    my $ctx = $Bio::KBase::DataStoreInterface::Service::CallContext;
    my($h);
    #BEGIN new_handle

        $h->{file_name} = undef;
        $h->{id} = undef;
        $h = $self->localize_handle(ref $self, $h);
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

  $h2 = $obj->localize_handle($service_name, $h1)

=over 4

=item Parameter and return types

=begin html

<pre>
$service_name is a string
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

$service_name is a string
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
    my($service_name, $h1) = @_;

    my @_bad_arguments;
    (!ref($service_name)) or push(@_bad_arguments, "Invalid type for argument \"service_name\" (value was \"$service_name\")");
    (ref($h1) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument \"h1\" (value was \"$h1\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to localize_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'localize_handle');
    }

    my $ctx = $Bio::KBase::DataStoreInterface::Service::CallContext;
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

    my $ctx = $Bio::KBase::DataStoreInterface::Service::CallContext;
    my($h2);
    #BEGIN initialize_handle

	$h2 = $h1;

	my $cmd = "curl -s -H \'Authorization: OAuth " . $ctx->{token} . "\' -X POST $default_shock/node";
	my $json_node = capture($cmd);
        my $ref = decode_json $json_node;

        $h2->{id} = $ref->{data}->{id} or die "could not find node id in $json_node";

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
provided as part of the DSI. In the case of using
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
