#!/bin/sh

DEVICE="/dev/ttyUSB0"
INTERVAL=15  # seconds
RRD="/tmp/rrd/RZ3E/thermal-EM9191/temperature.rrd"

# Create RRD if missing
if [ ! -f "$RRD" ]; then
    mkdir -p "$(dirname "$RRD")"
rrdtool create "$RRD" \
    --start now \
    --step "$INTERVAL" \
    DS:value:GAUGE:$((INTERVAL * 2)):-20:120 \
    RRA:AVERAGE:0.5:1:5760    \
    RRA:AVERAGE:0.5:5:2016    \
    RRA:AVERAGE:0.5:30:1488   \
    RRA:AVERAGE:0.5:120:2190  \
    RRA:AVERAGE:0.5:720:1825
fi

# Delete CSVs older than 7 days
find /root -maxdepth 1 -name "modem_temp_log_*.csv" -type f -mtime +7 -exec rm -f {} \;

while true; do
    DATE=$(date +%F)
    LOGFILE="/root/modem_temp_log_${DATE}.csv"
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    epoch=$(date +%s)

    [ ! -f "$LOGFILE" ] && echo "timestamp, temperature" > "$LOGFILE"

    # Query modem temperature
    temp_response=$(echo -e "AT!PCTEMP?\r" | picocom -q -b 115200 "$DEVICE" --exit-after 1000 --nolock 2>/dev/null)
    temperature=$(echo "$temp_response" | sed -n 's/.*Temperature: *\([0-9.]*\) *C.*/\1/p')

    if [ -n "$temperature" ]; then
        echo "$timestamp, $temperature" >> "$LOGFILE"
		rrdtool update "$RRD" "N:${temperature}"
    else
        echo "$timestamp, 0.00" >> "$LOGFILE"
        rrdtool update "$RRD" "N:0"
    fi

    sleep "$INTERVAL"
done
