package PNP::Comms;

use 5.012004;
use strict;
use warnings;

use YAML;
use Moose;
use JSON::XS;
use IO::Select;
use IO::Socket::INET;

use Data::Dumper;

has 'debug' => (is => 'rw', isa => 'Int');
has 'x' => (is => 'rw');
has 'y' => (is => 'rw');
has 'z' => (is => 'rw');
has 'a' => (is => 'rw');
has 'vel' => (is => 'rw');
has 'stat' => (is => 'rw');

has 'wr_fifo' => (is => 'rw', isa => 'Any', default => sub { return [] });

has 'lashx' => (is => 'rw', isa => 'Int', default => sub { return 2 });
has 'lashy' => (is => 'rw', isa => 'Int', default => sub { return 2 });

sub BUILD {
	my $self = shift;
	print("Building...\n");
	$self->{'socket'} = IO::Socket::INET->new(PeerAddr => '192.168.1.19:5353') || die;
	$self->{'select'} = IO::Select->new();
	($self->{'select'})->add($self->{'socket'});

	open(FILE_FD, "pnp.conf") || die("No pnp.conf");
	my @tmp = <FILE_FD>;
	$self->{'pnpconfig'} = Load join("", @tmp);

	$self->stat(5);

}

sub tick {
	my $self = shift;
	my @array = ($self->{'select'})->can_read(0.01);

	if ($#array >= 0) {
		my $socket = $self->{'socket'};
		my $line_in = <$socket>;

		$line_in =~ s///g;

		my @lines = split(/\n/, $line_in);
		chomp(@lines);

		foreach my $line (@lines) {
			$self->wr_debug("\n>> $line <<\n");
			if ($line =~ /{"sr"/) {
				$self->parsesr($line);
				@array = ($self->{'select'})->can_read(0.01);
				if (($self->stat == 5) && ($#array == -1)) { # BufferEmpty + moving
					print($socket '{"sr":""}');
					print($socket "\n");
				}
			}
#			$self->wr_debug(sprintf("x: %f\ny: %f\nz: %f\na: %f\nvel: %f\n",
#				$self->x, $self->y, $self->z, $self->a, $self->vel));
		}
	} else {
#		$self->wr_debug(".");
		# Let's look at writing
		my @tmp = @{$self->wr_fifo};
		if ($#tmp == -1) {
			$self->wr_debug(".");
		} else {
			my $wr_line = shift(@{$self->wr_fifo});

			if ($self->stat == 5) {
				return; # Still moving
			}

			$self->wr_debug("<< $wr_line >>\n");

			my $socket = $self->{'socket'};
			print($socket $wr_line);
			print($socket "\r\n");
		#	$self->stat(5);
		}



	}
}



sub parsesr {
	my $self = shift;
	my $line_in = shift;

	my $ds = decode_json($line_in);
#	$self->wr_debug(Dumper $ds);

	if (!defined($ds->{'r'})) {
		# Must be an sr kinda day:
		if (!defined($ds->{'sr'})) {
			die; # Just plain busted
		}
		$self->x($ds->{'sr'}{'posx'});
		$self->y($ds->{'sr'}{'posy'});
		$self->z($ds->{'sr'}{'posz'});
		$self->a($ds->{'sr'}{'posa'});
		$self->vel($ds->{'sr'}{'vel'});
		$self->stat($ds->{'sr'}{'stat'});
	} else {
		$self->x($ds->{'r'}{'sr'}{'posx'});
		$self->y($ds->{'r'}{'sr'}{'posy'});
		$self->z($ds->{'r'}{'sr'}{'posz'});
		$self->a($ds->{'r'}{'sr'}{'posa'});
		$self->stat($ds->{'r'}{'sr'}{'stat'});

	}
}

sub getCurrentPos {
	my $self = shift;

	my $socket = $self->{'socket'};
	print($socket '{"sr":""}'."\n");

}

sub g92xya {
	my $self = shift;

	my $socket = $self->{'socket'};
	print($socket '{"gc":"G92X0Y0A0"}'."\n");
	print($socket '{"sr":""}'."\n");

}

sub g92z68 {
	my $self = shift;

	my $socket = $self->{'socket'};
	print($socket '{"gc":"G92Z68"}'."\n");
	print($socket '{"sr":""}'."\n");

}

sub relMove {
	my $self = shift;
	my $socket = $self->{'socket'};
	my $x = shift;			
	my $y = shift;		

	## Calculate positions in advance because they're gonna move.
	## Let's overshoot because that's easier on the brane.

	## Initial New positions = $current + $offset + $lash
	## Final position = $current + $offset

	my $xto = $self->x + $x + $self->lashx;
	my $yto = $self->y + $y + $self->lashy;

	my $xfin = $self->x + $x;
	my $yfin = $self->y + $y;

	push(@{$self->wr_fifo},'{"gc": "G90"}');
	push(@{$self->wr_fifo}, sprintf('{"gc":"G0 X%f Y%f"}', $xto, $yto));
	push(@{$self->wr_fifo},'{"gc": "G90"}');
	push(@{$self->wr_fifo}, sprintf('{"gc":"G0 X%f Y%f"}', $xfin, $yfin));
}

sub relAMove {
	my $self = shift;
	my $socket = $self->{'socket'};
	my $a = shift;			

	my $afin = $self->a + $a;

	push(@{$self->wr_fifo},'{"gc": "G90"}');
	push(@{$self->wr_fifo}, sprintf('{"gc":"G0 A%f"}', $afin));
}

sub relZMove {
	my $self = shift;
	my $socket = $self->{'socket'};
	my $z = shift;			

	my $zfin = $self->z + $z;

	push(@{$self->wr_fifo},'{"gc": "G90"}');
	push(@{$self->wr_fifo}, sprintf('{"gc":"G0 Z%f"}', $zfin));
}


sub absMove {
	my $self = shift;
	my $socket = $self->{'socket'};
	my $x = shift;			
	my $y = shift;		

	## Calculate positions in advance because they're gonna move.
	## Let's overshoot because that's easier on the brane.

	my $xto = $x + $self->lashx;
	my $yto = $y + $self->lashy;

	my $xfin = $x;
	my $yfin = $y;

	push(@{$self->wr_fifo},'{"gc": "G90"}');
	push(@{$self->wr_fifo}, sprintf('{"gc":"G0 X%f Y%f"}', $xto, $yto));
	push(@{$self->wr_fifo}, '{"gc":"G4 P1"}');
	push(@{$self->wr_fifo}, sprintf('{"gc":"G0 X%f Y%f"}', $xfin, $yfin));
}


sub wr_debug {
	my $self = shift;
	if ($self->{'debug'}) {
		my $line_in;
		while ($line_in = shift) {
			print(STDERR $line_in);
		}
	}
}
1;

__END__

	$response = $self->one_line();

	$self->wr_debug("Reporting on this one: ");
	$self->wr_debug(Dumper $response);

	if (ref($response->{'f'} eq "HASH")) {
		$self->wr_debug(sprintf("Returning: %f, %f, %f, %f",$response->{'r'}{'sr'}{'posx'},$response->{'r'}{'sr'}{'posy'},$response->{'r'}{'sr'}{'posz'},$response->{'r'}{'sr'}{'posa'}));
		return( $response->{'r'}{'sr'}{'posx'},
		$response->{'r'}{'sr'}{'posy'},
		$response->{'r'}{'sr'}{'posz'},
		$response->{'r'}{'sr'}{'posa'});
	} else {
		$self->wr_debug(sprintf("Returning: %f, %f, %f, %f",$response->{'r'}{'sr'}{'posx'},$response->{'sr'}{'posy'},$response->{'sr'}{'posz'},$response->{'sr'}{'posa'}));
		return( $response->{'sr'}{'posx'},
		$response->{'sr'}{'posy'},
		$response->{'sr'}{'posz'},
		$response->{'sr'}{'posa'});
	}

}

sub wr_debug {
	my $self = shift;
	if ($self->{'debug'}) {
		my $line_in;
		while ($line_in = shift) {
			print(STDERR $line_in);
		}
	}
}

1;
__END__
