#!/bin/bash

SNAP_NAME=snap-h`date +%H`
PGDATA='pool1/pgbase/9.6/data'
ZFS='/usr/sbin/zfs'
PSQL='/usr/pgsql-9.6/bin/psql'

function pg_start_backup () {
	$PSQL -U postgres << EOF
SELECT pg_start_backup('zfs_backup');
EOF
}

function pg_end_backup () {
	$PSQL -U postgres << EOF
SELECT pg_stop_backup();
EOF
}

pg_start_backup
$ZFS snapshot ${PGDATA}@${SNAP_NAME} 2> /dev/null || ($ZFS destroy ${PGDATA}@${SNAP_NAME} && $ZFS snapshot ${PGDATA}@${SNAP_NAME})
pg_end_backup
