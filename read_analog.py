#!/usr/bin/python
# -*- coding:utf-8 -*-
from __future__ import print_function
import serial
import time
import sys
import os
from os import path
from timeit import default_timer as timer


		
def main():
	if (path.exists('/tmp/txtalert/analog')==0):
		os.mkdir('/tmp/txtalert/analog')

	ser=serial.Serial(port='/dev/ttyS0',baudrate=9600,parity=serial.PARITY_NONE,stopbits=serial.STOPBITS_ONE,bytesize=serial.EIGHTBITS,timeout=1)
	while(1):
		try:
			if ser.inWaiting():
				data=(ser.readline())
				#print(data)
				splitData=data.split(":")
				param=splitData[0]
				value=splitData[1].strip('\n\r')
				f = open('/tmp/txtalert/analog/'+param, "w")
				f.write(value)
				f.close()		
			time.sleep(0.1)						

		except:
  				print("An exception occurred")  		
		
	ser.close

		

if __name__ == "__main__":
	main()

