#!/usr/bin/env python3
from fanshim import FanShim
import colorsys
import psutil
import argparse
import time
import sys

# Parse arguments
parser = argparse.ArgumentParser()
parser.add_argument('--off-threshold', type=float, default=55.0, help='Temperature threshold in degrees C to enable fan.')
parser.add_argument('--on-threshold', type=float, default=65.0, help='Temperature threshold in degrees C to disable fan.')
parser.add_argument('--low-temp', type=float, default=30.0, help='Temperature at which the LED is blue')
parser.add_argument('--high-temp', type=float, default=85.0, help='Temperature for which LED is red')
parser.add_argument('--delay', type=float, default=5.0, help='Delay, in seconds, between temperature readings.')
parser.add_argument('--verbose', action='store_true', default=False, help='Output temp and fan status messages.')
parser.add_argument('--brightness', type=float, default=0.1, help='LED brightness (0-1).')
args = parser.parse_args()

def update_led(temp):
    """Update LED to indicate temperature."""
    if temp < args.off_threshold:
        temp -= args.low_temp
        temp /= float(args.off_threshold - args.low_temp)
        temp  = max(0, temp)
        hue   = (120.0 / 360.0) + ((1.0 - temp) * 120.0 / 360.0)
    elif temp > args.on_threshold:
        temp -= args.on_threshold
        temp /= float(args.high_temp - args.on_threshold)
        temp  = min(1, temp)
        hue   = 1.0 - (temp * 60.0 / 360.0)
    else:
        temp -= args.off_threshold
        temp /= float(args.on_threshold - args.off_threshold)
        temp = max(0, min(1, temp))
        hue   = (1.0 - temp) * 120.0 / 360.0
    r, g, b = [int(c * 255.0) for c in colorsys.hsv_to_rgb(hue, 1.0, args.brightness)]
    fanshim.set_light(r, g, b)

def get_cpu_temp():
    """Get CPU temperature."""
    t = psutil.sensors_temperatures()
    for x in ['cpu-thermal', 'cpu_thermal']:
        if x in t:
            return t[x][0].current
    # Trigger fan if unable to read temperature
    if args.verbose:
        print('Warning: unable to get CPU temperature!')
    return args.on_threshold + 1

# Set up fan
fanshim = FanShim()
fan = fanshim.get_fan()  # get initial fan status

# Monitor temperature and update fan/LED every args.delay seconds
try:
    while True:
        # Get current CPU temperature
        t = get_cpu_temp()
        update_led(t)
        if args.verbose:
                    print('Temp: {:05.02f} Target: {:05.02f} Fan: {}'.format(t, args.off_threshold, fan))
        # Toggle fan if needed
        if fan & (t < args.off_threshold):
            fan = fanshim.toggle_fan()
        elif (fan == False) & (t >= args.on_threshold):
            fan = fanshim.toggle_fan()
        # Wait for next check
        time.sleep(args.delay)
except KeyboardInterrupt:
    # Reset: run fan and switch off LED
    fanshim.set_fan(1)
    fanshim.set_light(0, 0, 0, 0)
    pass
