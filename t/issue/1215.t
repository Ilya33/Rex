use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;
use Rex::Commands;
use Rex::Commands::Run;
use Rex::Commands::SCM;

use constant TEST_FILENAMES =>
  [ 'testfile', 'Grüßen', 'Ёж', 'こんにちは', '你好' ];

my $svn_path      = can_run('svn');
my $svnadmin_path = can_run('svnadmin');

if ( !defined($svn_path) || !defined($svnadmin_path) ) {
  plan skip_all =>
    'Subversion client not found. Please install subversion client for this test.';
  return;
}

my $test_dir = tempdir( CLEANUP => 1 );
my $out      = run("$svnadmin_path create $test_dir/testrepo");

if ( 0 != $? ) {
  diag($out);
  plan skip_all => "Can't create svn repository for test";
  return;
}

mkdir("$test_dir/testfiles");

for my $testfile ( @{ +TEST_FILENAMES } ) {
  my $fh;
  if ( !open( $fh, '>', "$test_dir/testfiles/$testfile" ) ) {
    plan skip_all => "Can't prepare test files for svn: $!";
    return;
  }
  close($fh);

  my $out = run(
    "$svn_path import $testfile file://$test_dir/testrepo/$testfile -m 'Testing'",
    cwd => "$test_dir/testfiles/"
  );
  if ( 0 != $? ) {
    diag($out);
    plan skip_all => "Can't add files to test subversion repository";
    return;
  }
}

plan tests => 1;

set
  repository => 'testrepo',
  url        => "file://$test_dir/testrepo",
  type       => 'subversion';

my $success = eval {
  checkout( 'testrepo', path => "$test_dir/checkout_dir" );
  1;
};

is( $success, 1,
  "Failed to clone subversion repository that contains filenames in UTF-8." );
