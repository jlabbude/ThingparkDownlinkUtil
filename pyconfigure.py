import serial
import glob
import threading
import re
from cfgdicts import abeewaycfgdict

baud_rate = 9600
serial_port_array = glob.glob("/dev/ttyACM0")

def communicate_with_serial(serial_port, baud_rate):
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        with open('config.cfg', 'rb') as config:
            for line in config:
                ser.write(line.strip())
                ser.write(b'\r')

def get_config_from_cfg():
    with open('config.cfg', 'r') as config:
        for line in config:
            p = re.compile("config set (.*) ")
            match  = p.search(line)
            if match:
                return match.group(1)

def parallel_process():
    threads = []
    for serial_port in serial_port_array:
        thread = threading.Thread(target=communicate_with_serial, args=(serial_port, baud_rate))
        threads.append(thread)
        thread.start()
    for thread in threads:
        thread.join()

print(get_config_from_cfg())