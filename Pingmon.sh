
#!/bin/bash

# Set the path to the file containing the list of hosts to ping
HOSTS_FILE="path/to/hostfile/hosts.txt"

# Set the Telegram chat ID and bot token
TELEGRAM_CHAT_ID="<CHAT_ID"
TELEGRAM_BOT_TOKEN="<TOKEN>"

#Create an associative array to store each hosts prior status.. To order to prevent repeated pings while a host is down, it will be used to store host status.
declare -A PREV_STATUS

while true
do
        # Ping the hosts in the file hosts.txt
        while read -r HOST || [[ -n "$HOST" ]]
        do
                # Ping the host with 5 packets and get the packet loss percentage
                PACKET_LOSS=$(ping -c 5 $HOST | grep 'packet loss' | awk '{print $6}' | awk -F '%' '{print $1}')

                # Check if the previous status of the host is available in the array
                if [ ${PREV_STATUS[$HOST]+_} ]
                then
                    # Get the previous status of the host
                    PREV_STATUS_HOST=${PREV_STATUS[$HOST]}
                else
                    #Assume the host is down if the prior status is unavailable.
                    PREV_STATUS_HOST=0
                fi

                if [ $PACKET_LOSS -eq 100 ]
                then
                    # If all packets are lost, set the current status to 0
                    CURRENT_STATUS=0
                    # If the current status is different from the previous status, log a message and send an alert
                    if [ $CURRENT_STATUS -ne $PREV_STATUS_HOST ]
                    then
                        echo "$(date): Device not reachable: $HOST"
                        MESSAGE="Device not reachable: $HOST"
                        curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"
                    fi
                elif [ $PACKET_LOSS -gt 0 ]
                then
                    # If some packets are lost, set the current status to 0
                    CURRENT_STATUS=0
                    # If the current status is different from the previous status, log a message and send an alert
                    if [ $CURRENT_STATUS -ne $PREV_STATUS_HOST ]
                    then
                        echo "$(date): Packet loss to $HOST: $PACKET_LOSS%"
                        MESSAGE="Packet loss to $HOST: $PACKET_LOSS%"
                        curl -s -X POST https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage -d chat_id=$TELEGRAM_CHAT_ID -d text="$MESSAGE"
                    fi
                else
                    # If there is no packet loss, set the current status to 1
                    CURRENT_STATUS=1
                    # If the current status is different from the previous status, log a message and send an alert
                    if [ $CURRENT_STATUS -ne $PREV_STATUS_HOST ]
                    then
                        echo "$(date): Ping successful for $HOST"
                    fi
                fi

                # Update the previous status of the host in the array
                PREV_STATUS[$HOST]=$CURRENT_STATUS

        done < "$HOSTS_FILE"

        # Sleep for 3 minutes before pinging the hosts again 
        sleep 180
done
