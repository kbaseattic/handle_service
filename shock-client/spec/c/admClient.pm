package admClient;

use JSON::RPC::Client;
use strict;
use Data::Dumper;
use URI;
use Bio::KBase::Exceptions;

=head1 NAME

admClient

=head1 DESCRIPTION



=cut

sub new
{
    my($class, $url) = @_;

    my $self = {
	client => admClient::RpcClient->new,
	url => $url,
    };
    my $ua = $self->{client}->ua;	 
    my $timeout = $ENV{CDMI_TIMEOUT} || (30 * 60);	 
    $ua->timeout($timeout);

    return bless $self, $class;
}




=head2 $result = createUser(n, p)

Create a user

=cut

sub createUser
{
    my($self, @args) = @_;

    if ((my $n = @args) != 2)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function createUser (received $n, expecting 2)");
    }
    {
	my($n, $p) = @args;

	my @_bad_arguments;
        (!ref($n)) or push(@_bad_arguments, "Invalid type for argument 1 \"n\" (value was \"$n\")");
        (!ref($p)) or push(@_bad_arguments, "Invalid type for argument 2 \"p\" (value was \"$p\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to createUser:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'createUser');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "adm.createUser",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'createUser',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method createUser",
					    status_line => $self->{client}->status_line,
					    method_name => 'createUser',
				       );
    }
}



=head2 $result = createNode(n, p, np)

Create a node

=cut

sub createNode
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function createNode (received $n, expecting 3)");
    }
    {
	my($n, $p, $np) = @args;

	my @_bad_arguments;
        (!ref($n)) or push(@_bad_arguments, "Invalid type for argument 1 \"n\" (value was \"$n\")");
        (!ref($p)) or push(@_bad_arguments, "Invalid type for argument 2 \"p\" (value was \"$p\")");
        (ref($np) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 3 \"np\" (value was \"$np\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to createNode:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'createNode');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "adm.createNode",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'createNode',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method createNode",
					    status_line => $self->{client}->status_line,
					    method_name => 'createNode',
				       );
    }
}



=head2 $result = modifyNode(n, p, np)

Modify a node.

=cut

sub modifyNode
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function modifyNode (received $n, expecting 3)");
    }
    {
	my($n, $p, $np) = @args;

	my @_bad_arguments;
        (!ref($n)) or push(@_bad_arguments, "Invalid type for argument 1 \"n\" (value was \"$n\")");
        (!ref($p)) or push(@_bad_arguments, "Invalid type for argument 2 \"p\" (value was \"$p\")");
        (ref($np) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 3 \"np\" (value was \"$np\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to modifyNode:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'modifyNode');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "adm.modifyNode",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'modifyNode',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method modifyNode",
					    status_line => $self->{client}->status_line,
					    method_name => 'modifyNode',
				       );
    }
}



=head2 $result = listNodes(n, p, sp)

List nodes

=cut

sub listNodes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 3)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function listNodes (received $n, expecting 3)");
    }
    {
	my($n, $p, $sp) = @args;

	my @_bad_arguments;
        (!ref($n)) or push(@_bad_arguments, "Invalid type for argument 1 \"n\" (value was \"$n\")");
        (!ref($p)) or push(@_bad_arguments, "Invalid type for argument 2 \"p\" (value was \"$p\")");
        (ref($sp) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 3 \"sp\" (value was \"$sp\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to listNodes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'listNodes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "adm.listNodes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'listNodes',
					      );
	} else {
	    return wantarray ? @{$result->result} : $result->result->[0];
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method listNodes",
					    status_line => $self->{client}->status_line,
					    method_name => 'listNodes',
				       );
    }
}



=head2 $result = viewNodes(n, p, id, v)

View nodes

=cut

sub viewNodes
{
    my($self, @args) = @_;

    if ((my $n = @args) != 4)
    {
	Bio::KBase::Exceptions::ArgumentValidationError->throw(error =>
							       "Invalid argument count for function viewNodes (received $n, expecting 4)");
    }
    {
	my($n, $p, $id, $v) = @args;

	my @_bad_arguments;
        (!ref($n)) or push(@_bad_arguments, "Invalid type for argument 1 \"n\" (value was \"$n\")");
        (!ref($p)) or push(@_bad_arguments, "Invalid type for argument 2 \"p\" (value was \"$p\")");
        (!ref($id)) or push(@_bad_arguments, "Invalid type for argument 3 \"id\" (value was \"$id\")");
        (ref($v) eq 'HASH') or push(@_bad_arguments, "Invalid type for argument 4 \"v\" (value was \"$v\")");
        if (@_bad_arguments) {
	    my $msg = "Invalid arguments passed to viewNodes:\n" . join("", map { "\t$_\n" } @_bad_arguments);
	    Bio::KBase::Exceptions::ArgumentValidationError->throw(error => $msg,
								   method_name => 'viewNodes');
	}
    }

    my $result = $self->{client}->call($self->{url}, {
	method => "adm.viewNodes",
	params => \@args,
    });
    if ($result) {
	if ($result->is_error) {
	    Bio::KBase::Exceptions::JSONRPC->throw(error => $result->error_message,
					       code => $result->content->{code},
					       method_name => 'viewNodes',
					      );
	} else {
	    return;
	}
    } else {
        Bio::KBase::Exceptions::HTTP->throw(error => "Error invoking method viewNodes",
					    status_line => $self->{client}->status_line,
					    method_name => 'viewNodes',
				       );
    }
}




package admClient::RpcClient;
use base 'JSON::RPC::Client';

#
# Override JSON::RPC::Client::call because it doesn't handle error returns properly.
#

sub call {
    my ($self, $uri, $obj) = @_;
    my $result;

    if ($uri =~ /\?/) {
       $result = $self->_get($uri);
    }
    else {
        Carp::croak "not hashref." unless (ref $obj eq 'HASH');
        $result = $self->_post($uri, $obj);
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


1;
