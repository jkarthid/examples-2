echo "==== $0 started on `date` ==== stdout"
echo "==== $0 started on `date` ==== stderr" 1>&2

DEBUG=0
if [ "$DEBUG" -gt 0 ]; then
    set -x
fi
 
RMAN_LOG_FILE=${0}.`date +%Y-%h-%a_%d-%s`
if [ -f "$RMAN_LOG_FILE" ]; then
    rm -f "$RMAN_LOG_FILE"
fi
 
echo >> $RMAN_LOG_FILE

chmod 644 $RMAN_LOG_FILE

out=/tmp/`basename $0`.stdout.$$

trap "rm -f $out" EXIT SIGHUP SIGINT SIGQUIT SIGTRAP SIGKILL SIGUSR1 SIGUSR2 SIGPIPE SIGTERM SIGSTOP

mkfifo "$out"
tee -a $RMAN_LOG_FILE < "$out" &
exec 1>&- 2>&-
exec 1>"$out" 2>&1

echo "==== $0 started on `date` ===="
echo "==== $0 $*"
echo
ORACLE_HOME=/u01/app/oracle/product/db/12.1.0.2
ORACLE_SID=db1
ORACLE_USER=oracle
ORACLE_TARGET_CONNECT_STR='/'
 
RMAN_EXECUTABLE=$ORACLE_HOME/bin/rman
RMAN_SBT_LIBRARY="/usr/openv/netbackup/bin/libobk.so64"
RMAN_CATALOG="catalog rman/123qwe@rcat"
BACKUP_SCHEDULE=""
BACKUP_TAG="hot_db_bk"
export ORACLE_HOME ORACLE_SID

BACKUP_CUSER=`id |cut -d"(" -f2 | cut -d ")" -f1`

if [ "$NB_ORA_FULL" = "1" ]; then
    echo "Full backup requested from Schedule"
    BACKUP_TYPE="INCREMENTAL LEVEL=0"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl0"
 
elif [ "$NB_ORA_INCR" = "1" ]; then
    echo "Differential incremental backup requested from Schedule"
    BACKUP_TYPE="INCREMENTAL LEVEL=1"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl1"
 
elif [ "$NB_ORA_CINC" = "1" ]; then
    echo "Cumulative incremental backup requested from Schedule"
    BACKUP_TYPE="INCREMENTAL LEVEL=1 CUMULATIVE"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl1_cinc"
 
elif [ "$BACKUP_TYPE" = "" ]; then
    echo "Manual execution - defaulting to Full backup"
    BACKUP_TYPE="INCREMENTAL LEVEL=0"
    BACKUP_TAG="${BACKUP_TAG}_inc_lvl0"
fi

echo
RMAN_SEND=""
if [ "$NB_ORA_SERV" != "" ]; then
    RMAN_SEND="NB_ORA_SERV=${NB_ORA_SERV}"
fi
if [ "$NB_ORA_CLIENT" != "" ]; then
    if [ "$RMAN_SEND" != "" ]; then
        RMAN_SEND="${RMAN_SEND},NB_ORA_CLIENT=${NB_ORA_CLIENT}"
    else
        RMAN_SEND="NB_ORA_CLIENT=${NB_ORA_CLIENT}"
    fi
fi
if [ "$NB_ORA_POLICY" != "" ]; then
    if [ "$RMAN_SEND" != "" ]; then
        RMAN_SEND="${RMAN_SEND},NB_ORA_POLICY=${NB_ORA_POLICY}"
    else
        RMAN_SEND="NB_ORA_POLICY=${NB_ORA_POLICY}"
    fi
fi
if [ "$BACKUP_SCHEDULE" != "" ]; then
    if [ "$RMAN_SEND" != "" ]; then
        RMAN_SEND="${RMAN_SEND},NB_ORA_SCHED=${BACKUP_SCHEDULE}"
    else
        RMAN_SEND="NB_ORA_SCHED=${BACKUP_SCHEDULE}"
    fi
fi

if [ "$RMAN_SEND" != "" ]; then
    RMAN_SEND="SEND '${RMAN_SEND}';"
