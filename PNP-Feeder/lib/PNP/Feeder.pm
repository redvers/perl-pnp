package PNP::Feeder;

#use 5.020000;
use strict;
use warnings;

use YAML;
use DBD::CSV;
use Data::Dumper;

use Moose;

has 'debug'	=> (is => 'rw', isa => 'Num');

has 'component'	=> (is => 'ro', isa => 'Str');
has 'active'	=> (is => 'rw', isa => 'Num');

has 'x0'	=> (is => 'rw', isa => 'Num');
has 'y0'	=> (is => 'rw', isa => 'Num');
has 'z0'	=> (is => 'rw', isa => 'Num');
has 'a0'	=> (is => 'rw', isa => 'Num');

has 'x1'	=> (is => 'rw', isa => 'Num');
has 'y1'	=> (is => 'rw', isa => 'Num');
has 'z1'	=> (is => 'rw', isa => 'Num');
has 'a1'	=> (is => 'rw', isa => 'Num');

has 'pointer'	=> (is => 'rw', isa => 'Num');
has 'count'	=> (is => 'rw', isa => 'Num');

has 'dbh'	=> (is => 'ro', isa => 'Any', default => sub {
			DBI->connect("DBI:CSV:", undef, undef, { f_ext => '.csv/r' }) });

sub getCoord {
	my $self = shift;
	my $x = $self->x0 + ($self->pointer * (($self->x1 - $self->x0) / ($self->count - 1)));
	my $y = $self->y0 + ($self->pointer * (($self->y1 - $self->y0) / ($self->count - 1)));
	my $z = $self->z0 + ($self->pointer * (($self->z1 - $self->z0) / ($self->count - 1)));
	my $a = $self->a0 + ($self->pointer * (($self->a1 - $self->a0) / ($self->count - 1))); #carosel feeder? :-)
	return($x, $y, $z, $a);
}

sub getList {
	my $self = shift;
	my $sth = $self->dbh->prepare('select * from generic where Side = ?');

	$sth->execute('Top');

	my $feeders = {};
	my $feednum = {};

	while (my $hashref = $sth->fetchrow_hashref) {
		my $str = $hashref->{'name'}."_".$hashref->{'value'};
		push(@{$feeders->{$str}}, $hashref->{'refdes'});
		$feednum->{$str}++;
	}

	foreach my $component (sort { $feednum->{$b} <=> $feednum->{$a} } keys %$feednum) {
		$self->wr_debug(sprintf("Processing: %s, count: %d\nrefdes:(%s)\n\n", $component, $feednum->{$component}, join(', ', @{$feeders->{$component}})));
	}

	return $feeders;

}

sub load {
	my $self = shift;

	my $sth = $self->dbh->prepare("select yaml from feeders where component = ?");
	$sth->execute($self->component);

	if ($sth->rows() == 0) {
		$self->active(0);
		return undef;
	}

	my $yaml = $sth->fetchrow_array;

	my $hash = Load($yaml);


	$self->component($hash->{'component'});
	$self->active($hash->{'active'});

	$self->x0($hash->{'x0'});
	$self->y0($hash->{'y0'});
	$self->z0($hash->{'z0'});
	$self->a0($hash->{'a0'});

	$self->x1($hash->{'x1'});
	$self->y1($hash->{'y1'});
	$self->z1($hash->{'z1'});
	$self->a1($hash->{'a1'});

	$self->pointer($hash->{'pointer'});
	$self->count($hash->{'count'});
	
}


sub save {
	my $self = shift;
	my $hash = {
		component => $self->component,
		active => $self->active,
		

		x0 => $self->x0,
		y0 => $self->y0,
		z0 => $self->z0,
		a0 => $self->a0,

		x1 => $self->x1,
		y1 => $self->y1,
		z1 => $self->z1,
		a1 => $self->a1,

		pointer => $self->pointer,
		count => $self->count

	};

	my $std = $self->prepare("delete from feeders where component = ?");
	my $sth = $self->prepare("insert into feeders (component,yaml) VALUES (?,?)");
	$std->execute($self->component);

	$sth->execute($self->component, Dump($hash));

}


sub wr_debug {
	my $self = shift;
	if ($self->debug) {
		while (my $line = shift) {
			printf("%s\n", $line);
		}
	}
}

# Preloaded methods go here.

1;
__END__


