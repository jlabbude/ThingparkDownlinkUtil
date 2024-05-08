import serial
import glob

baud_rate = 9600
serial_port_array = glob.glob("/dev/ttyACM*")

for serial_port in serial_port_array:
    with serial.Serial(serial_port, baud_rate, timeout=1) as ser:
        with open('config.cfg', 'rb') as file:
                for line in file:
                        ser.write(line.strip())
                        ser.write(b'\r')
        response = ser.read(500)
        print(serial_port)
        print(response.decode('utf-8'))
        ser.close()