fi

if [ "$DEBUG" -gt 0 ]; then
    ENV_COMMANDS="
    echo ----- LIST OF DECLARED VARIABLES IN SUBSHELL -----
    echo
    set | sort
    echo
    echo ----- LANGUAGE AND LOCALE -----
    echo
    locale
    echo
    echo ----- PROCESS LIST -----
    echo
    ps -ef
    echo"
else
    ENV_COMMANDS=""
fi

CMDS="
export ORACLE_HOME=$ORACLE_HOME
export ORACLE_SID=$ORACLE_SID
echo
echo ----- SUBSHELL ENV VARIABLES -----
echo
env | sort | egrep '^ORACLE_|^NB_ORA_|^RMAN_|^BACKUP_|^TNS_'
echo
$ENV_COMMANDS
echo ----- STARTING RMAN EXECUTION -----
echo
$RMAN_EXECUTABLE target $ORACLE_TARGET_CONNECT_STR $RMAN_CATALOG"

if [ $RMAN_SBT_LIBRARY != "" ]; then
    RMAN_SBT_LIBRARY_PARMS="PARMS 'SBT_LIBRARY=$RMAN_SBT_LIBRARY'"
else
    RMAN_SBT_LIBRARY_PARMS=""
fi

CMD_INPUT="<< EOF
SHOW ALL;
RUN {
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch01 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
$RMAN_SEND
BACKUP
    $BACKUP_TYPE
    SKIP INACCESSIBLE
    TAG $BACKUP_TAG
    FILESPERSET 5
    # recommended format, must end with %t
    FORMAT 'bk_%s_%p_%t'
    DATABASE;
    sql 'alter system archive log current';
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
ALLOCATE CHANNEL ch01 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
$RMAN_SEND
BACKUP
    filesperset 20
    # recommended format, must end with %t
    FORMAT 'al_%s_%p_%t'
    ARCHIVELOG ALL DELETE INPUT;
RELEASE CHANNEL ch00;
RELEASE CHANNEL ch01;
ALLOCATE CHANNEL ch00 TYPE 'SBT_TAPE' $RMAN_SBT_LIBRARY_PARMS;
$RMAN_SEND
BACKUP
    # recommended format, must end with %t
    FORMAT 'cntrl_%s_%p_%t'
    CURRENT CONTROLFILE;
RELEASE CHANNEL ch00;
}
EOF
"

if [ "$DEBUG" -gt 0 ]; then
    echo ----- LIST OF DECLARED VARIABLES IN SCRIPT -----
    echo
    set | sort
    echo
fi

echo
echo "----- SCRIPT VARIABLES -----"
echo
set | sort | egrep '^ORACLE_|^NB_ORA_|^RMAN_|^BACKUP_|^TNS_'
echo
echo "----- RMAN CMD -----"
echo
echo "$CMDS"
echo
echo "----- RMAN INPUT -----"
echo
echo "$CMD_INPUT"
echo

if [ ! -x $RMAN_EXECUTABLE ]; then
    echo "ERR: $RMAN_EXECUTABLE: required executable not found!" 1>&2
    exit 1
fi

if [ ! -f  `echo $RMAN_SBT_LIBRARY | cut -d'(' -f1`  ]; then
    echo "ERR: $RMAN_SBT_LIBRARY: required library not found!" 1>&2
    exit 1
fi

echo "----- STARTING CMDS EXECUTION -----"
echo
if [ "$BACKUP_CUSER" = "root" ]; then
    su - $ORACLE_USER -c "$CMDS $CMD_INPUT"
    RSTAT=$?
else
    /bin/sh -c "$CMDS $CMD_INPUT"
    RSTAT=$?
fi

if [ "$RSTAT" = "0" ]; then
    LOGMSG="ended successfully"
else
    LOGMSG="ended in error"
fi
 
echo
echo "==== $0 $LOGMSG on `date` ==== stdout"
echo "==== $0 $LOGMSG on `date` ==== stderr" 1>&2
echo
exit $RSTAT
