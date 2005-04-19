my $loaded;
BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Events;
use strict;
$loaded = 1;
print "ok 1\n";

my $run = 1;
my $loop = IO::Events::Loop-> new();
$SIG{PIPE} = 'IGNORE';

sub loopy
{
	my $num = shift;
	$run = 1;
	$SIG{ALRM} = sub { $run = -1; };
	alarm(1);
	$loop-> yield while $run > 0;
	$SIG{ALRM} = undef;
	print ((( $run == 0) ? '' : 'not ') . "ok $num\n");
}

# test two processes
IO::Events::Fork::ReadWrite-> new(
	owner    => $loop,
	on_fork  => sub {
		$_ = <>;
		print "echo:$_\n";
		exit;
	},
	on_read => sub {
		while ( my $line = $_[0]-> readline) {
			$run = 0;
		}
	},
)-> write("hello, coprocess!\n");
loopy(2);

# test TCP communication
IO::Events::Socket::TCP-> new(
	owner    => $loop,
	listen   => 1,
	port     => 10000,
	on_read => sub {
		shift-> accept( 
			read   => 1,
			on_read => sub {
				while ( my $line = $_[0]-> readline) {
					$run = 0;
				}
			}
		);
	},
);

IO::Events::Socket::TCP-> new(
	owner   => $loop,
	connect => 'localhost',
	port 	=> 10000,
)-> write("hello, tcp socket!\n");

loopy(3);

# test UNIX socket communication
unlink './unix-socket';
IO::Events::Socket::UNIX-> new(
	owner    => $loop,
	listen   => './unix-socket',
	on_read => sub {
		shift-> accept(
			read   => 1,
			on_read => sub {
				while ( my $line = $_[0]-> readline) {
					$run = 0;
				}
			}
		);
	},
);

IO::Events::Socket::UNIX-> new(
	owner   => $loop,
	connect   => './unix-socket',
)-> write("hello, unix socket!\n");;

loopy(4);

unlink './unix-socket';
