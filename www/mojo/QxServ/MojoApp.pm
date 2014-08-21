package QxServ::MojoApp;
# Inherit from the Mojolicious package
use Mojo::Base 'Mojolicious';
# Load our JsonRpcService module (see below)
use QxServ::JsonRpcService;
 
sub startup {
    my $self = shift;
 
    # load the Mojolicious::Plugin::QooxdooJsonrpc module
    $self->plugin('qooxdoo_jsonrpc', {
        services => {
             rpc => QxServ::JsonRpcService->new,
        }
    });
}
 
1;
