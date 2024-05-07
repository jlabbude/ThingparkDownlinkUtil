import numpy
import matplotlib.pyploy
import math
import random

radius_size = 1000 #m
noise_figure_start = 0 #db
gateway_amount = 1
sf_value = 8 #todo
sf_dict = { 
    7 : 7.5,
    8 : 10,
    9 : 12.5,
    10 : 15,
    11 : 17.5,
    12 : 20
}
devices_dict = {
    0 : [get_device_location, random.randomint(0, 59)]
}
signal_strenth_array=[] # needed to calculate NF later

def get_device_location():
    angle = random.randint(0, 359)
    distance = random.randint(0, radius_size)
    device_pos = [angle, distance]

    return device_pos

def signal_sens_formula():
    
    noise_figure_current = noise_figure_start # todo implement dynamic NF calculation

    signal_strenth_array.append( # formula declaration
        -174 +
        (10*math.log10(500)) + # BW from DW channels are always 500 MHz
        noise_floor_current +
        sf_dict.get(sf_value) # noise floor from SF 
    )