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
target = serial.Serial(SERIAL_tx1, baudrate=115200, timeout=0.5)

CMD_TOGGLE_LED = 65
CMD_POWER_CYCLE = 66
CMD_SET_GLITCH_PULSE = 67 # uint32
CMD_SET_DELAY = 68 # uint32
CMD_SET_POWER_PULSE = 69 # uint32
CMD_GLITCH = 70
CMD_READ_GPIO = 71
CMD_ENABLE_GLITCH_POWER_CYCLE = 72 # bool/byte
CMD_GET_STATE = 73 # Get state of fpga
CMD_GET_FLANKS = 50 # Get current flank count
CMD_SET_EDGE_COUNTER = 74
CMD_SET_TRIGGER_MODE = 75
CMD_SET_TRIGGER_LENGTH = 76


def cmd_toggle_led(fpga):
    fpga.write(chr(CMD_TOGGLE_LED).encode("ASCII"))

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

def parse_status(status):
    power_pulse_status = (status >> 6) & 0b11
    trigger_status = (status >> 4) & 0b11
    delay_status = (status >> 2) & 0b11
    glitch_pulse_status = status & 0b11
    print("Power pulse   : " + str(power_pulse_status))
    print("Trigger status: " + str(trigger_status))
    print("Delay status  : " + str(delay_status))
    print("Glitch pulse  : " + str(glitch_pulse_status))


def success_gpio(delay, pulse):
    # Check whether the glitch was successful!
    gpios = cmd_read_uint8(fpga, CMD_READ_GPIO)
    if(gpios):
        print("*** SUCCESS ***")
        print("Delay: " + str(delay))
        print("Pulse: " + str(pulse))
        return True
    else:
        return False

def success_uart(delay, pulse):
    response = target.read(38)
    print(f"delay: {delay} | pulse: {pulse} | response: {response}", flush=True)
    # if not b"!100 - 100 - 10000\n" in response:
    if response != b'\x00\nstarting:\n1000000 \xe2\x88\x92 1000 \xe2\x88\x92 1000\n':
        print("*** SUCCESS ***", flush=True)
        target.timeout = None
        hexdump = target.read(1024*96)
        with open("./hexdump.txt", "w") as file:
            file.write(hexdump.decode())
        return True
    else:
        return False

def success_manual():
    input("Next? [Enter]\n")

def brute_glitch():
    success = False
    for delay in range(DELAY_FROM, DELAY_TO, DELAY_STEPS):
        # print(f"starting #delay: {delay}")
        cmd_uint32(fpga, CMD_SET_DELAY, delay)
        if success:
            return success
        for pulse in range(PULSE_FROM, PULSE_TO, PULSE_STEPS):
            cmd_uint32(fpga, CMD_SET_GLITCH_PULSE, pulse)
            cmd(fpga, CMD_GLITCH)
            # Loop until the status is == 0, aka the glitch is done.
            # This avoids having to manually time the glitch :)
            while(cmd_read_uint8(fpga, CMD_GET_STATE)):
                pass
            if TRIGGER_MODE:
                ctr = cmd_read_uint32(fpga, CMD_GET_FLANKS)
                ctr_int = int.from_bytes(ctr, "big")
                # print(f"flank counter: {ctr_int}")
                if not ctr_int:
                    print("edge_counter_max was too high")
                    continue
            success = success_uart(delay, pulse)
            if success:
                return success
            # success_manual()
    return success


def count_flanks():
    cmd(fpga, CMD_GLITCH)
    while(cmd_read_uint8(fpga, CMD_GET_STATE)):
        pass
    ctr = cmd_read_uint32(fpga, CMD_GET_FLANKS)
    ctr_int = int.from_bytes(ctr, "big")
    return ctr_int
    
def setup():
    # 1 == 10ns
    cmd_uint32(fpga, CMD_SET_POWER_PULSE, POWER_CYCLE_PULSE)
    # cmd_uint32(fpga, CMD_SET_DELAY, 21340039)
    cmd_uint32(fpga, CMD_SET_DELAY, DELAY)
    cmd_uint32(fpga, CMD_SET_GLITCH_PULSE, GLITCH_PULSE)
    cmd_uint32(fpga, CMD_SET_EDGE_COUNTER, EDGE_COUNTER)
    cmd_uint32(fpga, CMD_SET_TRIGGER_LENGTH, TRIGGER_LENGTH) #works
    # cmd_uint32(fpga, CMD_SET_TRIGGER_LENGTH, 1000) #works
    cmd_uint8(fpga, CMD_ENABLE_GLITCH_POWER_CYCLE, POWER_CYCLE_BEFORE_GLITCH)
    cmd_uint8(fpga, CMD_SET_TRIGGER_MODE, TRIGGER_MODE)
    

def run_flank_counter(repetitions):

    print("Power pulse...")
    results = []
    for i in range(repetitions):
        results.append(count_flanks())
    return results

# Whether the DUT should be power-cycled before the test. 
# Some fpgas are very slow to start up (for example the ESP32), 
# and as such it makes more sense to try to glitch and endless loop.
POWER_CYCLE_BEFORE_GLITCH = 1
TRIGGER_MODE = 0
# 8333
EDGE_COUNTER = 1
DELAY = 10
# DELAY = 8250
GLITCH_PULSE = 100
TRIGGER_LENGTH = 10
# 100_000_000th of a second 
# 0,01               us
# 10                 ns
# The duration for which the power-cycle pulse should be send, in 100_000_000th of a second (0,01 us == 10 ns)
POWER_CYCLE_PULSE = 500 
# The delay range from the trigger to the glitch that should be tested, in 100_000_000th of a second
DELAY_FROM = 0 
DELAY_TO = 7677800 # delay until after "!" plus loop length (76,7ms)
DELAY_STEPS = 2
# The duration range for the glitch pulse, in 100_000_000th of a second.
PULSE_FROM = 100
PULSE_TO = 1500
PULSE_STEPS = 2

if __name__ == "__main__":
    # Lets see what the current state of the glitching logic is. 
    # This is useful to verify that the fpga is working and to ensure it does not need to be reset:
    # status = cmd_read_uint8(fpga, CMD_GET_STATE)

    setup()
    # results = run_flank_counter(1000)

    # occurences = {occ:results.count(occ) for occ in results}
    # occurences_sorted = {k: v for k, v in sorted(occurences.items(), key=lambda item: item[1])}

    # with open("./flanks.txt", "w") as file:
    #     file.writelines(f"{result}\n" for result in results)
    #     file.write("\n============= grouped by occurence ===============\n")
    #     file.writelines(f"{occ}: {occurences_sorted[occ]}\n" for occ in occurences_sorted)
    success = False
    while not success:
        success = brute_glitch()
    # while True:
    #     run_flank_counter(1)
    # Show status of IOs