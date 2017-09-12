use Bio::KBase::AbstractHandle::AbstractHandleImpl;

use Bio::KBase::AbstractHandle::AbstractHandleServer;
use Plack::Middleware::CrossOrigin;



my @dispatch;

{
    my $obj = Bio::KBase::AbstractHandle::AbstractHandleImpl->new;
    push(@dispatch, 'AbstractHandle' => $obj);
}


my $server = Bio::KBase::AbstractHandle::AbstractHandleServer->new(instance_dispatch => { @dispatch },
				allow_get => 0,
			       );

my $handler = sub { $server->handle_input(@_) };

$handler = Plack::Middleware::CrossOrigin->wrap( $handler, origins => "*", headers => "*");
