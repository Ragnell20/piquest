"""
GPIO controller for Pi Quest.
Maps physical breadboard buttons (wired to Raspberry Pi 4 GPIO pins)
to keyboard/mouse inputs for gameplay.
"""

import RPi.GPIO as GPIO
import keyboard
import mouse
import time

# BCM pin numaralandırması
GPIO.setmode(GPIO.BCM)

# Buton-tuş eşlemeleri
buttons = {
    17: 'w',       # yukarı
    18: 's',       # aşağı
    27: 'a',       # sol
    22: 'd',       # sağ
    23: 'RMB',     # saldırı (sağ tıklama)
    24: 'enter',   # etkileşim / onay
    # TODO: tab için pin numarası eklenecek
    # <PIN>: 'tab',
}

# Her pini INPUT olarak ayarla, dahili pull-up direnci aktif et
for pin in buttons:
    GPIO.setup(pin, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# Ana döngü - yaklaşık 100 Hz
try:
    while True:
        for pin, key in buttons.items():
            pressed = GPIO.input(pin) == GPIO.LOW  # Buton basılı

            if key == 'RMB':
                if pressed:
                    mouse.press(button='right')
                else:
                    mouse.release(button='right')
            else:
                if pressed:
                    keyboard.press(key)
                else:
                    keyboard.release(key)

        time.sleep(0.01)  # 100 Hz

except KeyboardInterrupt:
    GPIO.cleanup()
