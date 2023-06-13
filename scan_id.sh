#!/bin/bash

#project 		:okada charging station
#description	:this script will read nfc serial number and operate the charging cabinet
#author			:jun dychitan (Dychitan Electronics Corp)
#date 			:12012021
#version 		:2.1

#date 			:06072023
#version 		:2.2
#Rev History	: 1. disable charging monitoring				
#=========================================================================================

project_dir=/projects/charger
nfc_file=/var/txtalert/nfc.id
employee_list=/projects/charger/employee_list
charging_list=/projects/charger/charging_list
slot_list=/projects/charger/slot_list
config_file_dir=/projects/config_file
sensor_dir=/projects/txtalert/config/sensor_status
light_dir=/projects/charger/pixel_led/light
blink_dir=/projects/charger/pixel_led/blink
kbd_file=/var/txtalert/kbd
filename=$nfc_file
analog_dir=/tmp/txtalert/analog 
no_charge_list=$project_dir/no_charge_list

#door sensor
open=0
close=1
#solenoid lock
lock=0
unlock=1

open_door_timeout=10 	#timeout for door opening
close_door_timeout=20 	#timeout for door closing
door_lock_timeout=30	#time delay until lock

#serial port
serial_port=/dev/ttyAMA0
#serial_port=/dev/ttyS0 # b8:27:eb:f6:39:65

#led color
RED=0xFF0000
GREEN=0x00FF00
BLUE=0xFF
WHITE=0xFFFFFF
#ORANGE=0xFFFF00
#ORANGE=0xFF
ORANGE=0

#charging parameters
#harging_delay=45
charging_delay=30
charge_timeout=14400	#no. of seconds allowed to charge; 14400 = 4 hrs

timestamp(){
	date +"%Y%m%d%H%M%S"
}
map_sensor(){ #map slot to sensor address
	case $1 in
		0)
			echo "1_0"
			;;
		1)
			echo "1_1"
			;;
		2)
			echo "1_2"
			;;
		3)
			echo "1_3"
			;;
		4)
			echo "1_4"
			;;
		9)
			echo "2_0"
			;;
		8)
			echo "2_1"
			;;
		7)
			echo "2_2"
			;;
		6)
			echo "2_3"
			;;
		5)
			echo "2_4"
			;;
		10)
			echo "4_0"
			;;
		11)
			echo "4_1"
			;;
		12)
			echo "4_2"
			;;
		13)
			echo "4_3"
			;;
		14)
			echo "4_4"
			;;
		19)
			echo "5_0"
			;;
		18)
			echo "5_1"
			;;
		17)
			echo "5_2"
			;;
		16)
			echo "5_3"
			;;
		15)
			echo "5_4"
			;;			
	esac
}
map_relay(){ #map slot to relay address
	case $1 in
		0)
			echo "1_0"
			;;
		1)
			echo "2_0"
			;;
		2)
			echo "3_0"
			;;
		3)
			echo "4_0"
			;;
		4)
			echo "5_0"
			;;
		9)
			echo "1_1"
			;;
		8)
			echo "2_1"
			;;
		7)
			echo "3_1"
			;;
		6)
			echo "4_1"
			;;
		5)
			echo "5_1"
			;;
		10)
			echo "1_2"
			;;
		11)
			echo "2_2"
			;;
		12)
			echo "3_2"
			;;
		13)
			echo "4_2"
			;;
		14)
			echo "5_2"
			;;
		19)
			echo "1_3"
			;;
		18)
			echo "2_3"
			;;
		17)
			echo "3_3"
			;;
		16)
			echo "4_3"
			;;
		15)
			echo "5_3"
			;;			
	esac
}
map_analog(){ #map slot to Analog input

	case $1 in
		0) 
			echo "A0"
			;;
		1) 
			echo "A0"
			;;
		2) 
			echo "A0"
			;;			
		3) 
			echo "A0"
			;;			
		4)
			echo "A0"
			;;									
		5)
			echo "A3"
			;;	
		6)
			echo "A3"
			;;			
		7)
			echo "A3"
			;;				
		8)
			echo "A3"
			;;				
		9)
			echo "A3"
			;;				
		10)
			echo "A2"
			;;				
		11)
			echo "A2"
			;;				
		12)
			echo "A2"
			;;				
		13)
			echo "A2"
			;;				
		14)
			echo "A2"
			;;				
		15)
			echo "A1"
			;;				
		16)
			echo "A1"
			;;				
		17)
			echo "A1"
			;;				
		18)
			echo "A1"
			;;				
		19)
			echo "A1"
			;;


	# b8:27:eb:f6:39:65
	# case $1 in
	# 	0) 
	# 		echo "A0"
	# 		;;
	# 	9) 
	# 		echo "A0"
	# 		;;
	# 	10) 
	# 		echo "A0"
	# 		;;			
	# 	19) 
	# 		echo "A0"
	# 		;;			
	# 	15)
	# 		echo "A1"
	# 		;;									
	# 	16)
	# 		echo "A1"
	# 		;;	
	# 	17)
	# 		echo "A1"
	# 		;;			
	# 	18)
	# 		echo "A1"
	# 		;;				
	# 	11)
	# 		echo "A2"
	# 		;;				
	# 	12)
	# 		echo "A2"
	# 		;;				
	# 	13)
	# 		echo "A2"
	# 		;;				
	# 	14)
	# 		echo "A2"
	# 		;;				
	# 	5)
	# 		echo "A3"
	# 		;;				
	# 	6)
	# 		echo "A3"
	# 		;;				
	# 	7)
	# 		echo "A3"
	# 		;;				
	# 	8)
	# 		echo "A3"
	# 		;;				
	# 	1)
	# 		echo "A4"
	# 		;;				
	# 	2)
	# 		echo "A4"
	# 		;;				
	# 	3)
	# 		echo "A4"
	# 		;;				
	# 	4)
	# 		echo "A4"
	# 		;;
	esac
}

