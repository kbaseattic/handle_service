package Bio::KBase::AbstractHandle::AbstractHandleClient;

use JSON::RPC::Client;
use POSIX;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;
my $get_time = sub { time, 0 };
eval {
    require Time::HiRes;
    $get_time = sub { Time::HiRes::gettimeofday() };
};

use Bio::KBase::AuthToken;

# Client version should match Impl version
# This is a Semantic Version number,
# http://semver.org
our $VERSION = "0.1.0";

=head1 NAME

AbstractHandleClient

=head1 DESCRIPTION


The AbstractHandle module provides a programmatic
access to a remote file store.


=cut

sub new
{
    my($class, $url, @args) = @_;
    
    if (!defined($url))
    {
	$url = 'http://localhost:7109';
    }

    my $self = {
	client => AbstractHandleClient::RpcClient->new,
	url => $url,
	headers => [],
    };

    chomp($self->{hostname} = `hostname`);
    $self->{hostname} ||= 'unknown-host';

    #
    # Set up for propagating KBRPC_TAG and KBRPC_METADATA environment variables through
    # to invoked services. If these values are not set, we create a new tag
    # and a metadata field with basic information about the invoking script.
    #
    if ($ENV{KBRPC_TAG})
    {
	$self->{kbrpc_tag} = $ENV{KBRPC_TAG};
    }
    else
    {
	my ($t, $us) = &$get_time();
	$us = sprintf("%06d", $us);
	my $ts = strftime("%Y-%m-%dT%H:%M:%S.${us}Z", gmtime $t);
	$self->{kbrpc_tag} = "C:$0:$self->{hostname}:$$:$ts";
    }
    push(@{$self->{headers}}, 'Kbrpc-Tag', $self->{kbrpc_tag});

    if ($ENV{KBRPC_METADATA})
    {
	$self->{kbrpc_metadata} = $ENV{KBRPC_METADATA};
	push(@{$self->{headers}}, 'Kbrpc-Metadata', $self->{kbrpc_metadata});
    }

    if ($ENV{KBRPC_ERROR_DEST})
    {
	$self->{kbrpc_error_dest} = $ENV{KBRPC_ERROR_DEST};
	push(@{$self->{headers}}, 'Kbrpc-Errordest', $self->{kbrpc_error_dest});
    }

    #
    # This module requires authentication.
    #
    # We create an auth token, passing through the arguments that we were (hopefully) given.

    {
	my %arg_hash2 = @args;
	if (exists $arg_hash2{"token"}) {
	    $self->{token} = $arg_hash2{"token"};
	} elsif (exists $arg_hash2{"user_id"}) {
	    my $token = Bio::KBase::AuthToken->new(@args);
	    if (!$token->error_message) {
	        $self->{token} = $token->token;
	    }
	}
	
	if (exists $self->{token})
	{
	    $self->{client}->{token} = $self->{token};
	}
    }

    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);
    bless $self, $class;
    #    $self->_validate_version();
    return $self;
}




=head2 new_handle

  $h = $obj->new_handle()

=over 4

=item Parameter and return types

=begin html

<pre>
$h is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 0)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function new_handle (received $n, expecting 0)");
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.new_handle",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'new_handle',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method new_handle",
					    status_line => $self->{client}->status_line,
					    method_name => 'new_handle',
				       );
    }
}
 


=head2 localize_handle

  $h2 = $obj->localize_handle($h1, $service_name)

=over 4

=item Parameter and return types

=begin html

<pre>
$h1 is an AbstractHandle.Handle
$service_name is a string
$h2 is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h1 is an AbstractHandle.Handle
$service_name is a string
$h2 is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


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
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function localize_handle (received $n, expecting 2)");
    }
    {
	my($h1, $service_name) = @args;

	my @_bad_arguments;
        (ref($h1) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"h1\" (value was \"$h1\")");
        (!ref($service_name)) or push(@_bad_arguments, "Invalid type for argument 2 \"service_name\" (value was \"$service_name\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to localize_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'localize_handle');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.localize_handle",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'localize_handle',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method localize_handle",
					    status_line => $self->{client}->status_line,
					    method_name => 'localize_handle',
				       );
    }
}
 


=head2 initialize_handle

  $h2 = $obj->initialize_handle($h1)

