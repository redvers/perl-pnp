package QxServ::JsonRpcService;
use Mojo::Base -base;
use File::Copy;
use Data::Dumper;

has 'pnp';
has 'dbi';

# whenever a service method is about to be executed, the dispatcher calls the
# "allow_rpc_access" method to determine if the incoming request should be satisfied.
# You can use this facility to enforce access control to the methods of your service.
# Make sure to only allow access to the things you want to be public. Also the answers
# of the "allow_rpc_access" method could depend on the session status.
 
our %allow_access =  (
    xyza => 1,
    feeder => 1,
    g92xya => 1,
    g92z68 => 1,
    relmove => 1,
    relamove => 1,
    relzmove => 1,
    absmove => 1
);
 
sub allow_rpc_access {
    my $self = shift;
    my $method = shift;
	print("method: $method\n");
    return $allow_access{$method};
}
 
# the echo method returns what it hears except when it hears 'die' then
# it dies. Here we use a hash pointer with a code and a message property
# with this we can control what gets sent back to the qooxdoo application.
 
sub xyza {
    my $self = shift;
    my $arg = shift;

	my $foo = [	[$self->pnp->x,	$self->pnp->y,	$self->pnp->z,	$self->pnp->a],
			[$self->pnp->x + $self->pnp->{'pnpconfig'}{'downCameraConfig'}{'Xoffset'},$self->pnp->y + $self->pnp->{'pnpconfig'}{'downCameraConfig'}{'Yoffset'},$self->pnp->z,	$self->pnp->a], [$self->pnp->vel, $self->pnp->stat]];
    return $foo;
}

sub feeder {
	my $self = shift;
	my $arg = shift;

	my $sth = $self->dbi->prepare("select f.id,c.value,c.package,f.x1,f.y1,f.x2,f.y2,f.a1,f.z1,f.count,f.netavail from feeder f LEFT JOIN component c ON (c.id = f.id_component) order by f.id");
	$sth->execute;

	my @ds;
	while (my @array = $sth->fetchrow_array) {
		print("Before: ");
		print(Dumper \@ds);
		print("After: ");
		push(@ds, [@array]);
		print("After: ");
		print(Dumper \@ds);
	}
#	print(Dumper \@ds);

	return \@ds;
}

sub relmove {
	my $self = shift;
	my $args = shift;

	my $x = $args->[0];
	my $y = $args->[1];

	$self->pnp->relMove($x, $y);
}

sub g92xya {
	my $self = shift;
	my $args = shift;

	$self->pnp->g92xya();
}

sub g92z68 {
	my $self = shift;
	my $args = shift;

	$self->pnp->g92z68();
}

sub relamove {
	my $self = shift;
	my $args = shift;

	my $a = $args->[0];

	$self->pnp->relAMove($a);
}

sub relzmove {
	my $self = shift;
	my $args = shift;

	my $z = $args->[0];

	$self->pnp->relZMove($z);
}

sub absmove {
	my $self = shift;
	my $args = shift;

	my $x = $args->[0];
	my $y = $args->[1];

	$self->pnp->absMove($x, $y);
}









