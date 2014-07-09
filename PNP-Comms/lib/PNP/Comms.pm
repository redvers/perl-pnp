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

sub BUILD {
	my $self = shift;
	$self->{'socket'} = IO::Socket::INET->new(PeerAddr => '127.0.0.1:5353') || die;
	$self->{'select'} = IO::Select->new();
	($self->{'select'})->add($self->{'socket'});

	open(FILE_FD, "pnp.conf") || die("No pnp.conf");
	my @tmp = <FILE_FD>;
	$self->{'pnpconfig'} = Load join("", @tmp);

}

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

	if ($response->{'f'}[1] != 0) {
	$self->wr_debug(Dumper $response);
		die("Command failed");
	}

	$response = $self->one_line();

	return( $response->{'sr'}{'posx'},
		$response->{'sr'}{'posy'},
		$response->{'sr'}{'posz'},
		$response->{'sr'}{'posa'});

}

sub one_line {
	my $self = shift;
	my $line;

	my $socket = $self->{'socket'};

	foreach my $cnt (0..9) {
		my @array = ($self->{'select'})->can_read(1);
		if ($#array >= 0) {
			$line = <$socket>;
			if ($line =~ /^\r{"sr/) {
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
