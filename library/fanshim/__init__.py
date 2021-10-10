import lgpio as gpio
import time

__version__ = '1.0.0'


class APA102():
    def __init__(self, sbc, gpio_clock, gpio_data, brightness):
        """APA102 LED class.
        
        Based heavily on https://github.com/pimoroni/apa102-python.
        """
        self.sbc = sbc
        self.gpio_clock = gpio_clock
        self.gpio_data = gpio_data
        # Intialise buffer (see https://cpldcpu.wordpress.com/2014/08/27/apa102/)
        self._start_length = 4
        _frame_length = 4
        _end_length = 4
        self.buffer = self.reset_buffer(self._start_length, _frame_length, _end_length, brightness)

    def reset_buffer(self, start_length, frame_length, end_length, brightness):
        """Clear buffer i.e. LED off."""
        buffer = []
        for _ in range(start_length):
            buffer.append(0b00000000)
        buffer += [0b11100000 | int(brightness * 31) for _ in range(frame_length)]
        for _ in range(end_length):
            buffer.append(0b11111111)
        return buffer
    
    def set_colour(self, r, g, b):
        """Set LED colour.

        :param r: amount of red (0-255).
        :param g: amount of green (0-255).
        :param b: amount of blue (0-255).
        """
        offset = self._start_length  + 1
        self.buffer[offset:offset + 3] = [b, g, r]

    def set_brightness(self, brightness):
        """Set LED brightness.

        :param brightness: LED brightness (0.0-1.0).
        """
        self.buffer[self._start_length] = 0b11100000 | int(31 * brightness)
    
    def write_buffer(self):
        """Update LED state."""
        for byte in self.buffer:
            for _ in range(8):
                gpio.gpio_write(self.sbc, self.gpio_data, (byte & 0x80))
                gpio.gpio_write(self.sbc, self.gpio_clock, 1)
                time.sleep(0)
                byte <<= 1
                gpio.gpio_write(self.sbc, self.gpio_clock, 0)
                time.sleep(0)


class FanShim():
    def __init__(self, led_clock=14, led_data=15, fan_pin=18, led_brightness=0.1):
        """FAN Shim.

        Based heavily on https://github.com/pimoroni/fanshim-python.

        :param led_clock: SPI clock pin for APA102 LED.
        :param led_data: SPI data pin for APA102 LED.
        :param fan_pin: BCM pin for fan on/off.
        :param led_brightness: Control brightness of LED (0-1 but not linear).
        """
        self._led_clock = led_clock
        self._led_data = led_data
        self._fan_pin = fan_pin
        # Raspberry Pi GPIO class
        self._sbc = gpio.gpiochip_open(0)
        gpio.gpio_write(self._sbc, fan_pin, 1)  # fan is on by default
        # LED class
        self._led = APA102(self._sbc, led_clock, led_data, led_brightness)

    def get_fan(self):
        """Get current fan state."""
        return gpio.gpio_read(self._sbc, self._fan_pin)

    def set_fan(self, state):
        """Set fan state."""
        gpio.gpio_write(self._sbc, self._fan_pin, state)
        return int(state)

    def toggle_fan(self):
        """Toggle fan state."""
        fan_state = self.get_fan()
        gpio.gpio_write(self._sbc, self._fan_pin, not fan_state)
        return int(not fan_state)

    def set_light(self, r, g, b, brightness=None):
        """Set LED.

        :param r: Red (0-255).
        :param g: Green (0-255).
        :param b: Blue (0-255).
        """
        self._led.set_colour(r, g, b)
        if brightness is not None:
            self._led.set_brightness(brightness)
        self._led.write_buffer()
