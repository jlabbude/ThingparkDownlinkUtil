import serial
import glob
import threading
import re
from cfgdicts import abeewaycfgdict

baud_rate = 9600
serial_port_array = glob.glob("/dev/ttyACM0")
config_file = 'config.cfg'

def set_config_on_device(serial_port, baud_rate):
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        with open(config_file, 'rb') as config:
            for line in config:
                ser.write(line.strip())
                ser.write(b'\r')

def get_config_from_device(serial_port, baud_rate, filename):
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        ser.write(b'123\r')
        ser.write(b'config show\r')
        output = ser.read(3000)
        with open(filename, 'w') as log:
            log.write(output)

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

def parallel_process(target, args):
    threads = []
    for serial_port in serial_port_array:
        thread = threading.Thread(target=target, args=args)
        threads.append(thread)
        thread.start()
    for thread in threads:
        thread.join()

for serial_port in serial_port_array:
    parallel_process(target=set_config_on_device, args=(serial_port, baud_rate))

#with open(config_file, 'r') as config:
 #   for line in config:
        #print(abeewaycfgdict.config_dict.get(get_config_parameter(line)), get_config_from_cfg(get_config_parameter(line), line))