=over 4

=item Parameter and return types

=begin html

<pre>
$h1 is an AbstractHandle.Handle
$h2 is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h1 is an AbstractHandle.Handle
$h2 is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


=end text

=item Description

The initialize_handle returns a Handle object with an ID. This
function should not be called directly

=back

=cut

 sub initialize_handle
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function initialize_handle (received $n, expecting 1)");
    }
    {
	my($h1) = @args;

	my @_bad_arguments;
        (ref($h1) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"h1\" (value was \"$h1\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to initialize_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'initialize_handle');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.initialize_handle",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'initialize_handle',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method initialize_handle",
					    status_line => $self->{client}->status_line,
					    method_name => 'initialize_handle',
				       );
    }
}
 


=head2 persist_handle

  $hid = $obj->persist_handle($h)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is an AbstractHandle.Handle
$hid is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h is an AbstractHandle.Handle
$hid is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


=end text

=item Description

The persist_handle writes the handle to a persistent store
that can be later retrieved using the list_handles
function.

=back

=cut

 sub persist_handle
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function persist_handle (received $n, expecting 1)");
    }
    {
	my($h) = @args;

	my @_bad_arguments;
        (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"h\" (value was \"$h\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to persist_handle:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'persist_handle');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.persist_handle",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'persist_handle',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method persist_handle",
					    status_line => $self->{client}->status_line,
					    method_name => 'persist_handle',
				       );
    }
}
 


=head2 upload

  $h = $obj->upload($infile)

=over 4

=item Parameter and return types

=begin html

<pre>
$infile is a string
$h is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$infile is a string
$h is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function upload (received $n, expecting 1)");
    }
    {
	my($infile) = @args;

	my @_bad_arguments;
        (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument 1 \"infile\" (value was \"$infile\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to upload:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'upload');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.upload",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'upload',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method upload",
					    status_line => $self->{client}->status_line,
					    method_name => 'upload',
				       );
    }
}
 


=head2 download

  $obj->download($h, $outfile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is an AbstractHandle.Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h is an AbstractHandle.Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function download (received $n, expecting 2)");
    }
    {
	my($h, $outfile) = @args;

	my @_bad_arguments;
        (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"h\" (value was \"$h\")");
        (!ref($outfile)) or push(@_bad_arguments, "Invalid type for argument 2 \"outfile\" (value was \"$outfile\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to download:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'download');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.download",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'download',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method download",
					    status_line => $self->{client}->status_line,
					    method_name => 'download',
				       );
    }
}
 


=head2 upload_metadata

  $obj->upload_metadata($h, $infile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is an AbstractHandle.Handle
$infile is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h is an AbstractHandle.Handle
$infile is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


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
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function upload_metadata (received $n, expecting 2)");
    }
    {
	my($h, $infile) = @args;

	my @_bad_arguments;
        (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"h\" (value was \"$h\")");
        (!ref($infile)) or push(@_bad_arguments, "Invalid type for argument 2 \"infile\" (value was \"$infile\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to upload_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'upload_metadata');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.upload_metadata",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'upload_metadata',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method upload_metadata",
					    status_line => $self->{client}->status_line,
					    method_name => 'upload_metadata',
				       );
    }
}
 


=head2 download_metadata

  $obj->download_metadata($h, $outfile)

=over 4

=item Parameter and return types

=begin html

<pre>
$h is an AbstractHandle.Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$h is an AbstractHandle.Handle
$outfile is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


=end text

=item Description

The download_metadata function downloads metadata associated
with the data handle and writes it to a file.

[client_implemented]

=back

=cut

 sub download_metadata
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function download_metadata (received $n, expecting 2)");
    }
    {
	my($h, $outfile) = @args;

	my @_bad_arguments;
        (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 1 \"h\" (value was \"$h\")");
        (!ref($outfile)) or push(@_bad_arguments, "Invalid type for argument 2 \"outfile\" (value was \"$outfile\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to download_metadata:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'download_metadata');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.download_metadata",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'download_metadata',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method download_metadata",
					    status_line => $self->{client}->status_line,
					    method_name => 'download_metadata',
				       );
    }
}
 


=head2 hids_to_handles

  $handles = $obj->hids_to_handles($hids)

=over 4

=item Parameter and return types

