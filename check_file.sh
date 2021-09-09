#!/bin/bash

while [ 1 ]
do
	if [ -f /media/usb0/ch.csv ]; then
		mv /media/usb0/ch.csv /projects/charger/employee_list
	else
		sleep 1
	fi
done
