#!/bin/bash
# set -exv
# Time warp: generate old files
# here we touch files from 1,4,2015 to 12,26,2015
# from yesterdays weirdness, we think that github gets file timestamps from the file, not server time. 
# or maybe from system time. It seems like it doesnt use its own internal server time. 
# so this script is to make old files, and test ghb



start_date="2015-01-04"
end_date="2015-12-26"
p=$PWD
current_date="$start_date"
mkdir output

po=$p/output
while [ "$(date -d "$current_date" +%Y-%m-%d)" != "$(date -d "$end_date + 1 day" +%Y-%m-%d)" ]; do
    f=$(date -d "$current_date" +%m-%d-%Y)
    touch "$po/$f.txt"
    echo "Created $f.txt"
    current_date=$(date -d "$current_date + 1 day" +%Y-%m-%d)
done
# lol I aint commenting out shit
exit



# OK this part is for doing github stuff.
# successivley warp time
timedatectl set-ntp true
systemctl start systemd-timesyncd >/dev/null 2>&1
systemctl start chronyd >/dev/null 2>&1
systemctl start ntpd >/dev/null 2>&1
sleep 1
echo "Initiating time warp"
if [[ $EUID -ne 0 ]]; then
    echo "Run as root"
    exit 1
fi

# Disable NTP
systemctl stop systemd-timesyncd >/dev/null 2>&1
systemctl stop chronyd >/dev/null 2>&1
systemctl stop ntpd >/dev/null 2>&1
timedatectl set-ntp false

# Capture REAL time and epoch
REAL_TS=$(date +"%Y-%m-%d %H:%M:%S")
REAL_EPOCH=$(date +%s)

echo "Real time saved: $REAL_TS ($REAL_EPOCH)"
echo "Starting 30-day simulation..."

# Simulate 30 days, each lasting 60 seconds
for ((i=1; i<=30; i++)); do
    FAKE_EPOCH=$(( REAL_EPOCH + i*86400 ))
    FAKE_TIME=$(date -d "@$FAKE_EPOCH" "+%Y-%m-%d %H:%M:%S")

    echo "[$i/30] Setting fake date: $FAKE_TIME"
    date -s "$FAKE_TIME"

    sleep 60
done

echo "Restoring real time: $REAL_TS"
date -s "$REAL_TS"

# Re-enable NTP
timedatectl set-ntp true
systemctl start systemd-timesyncd >/dev/null 2>&1
systemctl start chronyd >/dev/null 2>&1
systemctl start ntpd >/dev/null 2>&1
echo "Time warp complete."