=begin html

<pre>
$hids is a reference to a list where each element is an AbstractHandle.HandleId
$handles is a reference to a list where each element is an AbstractHandle.Handle
HandleId is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
NodeId is a string

</pre>

=end html

=begin text

$hids is a reference to a list where each element is an AbstractHandle.HandleId
$handles is a reference to a list where each element is an AbstractHandle.Handle
HandleId is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
NodeId is a string


=end text

=item Description

Given a list of handle ids, this function returns
a list of handles.

=back

=cut

 sub hids_to_handles
{
    my($self, @args) = @_;

# Authentication: none

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function hids_to_handles (received $n, expecting 1)");
    }
    {
	my($hids) = @args;

	my @_bad_arguments;
        (ref($hids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"hids\" (value was \"$hids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to hids_to_handles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'hids_to_handles');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.hids_to_handles",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'hids_to_handles',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method hids_to_handles",
					    status_line => $self->{client}->status_line,
					    method_name => 'hids_to_handles',
				       );
    }
}
 


=head2 are_readable

  $return = $obj->are_readable($arg_1)

=over 4

=item Parameter and return types

=begin html

<pre>
$arg_1 is a reference to a list where each element is an AbstractHandle.HandleId
$return is an int
HandleId is a string

</pre>

=end html

=begin text

$arg_1 is a reference to a list where each element is an AbstractHandle.HandleId
$return is an int
HandleId is a string


=end text

=item Description

Given a list of handle ids, this function determines if
the underlying data is readable by the caller. If any
one of the handle ids reference unreadable data this
function returns false.

=back

=cut

 sub are_readable
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function are_readable (received $n, expecting 1)");
    }
    {
	my($arg_1) = @args;

	my @_bad_arguments;
        (ref($arg_1) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"arg_1\" (value was \"$arg_1\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to are_readable:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'are_readable');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.are_readable",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'are_readable',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method are_readable",
					    status_line => $self->{client}->status_line,
					    method_name => 'are_readable',
				       );
    }
}
 


=head2 is_owner

  $return = $obj->is_owner($arg_1)

=over 4

=item Parameter and return types

=begin html

<pre>
$arg_1 is a reference to a list where each element is an AbstractHandle.HandleId
$return is an int
HandleId is a string

</pre>

=end html

=begin text

$arg_1 is a reference to a list where each element is an AbstractHandle.HandleId
$return is an int
HandleId is a string


=end text

=item Description

Given a list of handle ids, this function determines if the underlying
data is owned by the caller. If any one of the handle ids reference
unreadable data this function returns false.

=back

=cut

 sub is_owner
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function is_owner (received $n, expecting 1)");
    }
    {
	my($arg_1) = @args;

	my @_bad_arguments;
        (ref($arg_1) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"arg_1\" (value was \"$arg_1\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to is_owner:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'is_owner');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.is_owner",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'is_owner',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method is_owner",
					    status_line => $self->{client}->status_line,
					    method_name => 'is_owner',
				       );
    }
}
 


=head2 is_readable

  $return = $obj->is_readable($id)

=over 4

=item Parameter and return types

=begin html

<pre>
$id is a string
$return is an int

</pre>

=end html

=begin text

$id is a string
$return is an int


=end text

=item Description

Given a handle id, this function queries the underlying
data store to see if the data being referred to is
readable to by the caller.

=back

=cut

 sub is_readable
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function is_readable (received $n, expecting 1)");
    }
    {
	my($id) = @args;

	my @_bad_arguments;
        (!ref($id)) or push(@_bad_arguments, "Invalid type for argument 1 \"id\" (value was \"$id\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to is_readable:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'is_readable');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.is_readable",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'is_readable',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method is_readable",
					    status_line => $self->{client}->status_line,
					    method_name => 'is_readable',
				       );
    }
}
 


=head2 list_handles

  $l = $obj->list_handles()

=over 4

=item Parameter and return types

=begin html

<pre>
$l is a reference to a list where each element is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$l is a reference to a list where each element is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


=end text

=item Description

The list function returns the set of handles that were
created by the user.

=back

=cut

 sub list_handles
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 0)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function list_handles (received $n, expecting 0)");
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.list_handles",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'list_handles',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method list_handles",
					    status_line => $self->{client}->status_line,
					    method_name => 'list_handles',
				       );
    }
}
 


