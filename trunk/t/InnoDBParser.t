#!/usr/bin/perl
use strict;
use warnings FATAL => 'all';
use English qw(-no_match_vars);
use Test::More tests => 1;
use Data::Dumper;

require "../innotop";
my $innodb_parser = new InnoDBParser;

sub read_file {
   my ($filename) = @_;
   open my $fh, "<", $filename or die $OS_ERROR;
   local $INPUT_RECORD_SEPARATOR = undef;
   my $contents = <$fh>;
   close $fh;
   return $contents;
}

my %tests = (
   'innodb-status-001' => {
      IB_bp_add_pool_alloc              => '0',
      IB_bp_awe_mem_alloc               => 0,
      IB_bp_buf_free                    => '8172',
      IB_bp_buf_pool_hit_rate           => undef,
      IB_bp_buf_pool_hits               => undef,
      IB_bp_buf_pool_reads              => undef,
      IB_bp_buf_pool_size               => '8191',
      IB_bp_complete                    => 1,
      IB_bp_dict_mem_alloc              => '22888',
      IB_bp_page_creates_sec            => '0.00',
      IB_bp_page_reads_sec              => '0.00',
      IB_bp_page_writes_sec             => '0.00',
      IB_bp_pages_created               => '1',
      IB_bp_pages_modified              => '0',
      IB_bp_pages_read                  => '17',
      IB_bp_pages_total                 => '18',
      IB_bp_pages_written               => '12',
      IB_bp_reads_pending               => '0',
      IB_bp_total_mem_alloc             => '136740864',
      IB_bp_writes_pending              => '0',
      IB_bp_writes_pending_flush_list   => 0,
      IB_bp_writes_pending_lru          => 0,
      IB_bp_writes_pending_single_page  => 0,
      IB_dl_complete                    => undef,
      IB_dl_rolled_back                 => undef,
      IB_dl_timestring                  => undef,
      IB_dl_txns                        => undef,
      IB_fk_attempted_op                => undef,
      IB_fk_child_db                    => undef,
      IB_fk_child_index                 => undef,
      IB_fk_child_table                 => undef,
      IB_fk_col_name                    => undef,
      IB_fk_complete                    => undef,
      IB_fk_fk_name                     => undef,
      IB_fk_parent_col                  => undef,
      IB_fk_parent_db                   => undef,
      IB_fk_parent_index                => undef,
      IB_fk_parent_table                => undef,
      IB_fk_reason                      => undef,
      IB_fk_records                     => undef,
      IB_fk_timestring                  => undef,
      IB_fk_trigger                     => undef,
      IB_fk_txn                         => undef,
      IB_fk_type                        => undef,
      IB_got_all                        => 1,
      IB_ib_bufs_in_node_heap           => undef,
      IB_ib_complete                    => 1,
      IB_ib_free_list_len               => '0',
      IB_ib_hash_searches_s             => '0.00',
      IB_ib_hash_table_size             => undef,
      IB_ib_inserts                     => '0',
      IB_ib_merged_recs                 => '0',
      IB_ib_merges                      => '0',
      IB_ib_non_hash_searches_s         => '0.00',
      IB_ib_seg_size                    => '2',
      IB_ib_size                        => '1',
      IB_ib_used_cells                  => undef,
      IB_io_avg_bytes_s                 => '0',
      IB_io_complete                    => 1,
      IB_io_flush_type                  => 'fsync',
      IB_io_fsyncs_s                    => '0.00',
      IB_io_os_file_reads               => '28',
      IB_io_os_file_writes              => '19',
      IB_io_os_fsyncs                   => '14',
      IB_io_pending_aio_writes          => '0',
      IB_io_pending_buffer_pool_flushes => '0',
      IB_io_pending_ibuf_aio_reads      => '0',
      IB_io_pending_log_flushes         => '0',
      IB_io_pending_log_ios             => '0',
      IB_io_pending_normal_aio_reads    => '0',
      IB_io_pending_preads              => 0,
      IB_io_pending_pwrites             => 0,
      IB_io_pending_sync_ios            => '0',
      IB_io_reads_s                     => '0.00',
      IB_io_threads                     => {
         '0' => {
            event_set => 0,
            purpose   => 'insert buffer thread',
            state     => 'waiting for i/o request',
            thread    => '0'
         },
         '1' => {
            event_set => 0,
            purpose   => 'log thread',
            state     => 'waiting for i/o request',
            thread    => '1'
         },
         '2' => {
            event_set => 0,
            purpose   => 'read thread',
            state     => 'waiting for i/o request',
            thread    => '2'
         },
         '3' => {
            event_set => 0,
            purpose   => 'read thread',
            state     => 'waiting for i/o request',
            thread    => '3'
         },
         '4' => {
            event_set => 0,
            purpose   => 'read thread',
            state     => 'waiting for i/o request',
            thread    => '4'
         },
         '5' => {
            event_set => 0,
            purpose   => 'read thread',
            state     => 'waiting for i/o request',
            thread    => '5'
         },
         '6' => {
            event_set => 0,
            purpose   => 'write thread',
            state     => 'waiting for i/o request',
            thread    => '6'
         },
         '7' => {
            event_set => 0,
            purpose   => 'write thread',
            state     => 'waiting for i/o request',
            thread    => '7'
         },
         '8' => {
            event_set => 0,
            purpose   => 'write thread',
            state     => 'waiting for i/o request',
            thread    => '8'
         },
         '9' => {
            event_set => 0,
            purpose   => 'write thread',
            state     => 'waiting for i/o request',
            thread    => '9'
         }
      },
      IB_io_writes_s            => '0.00',
      IB_last_secs              => '34',
      IB_lg_complete            => 1,
      IB_lg_last_chkp           => '64909',
      IB_lg_log_flushed_to      => '64909',
      IB_lg_log_ios_done        => '15',
      IB_lg_log_ios_s           => '0.00',
      IB_lg_log_seq_no          => '64909',
      IB_lg_pending_chkp_writes => '0',
      IB_lg_pending_log_writes  => '0',
      IB_ro_complete            => 1,
      IB_ro_del_sec             => '0.00',
      IB_ro_ins_sec             => '0.00',
      IB_ro_main_thread_id      => '2808687472',
      IB_ro_main_thread_proc_no => '7809',
      IB_ro_main_thread_state   => 'waiting for server activity',
      IB_ro_n_reserved_extents  => 0,
      IB_ro_num_rows_del        => '0',
      IB_ro_num_rows_ins        => '2',
      IB_ro_num_rows_read       => '6',
      IB_ro_num_rows_upd        => '0',
      IB_ro_queries_in_queue    => '0',
      IB_ro_queries_inside      => '0',
      IB_ro_read_sec            => '0.00',
      IB_ro_read_views_open     => '1',
      IB_ro_upd_sec             => '0.00',
      IB_sm_complete            => 1,
      IB_sm_mutex_os_waits      => '0',
      IB_sm_mutex_spin_rounds   => '0',
      IB_sm_mutex_spin_waits    => '0',
      IB_sm_reservation_count   => '4',
      IB_sm_rw_excl_os_waits    => '0',
      IB_sm_rw_excl_spins       => '0',
      IB_sm_rw_shared_os_waits  => '4',
      IB_sm_rw_shared_spins     => '4',
      IB_sm_signal_count        => '4',
      IB_sm_wait_array_size     => 0,
      IB_sm_waits               => [],
      IB_timestring             => '2010-09-04 10:24:51',
      IB_tx_complete            => 0,
      IB_tx_history_list_len    => '11',
      IB_tx_is_truncated        => 0,
      IB_tx_num_lock_structs    => undef,
      IB_tx_purge_done_for      => 905,
      IB_tx_purge_undo_for      => 0,
      IB_tx_transactions        => [
         {  active_secs      => 35,
            has_read_view    => 0,
            heap_size        => '320',
            hostname         => 'localhost',
            ip               => '127.0.0.1',
            lock_structs     => '2',
            lock_wait_status => '',
            lock_wait_time   => 0,
            locks            => [
               {  db               => 'test',
                  index            => '',
                  insert_intention => 0,
                  lock_mode        => 'IX',
                  lock_type        => 'TABLE',
                  n_bits           => 0,
                  page_no          => 0,
                  space_id         => 0,
                  special          => '',
                  table            => 't',
                  txn_id           => '907',
                  waiting          => 0
               },
               {  db               => 'test',
                  index            => 'GEN_CLUST_INDEX',
                  insert_intention => 0,
                  lock_mode        => 'X',
                  lock_type        => 'RECORD',
                  n_bits           => 72,
                  page_no          => 50,
                  space_id         => 0,
                  special          => '',
                  table            => 't',
                  txn_id           => '907',
                  waiting          => 0
               },
            ],
            mysql_thread_id    => '1',
            os_thread_id       => 3067652976,
            proc_no            => 7809,
            query_id           => '29',
            query_status       => '',
            query_text         => 'show innodb status',
            row_locks          => '3',
            tables_in_use      => 0,
            tables_locked      => 0,
            thread_decl_inside => 0,
            thread_status      => '',
            txn_doesnt_see_ge  => '',
            txn_id             => 907,
            txn_sees_lt        => '',
            txn_status         => 'ACTIVE',
            undo_log_entries   => 0,
            user               => 'root'
         }
      ],
      IB_tx_trx_id_counter => 908
   }
);

foreach my $fn ( keys %tests ) {
   my $contents = read_file($fn);
   my %result   = $innodb_parser->get_status_hash($contents);
   #print Dumper \%result;
   my $expected = $tests{$fn};
   is_deeply(\%result, $expected, $fn);
}

