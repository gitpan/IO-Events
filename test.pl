BEGIN { $| = 1; print "1..2\n"; }
END {print "not ok 1\n" unless $loaded;}
use IO::Events;
$loaded = 1;
print "ok 1\n";

my $loop = IO::Events::Loop-> new();

my $coprocess = IO::Events::Fork::ReadWrite-> new(
   owner    => $loop,
   on_fork  => sub {
      $_ = <>;
      print "echo:$_\n";
      exit;
   },
   on_read => sub {
      while ( my $line = $_[0]-> readline) {
         print "ok 2\n";
         exit;
      }
   },
);

$coprocess-> write("line\n");
$SIG{ALRM} = sub{ print "not ok 2\n"; exit; };
alarm(1);
$loop-> yield while 1;