=head2 delete_handles

  $obj->delete_handles($l)

=over 4

=item Parameter and return types

=begin html

<pre>
$l is a reference to a list where each element is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$l is a reference to a list where each element is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


=end text

=item Description

The delete_handles function takes a list of handles
and deletes them on the handle service server.

=back

=cut

 sub delete_handles
{
    my($self, @args) = @_;

# Authentication: optional

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function delete_handles (received $n, expecting 1)");
    }
    {
	my($l) = @args;

	my @_bad_arguments;
        (ref($l) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"l\" (value was \"$l\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to delete_handles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'delete_handles');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.delete_handles",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'delete_handles',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method delete_handles",
					    status_line => $self->{client}->status_line,
					    method_name => 'delete_handles',
				       );
    }
}
 


=head2 give

  $obj->give($user, $perm, $h)

=over 4

=item Parameter and return types

=begin html

<pre>
$user is a string
$perm is a string
$h is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string

</pre>

=end html

=begin text

$user is a string
$perm is a string
$h is an AbstractHandle.Handle
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string
NodeId is a string


=end text

=item Description



=back

=cut

 sub give
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function give (received $n, expecting 3)");
    }
    {
	my($user, $perm, $h) = @args;

	my @_bad_arguments;
        (!ref($user)) or push(@_bad_arguments, "Invalid type for argument 1 \"user\" (value was \"$user\")");
        (!ref($perm)) or push(@_bad_arguments, "Invalid type for argument 2 \"perm\" (value was \"$perm\")");
        (ref($h) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 3 \"h\" (value was \"$h\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to give:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'give');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.give",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'give',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method give",
					    status_line => $self->{client}->status_line,
					    method_name => 'give',
				       );
    }
}
 


=head2 ids_to_handles

  $handles = $obj->ids_to_handles($ids)

=over 4

=item Parameter and return types

=begin html

<pre>
$ids is a reference to a list where each element is an AbstractHandle.NodeId
$handles is a reference to a list where each element is an AbstractHandle.Handle
NodeId is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string

</pre>

=end html

=begin text

$ids is a reference to a list where each element is an AbstractHandle.NodeId
$handles is a reference to a list where each element is an AbstractHandle.Handle
NodeId is a string
Handle is a reference to a hash where the following keys are defined:
	hid has a value which is an AbstractHandle.HandleId
	file_name has a value which is a string
	id has a value which is an AbstractHandle.NodeId
	type has a value which is a string
	url has a value which is a string
	remote_md5 has a value which is a string
	remote_sha1 has a value which is a string
HandleId is a string


=end text

=item Description

Given a list of ids, this function returns
a list of handles. In case of Shock, the list of ids
are shock node ids and this function the handles, which
contains Shock url and related information.

=back

=cut

 sub ids_to_handles
{
    my($self, @args) = @_;

# Authentication: required

    if ((my $n = @args) != 1)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function ids_to_handles (received $n, expecting 1)");
    }
    {
	my($ids) = @args;

	my @_bad_arguments;
        (ref($ids) eq 'ARRAY') or push(@_bad_arguments, "Invalid type for argument 1 \"ids\" (value was \"$ids\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to ids_to_handles:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'ids_to_handles');
	}
    }

    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
	    method => "AbstractHandle.ids_to_handles",
	    params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{error}->{code},
					       method_name => 'ids_to_handles',
					       data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method ids_to_handles",
					    status_line => $self->{client}->status_line,
					    method_name => 'ids_to_handles',
				       );
    }
}
 
  
sub status
{
    my($self, @args) = @_;
    if ((my $n = @args) != 0) {
        Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
                                   "Invalid argument count for function status (received $n, expecting 0)");
    }
    my $url = $self->{url};
    my $result = $self->{client}->call($url, $self->{headers}, {
        method => "AbstractHandle.status",
        params => \@args,
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
                           code => $result->content->{error}->{code},
                           method_name => 'status',
                           data => $result->content->{error}->{error} # JSON::RPC::ReturnObject only supports JSONRPC 1.1 or 1.O
                          );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method status",
                        status_line => $self->{client}->status_line,
                        method_name => 'status',
                       );
    }
}
   

