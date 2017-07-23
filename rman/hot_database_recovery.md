## Startup nomount
```
SQL> startup nomount
ORACLE instance started.

Total System Global Area 4999610368 bytes
Fixed Size                  2934648 bytes
Variable Size            1040189576 bytes
Database Buffers         3942645760 bytes
Redo Buffers               13840384 bytes
SQL>
```

## Find control file backup piace
```
[root@oracle-db02 nbu_scripts]# /usr/openv/netbackup/bin/bplist -C nbu-master01 -C oracle-db01 -t 4 -I -R /
/cntrl_35_1_949214039
/al_34_1_949214030
/al_33_1_949214030
/bk_31_1_949214019
/bk_32_1_949214019
/bk_30_1_949214004
/bk_29_1_949214004
/cntrl_28_1_949213746
/al_26_1_949213738
/al_27_1_949213738
/bk_24_1_949213726
/bk_25_1_949213726
/bk_23_1_949213711
/bk_22_1_949213711
/cntrl_21_1_949213643
```

## Restore Database
```
[oracle@oracle-db02 ~]$ rman target / catalog rman@rcat
RMAN> set DBID=1543010047

executing command: SET DBID
database name is "DB1" and DBID is 1543010047

RMAN>
run {
allocate channel c1 type 'sbt_tape' PARMS="SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64";
send 'NB_ORA_SERV=netbackup-master01.net.billing.ru, NB_ORA_CLIENT=oracle-db01.net.billing.ru';
restore controlfile to '/tmp/cntrl.bak' from 'cntrl_35_1_949214039';
release channel c1;
}

RMAN> run {
replicate controlfile from '/tmp/cntrl.bak';
}

RMAN> alter database mount;

run {
allocate channel c1 type 'sbt_tape' PARMS="SBT_LIBRARY=/usr/openv/netbackup/bin/libobk.so64";
send 'NB_ORA_SERV=netbackup-master01.net.billing.ru, NB_ORA_CLIENT=oracle-db01.net.billing.ru';
RESTORE DATABASE;
RECOVER DATABASE;
release channel c1;
}

RMAN> alter database open resetlogs;
```
