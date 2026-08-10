import json
import time
from pynput import keyboard
import os
import sys

keys = {}
controller = keyboard.Controller()
is_expanding = False
typed_buffer = ""

def loaddata():
    if getattr(sys, 'frozen', False):
        base_dir = os.path.dirname(sys.executable)
    else:
        base_dir = os.path.dirname(os.path.abspath(__file__))
        
    json_path = os.path.join(base_dir, r"assets\data.json")
    
    global is_expanding
    is_expanding = True
    try:
        global keys
        with open(json_path, "r", encoding="utf-8") as f:   
            keys = json.load(f)
    except: 
        pass
    is_expanding = False

loaddata()

def replace(k, v):
    global is_expanding, typed_buffer
    is_expanding = True
    for _ in range(len(k)):
        controller.press(keyboard.Key.backspace)
        controller.release(keyboard.Key.backspace)
        
    controller.type(f"{v} ")
    typed_buffer = ""
    is_expanding = False
    
def on_press(key):
    """Callback function triggered on every keypress."""
    global typed_buffer, is_expanding
    
    if is_expanding:
        return
        
    loaddata()
    
    try:
        if key.char:
            typed_buffer += key.char
    except AttributeError:
        if key == keyboard.Key.space:
            typed_buffer += " "
        elif key == keyboard.Key.backspace:
            typed_buffer = typed_buffer[:-1]
        elif key in (keyboard.Key.enter, keyboard.Key.esc):
            typed_buffer = "" 

    
    if len(typed_buffer) > 20:
        typed_buffer = typed_buffer[-20:]

    
    for trigger, replacement in keys.items():
        if typed_buffer.endswith(trigger):
            replace(trigger, replacement)
            break

if __name__ == "__main__":
    loaddata()
    
    # Start the keypress listener
    with keyboard.Listener(on_press=on_press) as listener:
        listener.join()
