#!/usr/bin/perl -w
package DbAccess;

use strict;
use warnings;
use feature qw(:5.10);
use Data::Dumper;
use DBI qw(:sql_types);
use IO::Prompt;


our $VERSION=0.1;
our $dh;

{
my $OPTIONS = {
  '_DEBUG' => 1,
  '_schema' =>  1,
  '_host' => 1,
  '_port' => 1
};

my $ATTRIB = {
  '_schema' => 'test',
  '_host' => 'localhost',
  '_port' => 3306
};

sub _option_required {
  my $opt = shift;
  $opt='_'.$opt;
  return exists $OPTIONS->{$opt};
}

sub _attrib_default {
  my $attrib = shift;
  return $ATTRIB->{$attrib};
}

sub _attrib_keys {
  return keys %$ATTRIB;
}

}

sub new {
  my($class, $opts) = @_;
  my $self;
  $self->{$_} = _attrib_default($_) for _attrib_keys();
  for (keys %$opts) {
    $self->{'_'.$_} = $opts->{$_} if _option_required($_);
  }
  bless $self, $class;
  return $self;
}

sub getSchema {
  my $self = shift;
  return $self->{_schema};
}

sub getPort {
  my $self = shift;
  return $self->{_port};
}

sub getHost {
  my $self = shift;
 return $self->{_host};
}

sub getDebug {
 my $self = shift;
  return $self->{_DEBUG};
}

sub db_connect {
  my $self = shift;
  my $dsn = 'DBI:mysql:database='.$self->getSchema().';host='.$self->getHost.';port='.$self->getPort();
  say Dumper($dsn) if $self->getDebug() eq 1;
  $dh = DBI->connect($dsn, 'webuser', 'shradha');
  $dh->{RaiseError} = 1;
  $dh->{AutoCommit} = 1;
  return;
}

sub test {
  my $self = shift;
  my $stmt = <<STMT;
  select * from Contacts
STMT
  say Dumper($stmt) if $self->getDebug() eq 1;
  my $sh = $dh->prepare($stmt);
  $sh->execute();
  say Dumper($sh->rows(). " rows are affected") if $self->getDebug() eq 1;
  my $arr = $sh->fetchall_hashref('contact_id');
  for my $row (keys %$arr) {
    my $arr1 = $arr->{$row};
    for my $col (keys %$arr1) {
      print $arr1->{$col}."  "
    }
print "\n";
  }
  return;
}

sub create_db {
 my $self = shift;
 unless(check_table_exists()) {
	create_req_db();
 }
 prompt "Do you want to delete Contacts db [Y/N]?";
  my $choice = $_;
  unless ($choice eq 'Y') {
    return;
  }
 my $stmt1 = <<STMT1;
  drop table Contacts
STMT1
 $dh->do($stmt1, undef, undef);
 create_req_db(); 
}

sub create_req_db {
  my $self = shift;
  my $stmt1 = <<STMT1;
CREATE TABLE Contacts (
contact_id int(4) not null auto_increment,
first_name varchar(32) not null default '',
last_name varchar(32) not null default '',
age int(4) not null default 0,
address varchar(128) not null default '',
city varchar(64) not null default '',
state varchar(16) not null default '',
country varchar(24) not null default '',
primary key (contact_id),
index first_name (first_name),
index last_name (last_name),
index age (age),
index state (state),
index country (country)
);
STMT1

 $dh->do($stmt1, undef, undef);
  return;
}

sub check_table_exists {
  my $self = shift;
  my $stmt1 = <<STMT1;
select t.table_name from information_schema.tables t where t.table_schema=? and t.table_name=?;
STMT1
  my $val = $dh->selectrow_arrayref($stmt1, undef, qw(webapps Contacts));
  if ($val->[0] eq 'Contacts') {
    return 1;
  }
  return 0;
}

sub get_contact_fields {
  my $self = shift;
  my $stmt1 = <<STMT1;
select t.column_name from information_schema.columns t where t.table_schema=? and t.table_name=?
STMT1
  my $col_ref = $dh->selectcol_arrayref($stmt1, undef, qw(webapps Contacts));
  return $col_ref;
}

