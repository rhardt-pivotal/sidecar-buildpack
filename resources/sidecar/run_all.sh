#!/usr/bin/env bash

set -e

$PWD/run_pack.sh &
PID1=$!
echo "ran pack: "
$PWD/run_sidecar.sh &
PID2=$!

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

