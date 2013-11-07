#!/usr/bin/perl -w

use strict;
use warnings;
use feature qw(:5.10);
use Data::Dumper;
use DbAccess;
use Getopt::Long;
use IO::Prompt;

our $schema = undef;
our $host = undef;
our $port = undef;
our $debug = 0;
our $test = undef;

our $db;

GetOptions(
	'schema=s' => \$schema,
	'host=s' => \$host,
	'port=i' => \$port,
        'debug=i' => \$debug
);

if (not defined $schema and not defined $host and not defined $port) {
	Usage();
	exit;
}


main();

sub main {
  initialize();
  dispatch();
}

sub initialize {
  $db = DbAccess->new({DEBUG=>$debug, schema=>$schema, host=>$host, port=>$port});
  $db->db_connect();
}

sub dispatch {
  display_menu();
  while(prompt "Enter Choice: ") {
	my $choice = $_;
        exit if $choice eq 'q';
	if (defined $choice) {
	 given ($choice) {
	   $db->create_db() when ($choice  eq 'c');
	   $db->edit_contact() when ($choice eq 'e');
	   $db->delete_contact() when ($choice eq 'd');
	   $db->list_contact() when ($choice eq 'l');
	   $db->select_contact() when ($choice eq 's');
	 }
	}
  }
  display_menu();
  return;
}

sub display_menu {
  print <<DISP;
  Menu:
  ---------------------------------------
  c - create contact DB
  e - Edit (add/update contact)
  d - delete contact
  l - list contacts
  s - select a contact
  q - Exit
DISP
}

sub Usage {
print <<HELP;
$0 --schema <> --host <> --port <> [--debug <>]
Eg: $0 --schema webapps --host localhost --port 3306 --debug 1
HELP
}






