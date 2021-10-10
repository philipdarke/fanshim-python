# Pimoroni Fan Shim for Ubuntu 20.04+

**This repository updates the Pimoroni Fan Shim software for Raspberry Pi running Ubuntu 20.04+. Tested on a Raspberry Pi 4 8Gb running Ubuntu Server 20.04.**

The Python package `RPi.GPIO` no longer functions on Ubuntu 21.04 (Hirsute Hippo) or newer due to changes to the kernel. The `LGPIO` package should be used in its place. See https://waldorf.waveform.org.uk/2021/the-pins-they-are-a-changin.html, https://ubuntu.com/tutorials/gpio-on-raspberry-pi and http://abyz.me.uk/lg/py_lgpio.html for more information.

The `APA102` package is affected by the same issue. This repository includes a basic `APA102` class which can be used to control the LED on the Pimoroni Fan Shim.

This work is heavily based on https://github.com/pimoroni/fanshim-python and https://github.com/pimoroni/apa102-python.

:bangbang: Currently undergoing testing. Keep an eye on your CPU temperatures and use at your own risk.

## Installation

1. `apt install git python3-pip`
1. `git clone https://github.com/philipdarke/fanshim-python`
1. `cd fanshim-python`
1. `sudo ./install.sh`

A background service is also provided to switch the fan on when the CPU temperature exceeds a threshold (default 65C). The LED colour indicates the CPU temperature. See further details [here](examples/README.md). To install the background service:

1. `cd examples`
1. `sudo ./install-service.sh`

## Stress testing

`stress-ng` can be used to stress the CPU and test the background service is working correctly. The following code stresses the CPU for three minutes which should trigger the fan. The `--tz` argument reports the CPU temperature at the end of the run.

```bash
sudo apt install stress-ng
stress-ng --cpu 0 --cpu-method fft --tz -t 180
```

## Reference

First set up an instance of the `FanShim` class:

```python
from fanshim import FanShim
fanshim = FanShim()
```

### Fan

Turn the fan on/off with:

```python
fanshim.set_fan(True)  # fan on
fanshim.set_fan(False)  # fan off
```

You can also toggle the fan with:

```python
fanshim.toggle_fan()
```

You can check the status of the fan with:

```python
fanshim.get_fan()  # returns 1 for on, 0 for off
```

### LED

The Fan Shim includes one RGB APA-102 LED. Set it to any colour with:

```python
fanshim.set_light(r, g, b)
fanshim.set_light(r, g, b, brightness)  # optional to also set brightness
```

Arguments r, g and b should be numbers between 0 and 255 using the RGB colour system. For example, for red:

```
fanshim.set_light(255, 0, 0)
```

### Button

The Pimoroni Fan Shim includes a button that can be user bound, however **this is not current implemented**.

## Licence

See the [licence](LICENSE) for the https://github.com/pimoroni/fanshim-python/ and https://github.com/pimoroni/apa102-python repositories.
