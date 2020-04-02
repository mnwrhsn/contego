#!/bin/bash


#To generate a random integer variable between 5 and 10 (including both), use
#echo $(( RANDOM % (10 - 5 + 1 ) + 5 ))

for ((n=1;n<5;n++))
do

    echo "===================="
    echo "Experiment No. # $n"
    echo "===================="

    pkill main_bbb
    pkill bro

    # generate a random number between 150 and 250 (in seconds)
    ATTACK_TIME=$(( RANDOM % (250 - 150 + 1 ) + 150 ))

    # interval between DoS and FS attack
    INTERVAL=$(( RANDOM % ($ATTACK_TIME * 5 - $ATTACK_TIME * 2 + 1 ) + $ATTACK_TIME * 2 ))

    echo "DoS Attack will be launched at: $ATTACK_TIME"
    echo "Interval beween DoS and FS Attack: $INTERVAL"

    echo "Removing twout.txt..."
    rm twout.txt

    echo "Removing twattack.txt from /bin..."
    rm /bin/twattack.txt

    echo "Removing BRO logs..."
    rm *.log; rm *.trace

    echo "Restore mypackets.trace..."
    cp bf_trace/mypackets.trace .

    pkill main_bbb
    pkill bro

    # initialize tripwire to clean state
    echo "Initializing and cleaning up Tripwire database..."
    printf 'Pass1234\n' | sudo tripwire --init > twinit.txt
    rm twinit.txt

    pkill main_bbb
    pkill bro

    #sleep 5

    echo "Running MODE_CHANGE binary..."
    ./main_bbb 1 $ATTACK_TIME $INTERVAL

    echo "Removing twout.txt..."
    rm twout.txt

    echo "Removing twattack.txt from /bin..."
    rm /bin/twattack.txt

    echo "Removing BRO logs..."
    rm *.log; rm *.trace

    echo "Restore mypackets.trace..."
    cp bf_trace/mypackets.trace .

    # initialize tripwire to clean state
    echo "Initializing and cleaning up Tripwire database..."
    printf 'Pass1234\n' | sudo tripwire --init > twinit.txt
    rm twinit.txt

    pkill main_bbb
    pkill bro

    #sleep 5

    echo "Running NO_MODE_CHANGE binary..."
    ./main_bbb 0 $ATTACK_TIME $INTERVAL

    sleep 5

done

echo "All the experiments completed! Congratulations!!"
