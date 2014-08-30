package QxServ::MojoApp;
# Inherit from the Mojolicious package
use Mojo::Base 'Mojolicious';
# Load our JsonRpcService module (see below)
use QxServ::JsonRpcService;
use Mojo::IOLoop;
use PNP::Comms;
use DBI;
 
sub startup {
    my $self = shift;

	my $pnp = new PNP::Comms(debug => 1);
	my $dbi = DBI->connect("DBI:Pg:dbname=pnp", "red", "") || die;
	$pnp->getCurrentPos();
 
    # load the Mojolicious::Plugin::QooxdooJsonrpc module
    $self->plugin('qooxdoo_jsonrpc', {
        services => {
             rpc => QxServ::JsonRpcService->new( pnp => $pnp, dbi => $dbi )
        }
    });

	Mojo::IOLoop->recurring(0.1, sub {
		$pnp->tick();
	});

}
 
1;
