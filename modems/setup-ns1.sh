#!/bin/bash
MODEM=$"6"
#MODEM=$(mmcli -L | cut -d "/" -f6 | cut -d " " -f1 | tr -d ' ')
while [ "$MODEM" = "No" ]
do
    echo "No modem connected, waiting 10sec"
    sleep 10
    MODEM=$(mmcli -L | cut -d "/" -f6 | cut -d " " -f1 | tr -d ' ')
done

echo "using modem $MODEM"

sudo ip netns exec ns1 ip ad flu dev wwan0
IP=""
#$(ip a s wwan0 | grep -oP 'inet \K[\d.]+')

RETRIES=2
while [ "$IP" = "" ]
do
    echo "Trying to acquire IP, currently $IP"

    sudo mmcli -m $MODEM --disable
    sudo mmcli -m $MODEM --enable 
    sudo mmcli -m $MODEM --simple-connect="apn=internet"

    BEARER=$(sudo mmcli -m $MODEM | grep Bearer| cut -d "/" -f6 | cut -d " " -f1 | tr -d ' ')
    IP=$(sudo mmcli -m $MODEM --bearer=$BEARER | grep address | cut -d ":" -f2 | tr -d ' ' )
    INTERFACE=$(sudo mmcli -m $MODEM --bearer=$BEARER | grep interface | cut -d ":" -f2 | tr -d ' ' )
    sudo ip netns exec ns1 ip addr flush dev $INTERFACE
    sudo ip netns exec ns1 ip link set $INTERFACE down
    sudo ip netns exec ns1 ip r sh
    sudo ip netns exec ns1 ip a add $IP dev $INTERFACE
    sudo ip netns exec ns1 ip link set $INTERFACE up
    sudo ip netns exec ns1 ip r add 10.45.0.1 dev $INTERFACE
    sudo ip netns exec ns1 ip r add 10.45.0.0/24 dev $INTERFACE
    sudo ip netns exec ns1 ip r add default via 10.45.0.1

    if [[ "$IP" == "" ]]; then
        (( RETRIES-- ))
        if (( RETRIES == 0 )); then
            echo "Failed to obtain IP"
            exit 1
        fi
        echo "Didn't get new IP, waiting 10s to retry, $RETRIES left"
        sleep 10
    else
        echo "New IP: $IP"
    fi

done
