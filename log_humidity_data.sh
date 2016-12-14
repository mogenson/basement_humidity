#!/bin/sh

PHANT_PRIVATE_KEY=<copy private key here>
PHANT_PUBLIC_KEY=YGnjwvlZYqToya7DJGLp

# connect to WiFi start DHCP client
wpa_supplicant -B -Dnl80211 -iwlan0 -c/etc/wpa_supplicant.conf
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
    fi

    # wait 15 minutes
    sleep 15m

done
