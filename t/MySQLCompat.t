#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More tests => 39;

my $path;
BEGIN {
   my $pwd = `pwd`;
   chomp $pwd;
   $path = "$pwd/$0";
   $path =~ s{/[^/]+/[^/]+$}{/};
   unshift @INC, $path;
};

require "innotop";

sub dbh_for {
   my ( $version ) = @_;
   return { mysql_serverinfo => $version };
}

sub read_file {
   my ($filename) = @_;
   open my $fh, "<", $filename or die $OS_ERROR;
   local $INPUT_RECORD_SEPARATOR = undef;
   my $contents = <$fh>;
   close $fh;
   return $contents;
}

is(version_string('8.1'), '008001000', 'short version is padded');
ok(version_ge(dbh_for('9.7.0'), '9.0.0'), '9.7 is greater than 9.0');
ok(!version_ge(dbh_for('9.7.0'), '10.0.0'), '9.7 is lower than 10.0');
ok(!version_ge(dbh_for('10.0.0'), '10.0.1'), '10.0.0 is lower than 10.0.1');

is(show_master_logs_sql(dbh_for('5.7.44')), 'SHOW /*innotop*/ MASTER LOGS', 'MySQL 5.7 uses SHOW MASTER LOGS');
is(show_master_logs_sql(dbh_for('8.0.36')), 'SHOW /*innotop*/ MASTER LOGS', 'MySQL 8.0 uses SHOW MASTER LOGS');
is(show_master_logs_sql(dbh_for('8.4.0')), 'SHOW /*innotop*/ BINARY LOGS', 'MySQL 8.4 uses SHOW BINARY LOGS');
is(show_master_logs_sql(dbh_for('9.7.0')), 'SHOW /*innotop*/ BINARY LOGS', 'MySQL 9.7 uses SHOW BINARY LOGS');
is(show_master_logs_sql(dbh_for('10.0.0')), 'SHOW /*innotop*/ MASTER LOGS', 'MySQL 10 is not treated as MySQL 9');
is(show_master_logs_sql(dbh_for('10.11.0-MariaDB')), 'SHOW /*innotop*/ MASTER LOGS', 'MariaDB keeps SHOW MASTER LOGS');

is(show_master_status_sql(dbh_for('8.0.36')), 'SHOW /*innotop*/ MASTER STATUS', 'MySQL 8.0 uses SHOW MASTER STATUS');
is(show_master_status_sql(dbh_for('8.4.0')), 'SHOW /*innotop*/ BINARY LOG STATUS', 'MySQL 8.4 uses SHOW BINARY LOG STATUS');
is(show_master_status_sql(dbh_for('9.7.0')), 'SHOW /*innotop*/ BINARY LOG STATUS', 'MySQL 9.7 uses SHOW BINARY LOG STATUS');
is(show_master_status_sql(dbh_for('10.0.0')), 'SHOW /*innotop*/ MASTER STATUS', 'MySQL 10 is not treated as MySQL 9 for source status');
is(show_master_status_sql(dbh_for('10.11.0-MariaDB')), 'SHOW /*innotop*/ MASTER STATUS', 'MariaDB keeps SHOW MASTER STATUS');

is(show_slave_status_sql(dbh_for('8.0.33')), 'SHOW /*innotop*/ SLAVE STATUS', 'MySQL 8.0.33 uses SHOW SLAVE STATUS');
is(show_slave_status_sql(dbh_for('8.0.34')), 'SHOW /*innotop*/ REPLICA STATUS', 'MySQL 8.0.34 uses SHOW REPLICA STATUS');
is(show_slave_status_sql(dbh_for('9.7.0')), 'SHOW /*innotop*/ REPLICA STATUS', 'MySQL 9.7 uses SHOW REPLICA STATUS');
is(show_slave_status_sql(dbh_for('10.0.0')), 'SHOW /*innotop*/ SLAVE STATUS', 'MySQL 10 is not treated as MySQL 9 for replica status');
is(show_slave_status_sql(dbh_for('10.11.0-MariaDB')), 'SHOW /*innotop*/ SLAVE STATUS', 'MariaDB keeps SHOW SLAVE STATUS');

is(get_channels_sql(dbh_for('5.6.51')), 'select "no_channels"', 'MySQL 5.6 does not use P_S replication channels');
is(get_channels_sql(dbh_for('5.7.44')), 'select CHANNEL_NAME from performance_schema.replication_applier_status;', 'MySQL 5.7 uses P_S replication channels');
is(get_channels_sql(dbh_for('9.7.0')), 'select CHANNEL_NAME from performance_schema.replication_applier_status;', 'MySQL 9.7 uses P_S replication channels');
is(get_channels_sql(dbh_for('10.0.0')), 'select "no_channels"', 'MySQL 10 is not treated as MySQL 9 for channels');
is(get_channels_sql(dbh_for('10.11.0-MariaDB')), 'select "no_channels"', 'MariaDB does not use MySQL channel query');

my $row = normalize_replication_status({
   exec_source_log_pos    => 123,
   read_source_log_pos    => 456,
   relay_source_log_file  => 'bin.000001',
   replica_io_running     => 'Yes',
   replica_io_state       => 'Waiting',
   replica_sql_running    => 'No',
   seconds_behind_source  => 10,
   source_host            => 'source.example',
   source_log_file        => 'bin.000002',
   source_uuid            => 'uuid-1',
   source_retry_count     => 7,
});

is($row->{exec_master_log_pos}, 123, 'exec source log position maps to existing master key');
is($row->{read_master_log_pos}, 456, 'read source log position maps to existing master key');
is($row->{relay_master_log_file}, 'bin.000001', 'relay source log file maps to existing master key');
is($row->{slave_io_running}, 'Yes', 'replica I/O running maps to existing slave key');
is($row->{slave_sql_running}, 'No', 'replica SQL running maps to existing slave key');
is($row->{seconds_behind_master}, 10, 'seconds behind source maps to existing lag key');
is($row->{master_host}, 'source.example', 'source host maps to existing master host key');
ok(!exists $row->{master_retry_count}, 'unknown source fields are not wildcard-mapped');

my $existing = normalize_replication_status({ source_host => 'new.example', master_host => 'old.example' });
is($existing->{master_host}, 'old.example', 'existing legacy field is not overwritten');

my $innodb_parser = new InnoDBParser;
my %result = $innodb_parser->get_status_hash(read_file($path . 't/innodb-status-012'), undef, undef, undef, '9.7.0');
is($result{IB_timestring}, '2025-04-08 18:54:46', 'MySQL 9.7 uses modern InnoDB timestamp format');

my $deadlock_84 = { fulltext => "2025-04-08 18:54:46\n" };
ok(InnoDBParser::parse_dl_section($deadlock_84, undef, undef, undef, '8.4.0'), 'MySQL 8.4 parses modern deadlock timestamp');
is($deadlock_84->{timestring}, '2025-04-08 18:54:46', 'MySQL 8.4 deadlock timestamp is normalized');

my $deadlock_97 = { fulltext => "2025-04-08 18:54:46\n" };
ok(InnoDBParser::parse_dl_section($deadlock_97, undef, undef, undef, '9.7.0'), 'MySQL 9.7 parses modern deadlock timestamp');
is($deadlock_97->{timestring}, '2025-04-08 18:54:46', 'MySQL 9.7 deadlock timestamp is normalized');
