#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use Test::More;

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

sub rewrite_is {
   my ( $sql, $want_mods, $want_query, $name ) = @_;
   my ( $got_mods, $got_query ) = rewrite_for_explain($sql);
   is( $got_mods ? 1 : 0, $want_mods ? 1 : 0, "$name modifies flag" );
   is( $got_query, $want_query, "$name rewritten query" );
}

sub rewrite_is_undef {
   my ( $sql, $name ) = @_;
   my ( $got_mods, $got_query ) = rewrite_for_explain($sql);
   is( $got_mods ? 1 : 0, 0, "$name modifies flag" );
   ok( !defined $got_query, "$name is not explainable" );
}

rewrite_is(
   'SELECT 1',
   0,
   'SELECT 1',
   'plain SELECT',
);

rewrite_is(
   'WITH c AS (SELECT 1) SELECT * FROM c',
   0,
   'WITH c AS (SELECT 1) SELECT * FROM c',
   'WITH SELECT',
);

rewrite_is(
   'INSERT INTO dst SELECT * FROM src',
   1,
   'SELECT * FROM src',
   'INSERT SELECT',
);

rewrite_is(
   'REPLACE INTO dst SELECT * FROM src',
   1,
   'SELECT * FROM src',
   'REPLACE SELECT',
);

rewrite_is(
   'INSERT INTO dst WITH c AS (SELECT 1) SELECT * FROM c',
   1,
   'WITH c AS (SELECT 1) SELECT * FROM c',
   'INSERT WITH SELECT',
);

rewrite_is(
   'CREATE TEMPORARY TABLE dst AS SELECT * FROM src',
   1,
   'SELECT * FROM src',
   'CREATE TEMPORARY TABLE AS SELECT',
);

rewrite_is(
   'CREATE TABLE dst (id int) AS WITH c AS (SELECT 1) SELECT * FROM c',
   1,
   'WITH c AS (SELECT 1) SELECT * FROM c',
   'CREATE TABLE AS WITH SELECT',
);

rewrite_is(
   "INSERT INTO dst SELECT 'on duplicate key update' AS txt FROM src ON DUPLICATE KEY UPDATE txt = VALUES(txt)",
   1,
   "SELECT 'on duplicate key update' AS txt FROM src",
   'INSERT SELECT strips ON DUPLICATE KEY UPDATE',
);

rewrite_is(
   'SELECT `from` FROM src WHERE txt = "INSERT INTO x SELECT y"',
   0,
   'SELECT `from` FROM src WHERE txt = "INSERT INTO x SELECT y"',
   'quoted strings and identifiers in SELECT',
);

rewrite_is_undef(
   "INSERT INTO dst VALUES ('SELECT 1')",
   'INSERT VALUES',
);

rewrite_is_undef(
   'INSERT INTO my$select VALUES (1)',
   'identifier containing select',
);

rewrite_is_undef(
   'UPDATE dst SET a = (SELECT 1)',
   'UPDATE with subquery',
);

rewrite_is_undef(
   'DELETE FROM dst WHERE id IN (SELECT id FROM src)',
   'DELETE with subquery',
);

rewrite_is_undef(
   'WITH c AS (SELECT 1) UPDATE dst SET a = 1',
   'WITH UPDATE',
);

rewrite_is_undef(
   "/* SELECT 1 */ INSERT INTO dst VALUES ('SELECT 1')",
   'comments are ignored',
);

is(
   explain_sql_for(dbh_for('5.0.96'), 'SELECT 1', 'TRADITIONAL'),
   "EXPLAIN\nSELECT 1",
   'MySQL 5.0 uses plain EXPLAIN',
);

is(
   explain_sql_for(dbh_for('5.7.44'), 'SELECT 1', 'TRADITIONAL'),
   "EXPLAIN PARTITIONS\nSELECT 1",
   'MySQL 5.7 keeps EXPLAIN PARTITIONS',
);

is(
   explain_sql_for(dbh_for('8.0.36'), 'SELECT 1', 'TRADITIONAL'),
   "EXPLAIN FORMAT=TRADITIONAL\nSELECT 1",
   'MySQL 8.0 uses FORMAT=TRADITIONAL',
);

is(
   explain_sql_for(dbh_for('8.4.0'), 'SELECT 1', 'TRADITIONAL'),
   "EXPLAIN FORMAT=TRADITIONAL\nSELECT 1",
   'MySQL 8.4 uses FORMAT=TRADITIONAL',
);

is(
   explain_sql_for(dbh_for('9.7.0'), 'SELECT 1', 'TRADITIONAL'),
   "EXPLAIN FORMAT=TRADITIONAL\nSELECT 1",
   'MySQL 9.7 uses FORMAT=TRADITIONAL',
);

is(
   explain_sql_for(dbh_for('10.11.0-MariaDB'), 'SELECT 1', 'TRADITIONAL'),
   "EXPLAIN PARTITIONS\nSELECT 1",
   'MariaDB keeps EXPLAIN PARTITIONS',
);

is(
   explain_sql_for(dbh_for('9.7.0'), 'SELECT 1', 'JSON'),
   "EXPLAIN FORMAT=JSON\nSELECT 1",
   'MySQL 9.7 JSON EXPLAIN',
);

is(
   explain_sql_for(dbh_for('10.11.0-MariaDB'), 'SELECT 1', 'JSON'),
   "EXPLAIN FORMAT=JSON\nSELECT 1",
   'MariaDB JSON EXPLAIN',
);

is(
   explain_sql_for(dbh_for('9.7.0'), 'SELECT 1', 'TREE'),
   "EXPLAIN FORMAT=TREE\nSELECT 1",
   'MySQL 9.7 TREE EXPLAIN',
);

ok(
   !defined explain_sql_for(dbh_for('8.0.15'), 'SELECT 1', 'TREE'),
   'MySQL before 8.0.16 does not use TREE EXPLAIN',
);

ok(
   !defined explain_sql_for(dbh_for('10.11.0-MariaDB'), 'SELECT 1', 'TREE'),
   'MariaDB does not use TREE EXPLAIN',
);

is(
   explain_sql_for_optimized_query(dbh_for('9.7.0'), 'SELECT 1'),
   "EXPLAIN FORMAT=TRADITIONAL\nSELECT 1",
   'MySQL 9.7 optimized query uses FORMAT=TRADITIONAL',
);

is(
   explain_sql_for_optimized_query(dbh_for('5.7.44'), 'SELECT 1'),
   "EXPLAIN EXTENDED\nSELECT 1",
   'MySQL 5.7 optimized query keeps EXPLAIN EXTENDED',
);

is(
   explain_sql_for_optimized_query(dbh_for('10.11.0-MariaDB'), 'SELECT 1'),
   "EXPLAIN EXTENDED\nSELECT 1",
   'MariaDB optimized query keeps EXPLAIN EXTENDED',
);

done_testing();