sub version {
    my ($self) = @_;
    my $result = $self->{client}->call($self->{url}, $self->{headers}, {
        method => "AbstractHandle.version",
        params => [],
    });
    if ($result) {
        if ($result->is_error) {
            Bio::KBase::Exceptions::JSONRPC->throw(
                error => $result->error_message,
                code => $result->content->{code},
                method_name => 'ids_to_handles',
            );
        } else {
            return wantarray ? @{$result->result} : $result->result->[0];
        }
    } else {
        Bio::KBase::Exceptions::HTTP->throw(
            error => "Error invoking method ids_to_handles",
            status_line => $self->{client}->status_line,
            method_name => 'ids_to_handles',
        );
    }
}

sub _validate_version {
    my ($self) = @_;
    my $svr_version = $self->version();
    my $client_version = $VERSION;
    my ($cMajor, $cMinor) = split(/\./, $client_version);
    my ($sMajor, $sMinor) = split(/\./, $svr_version);
    if ($sMajor != $cMajor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Major version numbers differ.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor < $cMinor) {
        Bio::KBase::Exceptions::ClientServerIncompatible->throw(
            error => "Client minor version greater than Server minor version.",
            server_version => $svr_version,
            client_version => $client_version
        );
    }
    if ($sMinor > $cMinor) {
        warn "New client version available for AbstractHandleClient\n";
    }
    if ($sMajor == 0) {
        warn "AbstractHandleClient version is $svr_version. API subject to change.\n";
    }
}

=head1 TYPES



=head2 HandleId

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
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 NodeId

=over 4



=item Definition

=begin html

<pre>
a string
</pre>

=end html

=begin text

a string

=end text

=back



=head2 Handle

=over 4



=item Definition

=begin html

<pre>
a reference to a hash where the following keys are defined:
hid has a value which is an AbstractHandle.HandleId
file_name has a value which is a string
id has a value which is an AbstractHandle.NodeId
type has a value which is a string
url has a value which is a string
remote_md5 has a value which is a string
remote_sha1 has a value which is a string

</pre>

=end html

=begin text

a reference to a hash where the following keys are defined:
hid has a value which is an AbstractHandle.HandleId
file_name has a value which is a string
id has a value which is an AbstractHandle.NodeId
type has a value which is a string
url has a value which is a string
remote_md5 has a value which is a string
remote_sha1 has a value which is a string


=end text

=back



=cut

package AbstractHandleClient::RpcClient;
use base 'JSON::RPC::Client';
use POSIX;
use strict;

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $headers, $obj) = @_;
    my $result;


    {
	if ($uri =~ /\?/) {
	    $result = $self->_get($uri);
	}
	else {
	    Carp::croak "not hashref." unless (ref $obj eq 'HASH');
	    $result = $self->_post($uri, $headers, $obj);
	}

    }

    my $service = $obj->{method} =~ /^system\./ if ( $obj );

    $self->status_line($result->status_line);

    if ($result->is_success) {

        return unless($result->content); # notification?

        if ($service) {
            return JSON::RPC::ServiceObject->new($result, $self->json);
        }

        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    elsif ($result->content_type eq 'application/json')
    {
        return JSON::RPC::ReturnObject->new($result, $self->json);
    }
    else {
        return;
    }
}


sub _post {
    my ($self, $uri, $headers, $obj) = @_;
    my $json = $self->json;

    $obj->{version} ||= $self->{version} || '1.1';

    if ($obj->{version} eq '1.0') {
        delete $obj->{version};
        if (exists $obj->{id}) {
            $self->id($obj->{id}) if ($obj->{id}); # if undef, it is notification.
        }
        else {
            $obj->{id} = $self->id || ($self->id('JSON::RPC::Client'));
        }
    }
    else {
        # $obj->{id} = $self->id if (defined $self->id);
	# Assign a random number to the id if one hasn't been set
	$obj->{id} = (defined $self->id) ? $self->id : substr(rand(),2);
    }

    my $content = $json->encode($obj);

    $self->ua->post(
        $uri,
        Content_Type   => $self->{content_type},
        Content        => $content,
        Accept         => 'application/json',
	@$headers,
	($self->{token} ? (Authorization => $self->{token}) : ()),
    );
}



1;
