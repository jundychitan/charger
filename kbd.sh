#! /usr/bin/env python

import struct
import time
import sys

kbd_buffer = []

def map_key(key):
	if(key==82):
		kbd_buffer.append('0')
	if(key==79):
		kbd_buffer.append('1')
	if(key==80):
		kbd_buffer.append('2')		
	if(key==81):
		kbd_buffer.append('3')
	if(key==75):
		kbd_buffer.append('4')		
	if(key==76):
		kbd_buffer.append('5')		
	if(key==77):
		kbd_buffer.append('6')		
	if(key==71):
		kbd_buffer.append('7')
	if(key==72):
		kbd_buffer.append('8')		
	if(key==73):
		kbd_buffer.append('9')		
	if(key==96):
		#print ''.join(kbd_buffer)
		f=open("/var/txtalert/kbd","w+")
		f.write(''.join(kbd_buffer))
		f.close()
		kbd_buffer[:]=[]
			

if __name__ == "__main__":
	infile_path = "/dev/input/event" + (sys.argv[1] if len(sys.argv) > 1 else "0")

	#long int, long int, unsigned short, unsigned short, unsigned int
	FORMAT = 'llHHI'
	EVENT_SIZE = struct.calcsize(FORMAT)

	#open file in binary mode
	in_file = open(infile_path, "rb")

	event = in_file.read(EVENT_SIZE)

	while event:
		(tv_sec, tv_usec, type, code, value) = struct.unpack(FORMAT, event)

		if type != 0 or code != 0 or value != 0:
			#print("Event type %u, code %u, value %u at %d.%d" % \
			#	(type, code, value, tv_sec, tv_usec))
			if type==1 and value==1 and code!=69:
				#print("code %u" % (code))
				map_key(code)					
		event = in_file.read(EVENT_SIZE)
		

		
	in_file.close()

