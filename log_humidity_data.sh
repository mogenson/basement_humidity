#!/bin/sh

PHANT_PRIVATE_KEY=<private key here>
PHANT_PUBLIC_KEY=YGnjwvlZYqToya7DJGLp

WIFI_NAME="<wifi name here>"
WIFI_PASS="<wifi pass here>"

IFTTT_URL="https://maker.ifttt.com/trigger/basement_humidity/with/key/<IFTTT key here>/?value1="

# create a wpa_supplicant.conf configuration file
printf "network={\n\tssid=\"%s\"\n\tpsk=\"%s\"\n}\n" \
    "$WIFI_NAME" "$WIFI_PASS" > wpa_supplicant.conf

# connect to WiFi start DHCP client
wpa_supplicant -B -D nl80211 -i wlan0 -c wpa_supplicant.conf
sleep 30
dhcpcd wlan0
sleep 1m

# read DHT22 sensor and post data
while true;
do
    # read temperature and humidity values
    HUMIDITY=$(cat /sys/bus/iio/devices/iio:device0/in_humidityrelative_input)
    TEMPERATURE=$(cat /sys/bus/iio/devices/iio:device0/in_temp_input)

    # check to see if they are numbers
    if [ "$HUMIDITY" -eq "$HUMIDITY" ] && [ "$TEMPERATURE" -eq "$TEMPERATURE" ];
    then

        echo humidity = $HUMIDITY
        echo temperature = $TEMPERATURE

        # post data to data.sparkfun.com (don't require certificates)
        curl -k --header "Phant-Private-Key: $PHANT_PRIVATE_KEY" \
                --data "humidity=$HUMIDITY" \
                --data "temperature=$TEMPERATURE" \
                "https://data.sparkfun.com/input/$PHANT_PUBLIC_KEY"
                
        # if humidity is over 50% send a notification through IFTTT.com
        if [ "$HUMIDITY" -ge 50000 ]
        then
            curl -X POST "$IFTTT_URL$HUMIDITY"
        fi
    fi

    # print log message to dmesg
    echo "$0: logged data at $(date)" > /dev/kmsg

    # wait 15 minutes
    sleep 15m

done
