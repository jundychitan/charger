#!/bin/sh
project_dir=/projects/charger/pixel_led/blink

timestamp(){
	date +"%Y%m%d%H%M%S"
}
inotifywait -m -q -e close_write $project_dir  | while read res
do
	#echo $res
	dir=$(echo $res |awk '{print $1}')$(echo $res |awk '{print $3}')
	file_name=$(echo $res |awk '{print $3}')
	event=$(echo $res |awk '{print $2}')
	
	#echo $dir
	#echo $file_name
	
	if [ "$event" != "DELETE" ];
	then
		#echo $res
		led_status=$(cat $dir)
		echo "setblink=$file_name,$led_status"> /dev/ttyS0
	fi
done

