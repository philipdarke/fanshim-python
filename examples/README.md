# Example scripts

## `automatic.py`

Complete example for monitoring temperature and automatic fan control.

The LED will fade between blue (cool) to red (hot) as the CPU temperature changes.

The script supports these arguments:

* `--on-threshold` the temperature at which to turn the fan on, in degrees C (default 65)
* `--off-threshold` the temperature at which to turn the fan off, in degrees C (default 55)
* `--low-temp` the temperature at which to turn the fan on, in degrees C (default 65)
* `--high-temp` the temperature at which to turn the fan off, in degrees C (default 55)
* `--delay` the delay between subsequent temperature readings, in seconds (default 5)
* `--brightness` the brightness of the LED (0-1, default 0.05)

You can use systemd or crontab to run this example as a fan controller service on your Pi.

To use systemd, run:

```
sudo ./install-service.sh
```

You can then stop the fan service with:

```
sudo systemctl stop pimoroni-fanshim.service
```

To change the thresholds or other parameters you can add them as arguments to the installer:

```
sudo ./install-service.sh --on-threshold 65 --off-threshold 55 --delay 2
```

To remove the service run:

```
sudo systemctl stop pimoroni-fanshim.service
sudo systemctl disable pimoroni-fanshim.service
rm /etc/systemd/system/pimoroni-fanshim.service
```