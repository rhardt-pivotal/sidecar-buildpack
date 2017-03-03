#!/usr/bin/env bash

#http://stackoverflow.com/questions/360201/how-do-i-kill-background-processes-jobs-when-my-shell-script-exits/28333938#28333938
trap 'trap - SIGTERM && kill 0' SIGINT SIGTERM EXIT

$PWD/run_pack.sh &
PID1=$!
echo "PID1: $PID1"
echo "ran pack: "
$PWD/run_sidecar.sh &
PID2=$!
echo "PID2: $PID2"


while [[ ( -d /proc/$PID1 ) && ( -z `grep zombie /proc/$PID1/status` ) && ( -d /proc/$PID2 ) && ( -z `grep zombie /proc/$PID2/status` ) && ( ! -f $PWD/pack_dead ) && ( ! -f $PWD/sidecar_dead ) ]]; do
    sleep 1
done

echo 'Something Died.  Exiting'
if [[ ( -d /proc/$PID1 ) ]]; then
kill -9 $PID1
fi
if [[ ( -d /proc/$PID2 ) ]]; then
kill -9 $PID2
fi

exit 255

