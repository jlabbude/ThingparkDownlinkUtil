import serial
import glob
import threading

baud_rate = 9600
serial_port_array = glob.glob("/dev/ttyACM*")

def communicate_with_serial(serial_port, baud_rate):
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        with open('config.cfg', 'rb') as file:
            for line in file:
                ser.write(line.strip())
                ser.write(b'\r')
        ser.write(b'lora info\r')
        response = ser.read(4000)
        print(response.decode('utf-8'))

threads = []
for serial_port in serial_port_array:
    thread = threading.Thread(target=communicate_with_serial, args=(serial_port, baud_rate))
    threads.append(thread)
    thread.start()
for thread in threads:
    thread.join()