read_door_status(){
	slot=$1
	sensor=$(map_sensor $slot)
	bit=$(cat $sensor_dir/$sensor |awk -F, '{print $2}')
	#echo $sensor_name
	#echo $bit
	if [ $bit -eq $open ]; then
		echo "door opened"
	else
		echo "door closed"
	fi	
}

wait_for_door_event(){
	slot=$1
	timeout=$2	
	inotifywait -t $timeout -q -e close_write $sensor_dir  | while read res
	do
		#echo $res
		dir=$(echo $res |awk '{print $1}')$(echo $res |awk '{print $3}')
		sensor_file_name=$(echo $res |awk '{print $3}')
		event=$(echo $res |awk '{print $2}')
		#echo $sensor_file_name
		sensor=$(map_sensor $slot)
		if [ "$sensor_file_name" == "$sensor" ]; then
			if [ "$event" != "DELETE" ];
			then
				#echo "file changed: $dir"
				sensor_name=$(cat $dir |awk -F, '{print $1}')
				bit=$(cat $dir |awk -F, '{print $2}')
				#echo $sensor_name
				#echo $bit
				if [ $bit -eq $open ]; then
					echo "door opened"
				else
					echo "door closed"
				fi				
			fi
			break
		fi
	done
}
control_relay(){
	addr_bit=$(map_relay $1)
	addr=$(echo $addr_bit |awk -F_ '{print $1}')
	bit=$(echo $addr_bit |awk -F_ '{print $2}')
	#generate random filename for can command
	file_name=$(cat /dev/urandom | tr -dc "[:alpha:]" | head -c 8)
	
	#send command to can
	if [ ! -d /var/txtalert/command ];
	then
		mkdir /var/txtalert/command
	fi
	echo -e "SID_H:04\r\nSID_L:$addr\r\nD0:FF\r\nD1:01\r\nD2:$bit\r\nD3:1\r\nD4:$2">/var/txtalert/command/$file_name
	echo -e "SID_H:04\r\nSID_L:$addr\r\nD0:FF\r\nD1:01\r\nD2:$bit\r\nD3:1\r\nD4:$2"
}
control_relay_delay(){
	addr_bit=$(map_relay $1)
	addr=$(echo $addr_bit |awk -F_ '{print $1}')
	bit=$(echo $addr_bit |awk -F_ '{print $2}')
	#generate random filename for can command
	file_name=$(cat /dev/urandom | tr -dc "[:alpha:]" | head -c 8)
	
	#send command to can
	if [ ! -d /var/txtalert/command ];
	then
		mkdir /var/txtalert/command
	fi
	echo -e "SID_H:04\r\nSID_L:$addr\r\nD0:FF\r\nD1:01\r\nD2:$bit\r\nD3:2\r\nD4:$2">/var/txtalert/command/$file_name
	echo -e "SID_H:04\r\nSID_L:$addr\r\nD0:FF\r\nD1:01\r\nD2:$bit\r\nD3:2\r\nD4:$2"
}
refresh_led(){
	echo "allleds=0"> $serial_port
	for d in {0..19} ; do
		#echo "$d"
		#addr=$(basename "$d")
		addr=$blink_dir/$d
		_addr=$(basename $addr)
		if [ -f $addr ]; then
			#echo $addr
			value=$(cat "$addr")
			#echo $value			
			#echo $_addr
			echo "setblink=$_addr,$value"> $serial_port
			sleep 0.01
		else 
			echo "setblink=$_addr,0"> $serial_port						
			echo "0">$blink_dir/$d
			sleep 0.01
		fi
	done

	#for d in /projects/charger/pixel_led/light/* ; do
	for d in {0..19} ; do
		#echo "$d"
		#addr=$(basename "$d")
		addr=$light_dir/$d
		_addr=$(basename $addr)
		if [ -f $addr ]; then
			#echo $addr
			value=$(cat "$addr")
			#echo $_addr
			#echo $value
			echo "setled=$_addr,$value"> $serial_port
			sleep 0.01
		else 
			echo "setled=$_addr,0x00FF00"> $serial_port			
			echo "0x00FF00">$light_dir/$d
			sleep 0.01		
		fi
	done
}
lightup_led(){ #params: 1 slot 2 color 3 blink
	echo "allleds=0"> $serial_port
	sleep 0.1
	echo "setblink=$1,$3"> $serial_port
	sleep 0.1
	echo "setled=$1,$2"> $serial_port
	sleep 0.1
}
save_led(){
	echo "$3"> $blink_dir/$1
	sleep 0.1
	echo "$2"> $light_dir/$1
	sleep 0.1
	refresh_led
}
wait_to_plug_charger_event(){
	#echo "wait to plug charger"
	end=$((SECONDS+$charging_delay))
	analog_port=$1
	initial_current=$(cat $analog_dir/$analog_port)
	initial_current=$((initial_current+10))
	#echo "initial current:" $initial_current
	#echo "charging current:" $charging_current
	while [ $SECONDS -lt $end ]; do
		# Do what you want.\
		charging_current=$(cat /tmp/txtalert/analog/$analog_port)
		if [ $charging_current -gt $initial_current ]; then
			echo  "charging"
			exit
		fi
		sleep 1
	done
	#echo "not charging"
}
re_check_if_charging(){
	analog_port=$1
	charging_current=$2
	charging_current=$((charging_current-2))
	final_current=$(cat $analog_dir//$analog_port)
	if [ $final_current -lt $charging_current ]; then
		echo "not charging"
	else 
		echo "charging"
	fi  
}

stty -F $serial_port 9600 -opost
echo "color"> $serial_port

sleep 5
refresh_led

while inotifywait -q -e modify $filename >/dev/null; 
do
	#echo "file is changed"
	nfc_id=$(cat $nfc_file)
	#reverse the order of the scanned nfc id
	nfc_id_rev=$(echo $nfc_id|fold -w2|tac|tr -d '\n')
	#convert to decimal value
	nfc_id=$(( 16#$nfc_id_rev ))
	echo $nfc_id
	employee=$(grep -w $nfc_id $employee_list)
	#echo $employee
	if [ $? -eq 0 ]; then
		IFS=',' read -ra employee_id <<< "$employee"	
        emp_id=${employee_id[1]}
        _designation=${employee_id[2]}
        designation=$(echo $_designation|tr -d '\r')
        echo "designation: *"$designation"*"
		if [ "$designation" == "supervisor" ]; then #supervisor
			echo "fire"> $serial_port
			#read -t 1 -n 10000 discard #discard buffer before reading
			#read -t 5 -p "you are supervisor.. select door to unlock: " -a slot
			kbd_event=$(inotifywait -t 30 -q -e modify $kbd_file)
			if [ ${#kbd_event} -gt 0 ];then
				slot=$(cat $kbd_file)
				re='^[0-9]+$'
				if [[ $slot =~ $re ]] ; then
					if [ $slot -ge 0 -a $slot -le 19 ];then
						echo "slot selected: $slot"
						rm $no_charge_list/$slot
						selected=$(grep -w "slot $slot" $charging_list)
						if [ $? -eq 0 ]; then #slot is in list
							IFS=',' read -ra id <<< "$selected"
							echo ${id[2]}
							echo "unlocking slot no.: $slot"
							#unlock door and wait until door is opened
							lightup_led $slot $WHITE 1
							control_relay_delay $slot $door_lock_timeout							
							door_status=$(wait_for_door_event $slot $open_door_timeout)
							echo $door_status
							if [ "$door_status" == "door opened" ]; then
								sed -i "/${id[2]}/d" $charging_list

								lightup_led $slot $GREEN 1															
								#control_relay $slot $lock
								door_status=$(wait_for_door_event $slot $close_door_timeout)
								echo $door_status
								if [ "$door_status" == "door closed" ]; then
									control_relay $slot $lock
									save_led $slot $GREEN 0
								else #wait indefinetely if door not closed within prescribed time				
									lightup_led $slot $WHITE 1
									while [ 1 ];
									do
										door_status=$(wait_for_door_event $slot 0)
										echo $door_status
										if [ "$door_status" == "door closed" ]; then
											control_relay $slot $lock
											save_led $slot $GREEN 0
											echo "door closed"
											break
										fi
									done
								fi									
								
							else
								echo "not opened"
								refresh_led
								control_relay $slot $lock
							fi
						else #slot seletected not in list
							echo "slot not occupied..opening it anyway"
							lightup_led $slot $WHITE 1
							control_relay_delay $slot $door_lock_timeout							
							door_status=$(wait_for_door_event $slot $open_door_timeout)
							echo $door_status
							if [ "$door_status" == "door opened" ]; then
								lightup_led $slot $GREEN 1															
								#control_relay $slot $lock
								door_status=$(wait_for_door_event $slot $close_door_timeout)
								echo $door_status
								if [ "$door_status" == "door closed" ]; then	
									control_relay $slot $lock
									save_led $slot $GREEN 0
								else
									lightup_led $slot $WHITE 1
									while [ 1 ];
									do
										door_status=$(wait_for_door_event $slot 0)
										echo $door_status
										if [ "$door_status" == "door closed" ]; then
											control_relay $slot $lock
											refresh_led
											echo "door closed"
											break
										fi
									done								
								fi
							else
								echo "not opened"
								refresh_led
								control_relay $slot $lock							
							fi
						fi
					else
						refresh_led
						echo "invalid slot seletected.."
					fi	
				else
					refresh_led
					echo "invalid selection.."
				fi
			else
				refresh_led
				echo
				echo "no doors selected"
			fi
		else #employee
			charging_employee=$(grep -w $nfc_id $charging_list)
			result=$?
			#echo $result
			if [ $result -eq 1 ]; then #inbound
				echo "look for slot available"	
				slot_found=0
				for i in {0..19}
				do
					slot_avail=$(grep -w "slot $i" $charging_list)
					if [ $? -eq 1 ]; then # slot is not in list, so its available						
						slot=$i
						analog_port=$(map_analog $slot)
						echo "Analog Port: $analog_port"
						echo "available slot# $slot"
						initial_current=$(cat $analog_dir/$analog_port)
						echo "initial_current: $initial_current"							
						slot_found=1
						lightup_led $slot $WHITE 0				
						#unlock door and wait until door is opened						
						control_relay_delay $slot $door_lock_timeout #unlock then returns to lock for pre determined time
						door_status=$(wait_for_door_event $slot $open_door_timeout)
						echo $door_status
						if [ "$door_status" == "door opened" ]; then
							#echo "door_opened"
							#check if phone is plugged to charger and is charging
							lightup_led $slot $WHITE 1
							echo $SECONDS
#	uncomment if charging monitoring is needed						charging_state=$(wait_to_plug_charger_event $analog_port) #check if phone is plugged to charger
#	uncomment if charging monitoring is needed						echo $SECONDS
#	uncomment if charging monitoring is needed						echo $charging_state
							charging_state="charging" # comment this when charging monitoring is needed
							if [ "$charging_state" == "charging" ]; then
								lightup_led $slot $RED 1
								initial_current=$(cat $analog_dir/$analog_port) #get the charging current																				
							else 
								lightup_led $slot $GREEN 1
								echo "not charging... employee not added"
							fi							
							
							door_status=$(read_door_status $slot)
							echo $door_status
							if [ "$door_status" != "door closed" ]; then
								echo "wait for door closing"
								door_status=$(wait_for_door_event $slot $close_door_timeout)
								echo $door_status
							fi
							if [ "$door_status" == "door closed" ]; then
								control_relay $slot $lock
								if [ "$charging_state" == "charging" ]; then
#	uncomment if charging monitoring is needed									charging_state=$(re_check_if_charging $analog_port $initial_current)
									charging_state="charging" # comment this if charging monitoring is needed
									if [ "$charging_state" == "charging" ]; then
										echo "$nfc_id,$(timestamp),slot $i">> $charging_list
										echo "employee added to charging list"	
										save_led $slot $RED 0
										#remove the slot not charging counter if the slot is able to charge
										if [ -f $no_charge_list/$slot ]; then
											rm $no_charge_list/$slot
										fi
									else 
										#phone removed before closing
										#unlcok door and wait until closed
										lightup_led $slot $GREEN1 1 #blink green to indicate waiting to be closed
										control_relay_delay $slot $door_lock_timeout
										door_status=$(read_door_status $slot)
										echo $door_status
										if [ "$door_status" != "door closed" ]; then
											echo "wait for door closing"
											door_status=$(wait_for_door_event $slot $close_door_timeout)
											echo $door_status
										fi
										if [ "$door_status" == "door closed" ]; then
											control_relay $slot $lock
											save_led $slot $GREEN 0 #set to solid green to indicate vacant slot
										else 
											#wait if door not closed within prescribed time				
											lightup_led $slot $ORANGE 1
											control_relay $slot $lock
											door_status=$(wait_for_door_event $slot 5)
											echo $door_status
											if [ "$door_status" == "door closed" ]; then
												save_led $slot $GREEN 0
											else 
												echo "door sensor not detected"
												#lightup_led $slot $ORANGE 0
												save_led $slot $ORANGE 0
												echo "0,$(timestamp),slot $i">> $charging_list #blacklist this slot because sensor is not working
											fi
										fi
									fi
								else
									#not charging 
									#if still not charging for next 5 tries, it will blacklist this door
									if [ ! -d $no_charge_list ]; then
										mkdir $no_charge_list
									fi
									if [ -f $no_charge_list/$slot ]; then
										_value=$(cat $no_charge_list/$slot)
										((_value+=1))
										if [ $_value -gt 5 ]; then
											rm $no_charge_list/$slot
											#blacklist this slot if not charging more than 5 times
											echo "0,$(timestamp),slot $i">> $charging_list
											save_led $slot $ORANGE 0
										else 
											#if not, save the current tries
											echo $_value>$no_charge_list/$slot
											save_led $slot $GREEN 0
										fi
									else
										echo "1">$no_charge_list/$slot
										save_led $slot $GREEN 0
									fi									
								fi
							else #wait if door not closed within prescribed time				
								lightup_led $slot $ORANGE 1
								control_relay $slot $lock
								door_status=$(wait_for_door_event $slot 5)
								echo $door_status
								if [ "$door_status" == "door closed" ]; then
									control_relay $slot $lock
									if [ "$charging_state" == "charging" ]; then
#	uncomment if charging monitoring is needed									charging_state=$(re_check_if_charging $analog_port $initial_current)
										charging_state="charging" # comment this if charging monitoring is needed																				
										if [ "$charging_state" == "charging" ]; then
											echo "${employee_id[1]},$(timestamp),slot $i">> $charging_list
											echo "employee added to charging list"	
											save_led $slot $RED 0
										else 
											#phone removed before closing
											#unlcok door and wait until closed
											lightup_led $slot $GREEN1 1 #blink green to indicate waiting to be closed
											control_relay_delay $slot $door_lock_timeout
											door_status=$(wait_for_door_event $slot $close_door_timeout)
											if [ "$door_status" == "door closed" ]; then
												control_relay $slot $lock
												save_led $slot $GREEN 0 #set to solid green to indicate vacant slot
											else 
												#wait if door not closed within prescribed time				
												lightup_led $slot $ORANGE 1
												control_relay $slot $lock
												door_status=$(wait_for_door_event $slot 5)
												echo $door_status
												if [ "$door_status" == "door closed" ]; then
													save_led $slot $GREEN 0
												else 
													echo "door sensor not detected"
													#lightup_led $slot $ORANGE 0
													save_led $slot $ORANGE 0
													echo "0,$(timestamp),slot $i">> $charging_list #blacklist this slot because sensor is not working
												fi
											fi
										fi
									else 
										#not charging 
										#if still not charging for next 5 tries, it will blacklist this door
										if [ ! -d $no_charge_list ]; then
											mkdir $no_charge_list
										fi
										if [ -f $no_charge_list/$slot ]; then
											_value=$(cat $no_charge_list/$slot)
											((_value+=1))
											if [ $_value -gt 5 ]; then
												rm $no_charge_list/$slot
												#blacklist this slot if not charging more than 5 times
												echo "0,$(timestamp),slot $i">> $charging_list
												save_led $slot $ORANGE 0
											else 
												#if not, save the current tries
												echo $_value>$no_charge_list/$slot
												save_led $slot $GREEN 0
											fi
										else
											echo "1">$no_charge_list/$slot
											save_led $slot $GREEN 0
										fi
									fi
								else 
									echo "door sensor not detected"
									#lightup_led $slot $ORANGE 0
									save_led $slot $ORANGE 0
									echo "0,$(timestamp),slot $i">> $charging_list #blacklist this slot because sensor is not working
								fi
							fi																													
						else
							echo "not opened"
							refresh_led
							control_relay $slot $lock
							
						fi
						echo "done"	
						break
					fi
				done
				if [ $slot_found -eq 0 ]; then
					refresh_led
					echo "no slot available..."
				fi
			else #outbound
				echo "existing.. will delete from list"
				IFS=',' read -ra employee_id <<< "$charging_employee"
				echo "employee id: ${employee_id[0]}"
				echo "datetime   : ${employee_id[1]}"
				IFS=' ' read -ra slot <<< "${employee_id[2]}"
				slot=${slot[1]}
				echo "slot no    : $slot"
				seconds1=$(date --date "$(echo "${employee_id[1]}" | sed -nr 's/(....)(..)(..)(..)(..)(..)/\1-\2-\3 \4:\5:\6/p')" +%s)
				seconds2=$(date --date "$(echo "$(timestamp)" | sed -nr 's/(....)(..)(..)(..)(..)(..)/\1-\2-\3 \4:\5:\6/p')" +%s)
				delta=$((seconds2 - seconds1))
				echo "$delta seconds" 
				if [ $delta -gt $charge_timeout ]; then 
					#charging timed out 
					#will not open the door, instead blue light will blink for 5 seconds and stay blue after.
					lightup_led $slot $BLUE 1
					sleep 5
					save_led $slot $BLUE 0
				else 				
					lightup_led $slot $WHITE 1				
					#unlock door and wait until door is opened
					control_relay_delay $slot $door_lock_timeout
					door_status=$(wait_for_door_event $slot $open_door_timeout)
					echo $door_status
					if [ "$door_status" == "door opened" ]; then
						lightup_led $slot $GREEN 1
						echo "door_opened"
						sed -i "/$nfc_id/d" $charging_list #remove employee from charging list
						#now lock the door and wait till closed
						door_status=$(wait_for_door_event $slot $close_door_timeout)
						echo $door_status
						if [ "$door_status" == "door closed" ]; then
							echo "door_closed"	
							control_relay $slot $lock
							save_led $slot $GREEN 0
							echo "door_closed"
						else #wait indefinetely if door not closed within prescribed time				
							echo "not closed... wait until closed"
							lightup_led $slot $ORANGE 1
							control_relay $slot $lock
							while [ 1 ];
							do
								door_status=$(wait_for_door_event $slot 5)
								echo $door_status
								if [ "$door_status" == "door closed" ]; then
									save_led $slot $GREEN 0
									echo "door closed"
									break
								else 
									echo "door sensor not detected"
									lightup_led $slot $ORANGE 0
									save_led $slot $ORANGE 0
									echo "0,$(timestamp),slot $i">> $charging_list #blacklist this slot because sensor is not working
									break
								fi
							done
						fi							
					else
						echo "not opened"
						refresh_led
						control_relay $slot $lock
					fi				
					echo "done"	
				fi
			fi
		fi
	else
		echo "employee not found..."
		read -t 2 -p "Add ID? (y/n)" -a answer -N 1; echo #use this if run in terminal
		if [ "$answer" == "y" ]; then #use this if run in terminal
		# kbd_event=$(inotifywait -t 5 -q -e modify $kbd_file) #use this when run locally
		# if [ ${#kbd_event} -gt 0 ];then
		# 	slot=$(cat $kbd_file)
		# 	re='^[0-9]+$'
		# 	echo "keypressed: "$slot"*"
		# else	
		# 	echo "no key pressed"
		# fi		
		#if [ "$slot" == "1" ]; then #use this when run locally
			echo "employee added.."
			echo "$nfc_id,$nfc_id_hex">>$employee_list
		else	
			echo "not added.."
		fi
	fi
done
