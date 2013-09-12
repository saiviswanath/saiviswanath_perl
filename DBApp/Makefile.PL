use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
print "\nIMPORTANT!\nTo install this module you will need ....";
my $mod_path = '/home/viswanath/DBApp/lib/DbAccess.pm';
WriteMakefile(
'ABSTRACT' => 'Simple contacts application',
'NAME' => 'DBApp',
'AUTHOR' => 'SAI VISWANATH',
'LICENSE' => 'GPL License',
'VERSION_FROM' => $mod_path, # finds $VERSION
# 0 could be used, but is printed (which is confusing)
# so use ‘’ instead
'PREREQ_PM' => {
'Data::Dumper' => '2.130_02',
},
'PREREQ_PRINT' => 1,
'PM' => {
$mod_path => '$(INST_LIBDIR)/DbAccess.pm',
}
);
