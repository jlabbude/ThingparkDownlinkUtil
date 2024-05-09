import serial
import glob
import threading
import re
from cfgdicts import abeewaycfgdict

baud_rate = 9600
serial_port_array = glob.glob("/dev/ttyACM0")
config_file = 'configlong.cfg'

def communicate_with_serial(serial_port, baud_rate):
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        with open(config_file, 'rb') as config:
            for line in config:
                ser.write(line.strip())
                ser.write(b'\r')

def get_config_from_cfg(parameter, line):
    if parameter is not None:
        pattern = r"config set %d (.*)" % parameter
        p = re.compile(pattern)
        match  = p.search(line)
        if match:
            return int(match.group(1))

def get_config_parameter(line):
    p = re.compile("config set (.*) ")
    match = p.search(line)
    if match:
        return int(match.group(1))

def parallel_process():
    threads = []
    for serial_port in serial_port_array:
        thread = threading.Thread(target=communicate_with_serial, args=(serial_port, baud_rate))
        threads.append(thread)
        thread.start()
    for thread in threads:
        thread.join()

with open(config_file, 'r') as config:
    for line in config:
        print(get_config_from_cfg(get_config_parameter(line), line))