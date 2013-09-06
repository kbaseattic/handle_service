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
our $client_cfg;

if (defined $ENV{KB_DEPLOYMENT_CONFIG} && -e $ENV{KB_DEPLOYMENT_CONFIG}) {
    $cfg = new Config::Simple($ENV{KB_DEPLOYMENT_CONFIG}) or
	die "could not construct new Config::Simple object";
    $default_shock = $cfg->param('data_store_interface.default-shock-server');
    $client_cfg = $cfg->param('data_store_interface.shock-client-config');
    INFO "$$ reading config from $ENV{KB_DEPLOYMENT_CONFIG}";
    INFO "$$ using $default_shock as the default shock server";
    INFO "$$ using $client_cfg as the shock-client config";
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
	$self->{registry} = {};
    #END_CONSTRUCTOR

    if ($self->can('_init_instance'))
    {
	$self->_init_instance();
    }
    return $self;
}

=head1 METHODS



=head2 new_handle

  $h = $obj->new_handle($service_name)

=over 4

=item Parameter and return types

=begin html

<pre>
$service_name is a string
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string

</pre>

=end html

=begin text

$service_name is a string
$h is a Handle
Handle is a reference to a hash where the following keys are defined:
	file_name has a value which is a string
	id has a value which is a string
	type has a value which is a string
	url has a value which is a string


=end text



=item Description

new_handle returns a Handle object with a url and a node id

=back

=cut

sub new_handle
{
    my $self = shift;
    my($service_name) = @_;

    my @_bad_arguments;
    (!ref($service_name)) or push(@_bad_arguments, "Invalid type for argument \"service_name\" (value was \"$service_name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to new_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'new_handle');
    }

    my $ctx = $Bio::KBase::DataStoreInterface::Service::CallContext;
    my($h);
    #BEGIN new_handle

        # look to see if a shock server near the service is available
        # otherwise, use the general kbase shock server
        $h->{file_name} = undef;
        $h->{id} = undef;
	($h->{url}, $h->{type}) = locate($self, $service_name);
	$h = initialize_handle($self, $h);
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




=head2 locate

  $url, $type = $obj->locate($service_name)

=over 4

=item Parameter and return types

=begin html

<pre>
$service_name is a string
$url is a string
$type is a string

</pre>

=end html

=begin text

$service_name is a string
$url is a string
$type is a string


=end text



=item Description

locate returns a url of a shock server near a service

=back

=cut

sub locate
{
    my $self = shift;
    my($service_name) = @_;

    my @_bad_arguments;
    (!ref($service_name)) or push(@_bad_arguments, "Invalid type for argument \"service_name\" (value was \"$service_name\")");
    if (@_bad_arguments) {
	my $msg = "Invalid arguments passed to locate:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'locate');
    }

    my $ctx = $Bio::KBase::DataStoreInterface::Service::CallContext;
    my($url, $type);
    #BEGIN locate
        my $registry = $self->{registry};
        if (exists $registry->{$service_name}) {
                $type = $registry->{$service_name}->{type};
                $url = $registry->{$service_name}->{url};
        }
        else {
                $type = 'shock';
                $url = $default_shock;
        }
    #END locate
    my @_bad_returns;
    (!ref($url)) or push(@_bad_returns, "Invalid type for return variable \"url\" (value was \"$url\")");
    (!ref($type)) or push(@_bad_returns, "Invalid type for return variable \"type\" (value was \"$type\")");
    if (@_bad_returns) {
	my $msg = "Invalid returns passed to locate:\n" . join("", map { "\t$_\n" } @_bad_returns);
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
							       method_name => 'locate');
    }
    return($url, $type);
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

        my $cmd = "shock-client";
        my $json_node = capture("shock-client", "create", "-conf=$client_cfg");
        my $ref = decode_json $json_node;

        $h2->{id} = $ref->{id} or die "could not find node id in $json_node";

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
shock the value of type is “shock”. In the future 
these values should enumerated. The value of url is
the http address of the shock server, including the
protocol (http or https) and if necessary the port.


=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
file_name has a value which is a string
id has a value which is a string
type has a value which is a string
url has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
file_name has a value which is a string
id has a value which is a string
type has a value which is a string
url has a value which is a string


=end text

=back



=cut

1;
