#!/usr/bin/env python3
import sys
import serial
import struct
from tqdm import tnrange, tqdm_notebook
import time

# We start by configuring the path to the serial fpga of the FPGA. 
# Note that the Cmod A7 shows up as two serial ports, 
# you can figure out which one is the right one by trial and error.
SERIAL_fpga = sys.argv[1]
SERIAL_tx1 = sys.argv[2]


fpga = serial.Serial(SERIAL_fpga, baudrate=115200)
# tx1 = serial.Serial(SERIAL_tx1, baudrate=115200, timeout=0.02)


CMD_SET_PERIOD = 66
CMD_SET_GLITCH_PULSE = 67


def cmd(fpga, command):
    fpga.write(chr(command).encode("ASCII"))

def cmd_uint32(fpga, command, u32):
    fpga.write(chr(command).encode("ASCII"))
    data = struct.pack(">L", u32)
    fpga.write(data)

def cmd_uint8(fpga, command, u8):
    fpga.write(chr(command).encode("ASCII"))
    data = struct.pack("B", u8)
    fpga.write(data)

def cmd_read_uint8(fpga, command):
    fpga.write(chr(command).encode("ASCII"))
    return fpga.read(1)[0]

def cmd_read_uint32(fpga, command):
    fpga.write(chr(command).encode("ASCII"))
    return fpga.read(4)
    
def setup(period, pulse):
    # 1 == 10ns
    cmd_uint32(fpga, CMD_SET_PERIOD, period)
    cmd_uint32(fpga, CMD_SET_GLITCH_PULSE, pulse)

def bf_pulse():
    for pulse in range(PULSE_FROM, PULSE_TO, PULSE_STEP):
        print(f"current pulse: {pulse}")
        setup(PERIOD, pulse)
        time.sleep(PERIOD * 10 / 100000000)


GLITCH_PULSE = 1190
# 100 == 1us
PERIOD = 500000000

PULSE_FROM = 250
PULSE_TO = 500
PULSE_STEP = 10

if __name__ == "__main__":
    setup(PERIOD, GLITCH_PULSE)
    # bf_pulse()