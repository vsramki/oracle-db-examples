use IO::Socket;
use strict;

sub portConnect {

  my ($port)= @_;
  my ($sock, $accepted);

  $sock = IO::Socket::INET->new (
    LocalPort => $port,
    Proto    => 'tcp',
    Listen   => 1,
    Reuse    => 1);

  die "Could not create socket: $!\n" unless $sock;

  $accepted = $sock->accept();

  $sock->autoflush(1);

  die "Could not create socket: $!\n" unless $accepted;

  print "            ...Connection accepted!\n";
  print "____________________________________________________________\n\n";
  return $accepted;
}

sub printFromPort {
  open out_file, ">Spool.txt";
  my ($sock) = @_;
  while (<$sock>) {
     print;
     print out_file;
  }
  close out_file;
}

while (1) {
  print "\n____________________________________________________________\n";
  print "Listening...\n";
  printFromPort (portConnect (1599));
}