sub list_contact {
  my $self = shift;
  my $cnt_ref = $self->get_contacts();
  my $cnt_f_ref = $self->get_contact_fields();
  printf '%-15s', $_ for @$cnt_f_ref;
  print "\n";
  say '-' x 125;
  for my $ref1 (@$cnt_ref) {
    for my $col (@$ref1) {
      printf '%-15s', $col;
    }
  print "\n";
  }
}

sub get_contacts {
  my ($self, $contact_id) = @_;
  if($contact_id) {
    my $stmt = <<STMT;
select * from Contacts where contact_id=?
STMT
return $dh->selectrow_hashref($stmt, undef, ($contact_id));
  }
  my $stmt1 = <<STMT1;
select * from Contacts
STMT1
  my $ref = $dh->selectall_arrayref($stmt1); #TODO: Check slice
  return $ref;
}

sub edit_contact {
 my $self = shift;
 $self->list_contact();
 prompt "Enter Contact id to edit [Enter N if new contact]: ";
 my $entry = $_;
 if ($entry eq 'N') {
   $self->insert_contact();
   return;
 }
 $self->update_contact($entry);
 return;
}


sub update_contact {
  my ($self, $entry) = @_;
  my $rec = $self->get_contacts($entry);
  while(prompt "Enter field name to edit:[Enter U to return to normal menu/update]: ") {
    my $field = $_;
    if ($field ne 'U') {
    unless (exists $rec->{$field}) {
      say "$field is not valid";
      next;
    }
    prompt "Enter value for $field: ";
    my $val = $_;
    $rec->{$field} = $val;
    }
    else {
     last;
    }
  }
    my $stmt = 'update Contacts set ';
    for my $key (sort keys %$rec) {
      $stmt .= $key."='".$rec->{$key}."',";
    }
    $stmt = substr($stmt, 0, -1);
    $stmt .= ' where contact_id=?';
    say Dumper($stmt) if $self->getDebug() eq 1;
    $dh->do($stmt, undef, ($entry));
    say "Updated contact id $entry";
  return;
}

sub insert_contact {
  my $self = shift;
  my %req = (first_name=>1, last_name=>1);
  say "Please fill in the details below:";
  my $cnt_f_ref = $self->get_contact_fields();
  my @cnt_f = @{$cnt_f_ref}[1..@$cnt_f_ref-1]; 
  my @userin;
  for my $col (@cnt_f) {
    prompt "Enter $col: ";
    if (exists $req{$col} and $_ eq '') {
      say "$col is required";
      redo;
    }
    push @userin, $_;
  }
  my $stmt = 'insert into Contacts('. join(',', @cnt_f) . ') values(' . join(',', ('?') x @cnt_f)  . ')';
  say Dumper ($stmt) if $self->getDebug() eq 1;
  $dh->do($stmt, undef, @userin);
  say "Record for customer id ". $dh->last_insert_id(undef, undef, 'Contacts', undef, undef) . " has been added\n";
  return;
}

sub delete_contact {
  my $self = shift;
  $self->list_contact();
  prompt "Enter contact id to delete: ";
  my $entry = $_;
  prompt "Are you sure you want to delete $entry? [Y/N]: ";
  my $entry1 = $_;
  unless ($entry1 eq 'N') {
    my $stmt = <<STMT;
delete from Contacts where contact_id=?
STMT
   $dh->do($stmt, undef, ($entry));
   say "Delete contact_id $entry";
  }
 return;
}

sub select_contact {
  my $self = shift;
  $self->field_stack();
  while(prompt "Choose field from above to search: [Enter E to end search]: ") {
  my $col = $_;
  last if $col eq 'E';
  prompt "Enter value for $col: ";
  my $val = $_;
  my $stmt = 'select * from Contacts where '. $col .' = ?';
  say Dumper($stmt) if $self->getDebug() eq 1;
  my $ref = $dh->selectall_arrayref($stmt, undef, ($val));
  say "List of contacts with $col as $val are: ";
  say '-' x 125;
  my $cnt=0;
  for my $ref1 (@$ref) {
  for my $col (@$ref1) {
  printf '%-15s', $col;
  }
  $cnt++;
  print "\n";
  }
  say '-' x 125;
  say "Total records: $cnt";
  }
  return;
}

sub field_stack {
  my $self = shift;
  my $ref = $self->get_contact_fields();
  say '-' x 20;
  for my $col (@$ref) {
   say $col;
  }
  say '-' x 20;
  return;
}

1;
