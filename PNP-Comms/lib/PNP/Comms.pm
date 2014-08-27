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

has 'lashx' => (is => 'rw', isa => 'Int', default => sub { return -2 });
has 'lashy' => (is => 'rw', isa => 'Int', default => sub { return -2 });

sub BUILD {
	my $self = shift;
	print("Building...\n");
	$self->{'socket'} = IO::Socket::INET->new(PeerAddr => '192.168.1.19:5353') || die;
	$self->{'select'} = IO::Select->new();
	($self->{'select'})->add($self->{'socket'});

	open(FILE_FD, "pnp.conf") || die("No pnp.conf");
	my @tmp = <FILE_FD>;
	$self->{'pnpconfig'} = Load join("", @tmp);

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
			if ($line =~ /"sr"/) {
				$self->parsesr($line);
			}
			$self->wr_debug(sprintf("x: %f\ny: %f\nz: %f\na: %f\nvel: %f\n",
				$self->x, $self->y, $self->z, $self->a, $self->vel));
		}
	} else {
		$self->wr_debug(".");
	}
}



sub parsesr {
	my $self = shift;
	my $line_in = shift;

	my $ds = decode_json($line_in);
	$self->wr_debug(Dumper $ds);

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
	} else {
		$self->x($ds->{'r'}{'sr'}{'posx'});
		$self->y($ds->{'r'}{'sr'}{'posy'});
		$self->z($ds->{'r'}{'sr'}{'posz'});
		$self->a($ds->{'r'}{'sr'}{'posa'});
		$self->vel($ds->{'r'}{'sr'}{'vel'});

	}
}

sub getCurrentPos {
	my $self = shift;

	my $socket = $self->{'socket'};
	print($socket '{"sr":""}'."\n");

}

sub relMove {
	my $self = shift;
	my $socket = $self->{'socket'};
	my $x = shift;
	my $y = shift;

	$x += $self->lashx;
	$y += $self->lashy;

	print('{"gc":"G91"}'."\n");

	my $smovestr = sprintf('{"gc":"G0 X%f Y%f"}\n', $x, $y);
	print($smovestr);

	$x -= $self->lashx;
	$y -= $self->lashy;

	$smovestr = sprintf('{"gc":"G0 X%f Y%f"}\n', $x, $y);
	print($smovestr);

	print($socket '{"gc": "G90"}'."\n");
	
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
sub locationCallback {
	my $self = shift;
	$self->{'callback'} = shift;
	$self->wr_debug("Registered callback ".$self->{'callback'}." on locationCallback\n");
}



sub moveAbsTo {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;
	my $a = shift;

	my ($curx, $cury, $curz, $cura) = $self->getCurrentPos();

	if (!defined($x)) { $x = $curx };
	if (!defined($y)) { $y = $cury };
	if (!defined($z)) { $z = $curz };
	if (!defined($a)) { $a = $cura };

	if (
		($x == $curx) &&
		($y == $cury) &&
		($z == $curz) &&
		($a == $cura) ) {
			$self->wr_debug("Don't need to move at all\n");
			return 1;
	}

	if ($x < $self->{'pnpconfig'}{'machineConfig'}{'XminLimit'}) { die("< X mimimum requested $x") };
	if ($x > $self->{'pnpconfig'}{'machineConfig'}{'XmaxLimit'}) { die("> X maximum requested $x") };

	if ($y < $self->{'pnpconfig'}{'machineConfig'}{'YminLimit'}) { die("< Y mimimum requested $y") };
	if ($y > $self->{'pnpconfig'}{'machineConfig'}{'YmaxLimit'}) { die("> Y maximum requested $y") };

	if ($z < $self->{'pnpconfig'}{'machineConfig'}{'ZminLimit'}) { die("< Z mimimum requested $z") };
	if ($z > $self->{'pnpconfig'}{'machineConfig'}{'ZmaxLimit'}) { die("> Z maximum requested $z") };

	if ($a < $self->{'pnpconfig'}{'machineConfig'}{'AminLimit'}) { die("< A mimimum requested $a") };
	if ($a > $self->{'pnpconfig'}{'machineConfig'}{'AmaxLimit'}) { die("> A maximum requested $a") };

	my $socket = $self->{'socket'};
	$self->wr_debug('{"gc":"G0 X'.$x." Y".$y." Z".$z." A".$a.'"}'."\n");
	print($socket '{"gc":"G0 X'.$x." Y".$y." Z".$z." A".$a.'"}'."\n");

	my $ds = $self->one_line;
	while (1) {
		$ds = $self->one_line;
		$self->wr_debug(Dumper $ds);

		if ($ds->{'sr'}{'stat'} == 3) {
			return;
		}
	}
}

sub moveRel {
	my $self = shift;
	my $x = shift;
	my $y = shift;
	my $z = shift;
	my $a = shift;

	my ($curx, $cury, $curz, $cura) = $self->getCurrentPos();
	$self->wr_debug("Current location is: $curx, $cury, $curz, $cura");

	$self->moveAbsTo(
			($x + $curx),
			($y + $cury),
			($z + $curz),
			($a + $cura));

	return;
}


sub getCurrentPos {
	my $self = shift;

	my $socket = $self->{'socket'};
	print($socket '{"sr":""}'."\n");
	my $response = $self->one_line();

	$self->wr_debug(Dumper $response);

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

sub one_line {
	my $self = shift;
	my $line;

	my $socket = $self->{'socket'};

	foreach my $cnt (0..9) {
		my @array = ($self->{'select'})->can_read(1);
		if ($#array >= 0) {
			$line = <$socket>;
			$self->wr_debug("got: $line");
			if ($line =~ /{"sr/) {
				if (ref($self->{'callback'}) eq "CODE") {
					my $func = $self->{'callback'};
					$func->($line);
				}
			}
			return decode_json($line);
		}
		$self->wr_debug("timeout 1s\n");
	}
	return undef;
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
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

PNP::Comms - Perl extension for blah blah blah

=head1 SYNOPSIS

  use PNP::Comms;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for PNP::Comms, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

root, E<lt>root@(none)E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by root

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
