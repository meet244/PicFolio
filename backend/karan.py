import tkinter as tk
from PIL import Image, ImageTk
import customtkinter as ctk
import threading
import ctypes
import app
import os
import socket
import qrcode
import json
from waitress import serve
from tkinter import filedialog

server_thread = None

config = None

def read_config():
    global config
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
    else:
        config = {"users": ["family"], "path": ""}
        save_config()
    print("Config loaded")
def save_config():
    global config
    with open('config.json', 'w') as f:
        json.dump(config, f)
    print("Config saved")

read_config()

def on_set_button_click():
    if server_thread is not None and server_thread.is_alive():
        print('Alert')
        print('Please server stop first')
        return
    global config
    config['path'] = entry.get()
    save_config()

def on_open_button_click():
    if server_thread is not None and server_thread.is_alive():  
        print('Alert')
        print('Please server stop first')
        return
    folder_path = filedialog.askdirectory()
    if folder_path:
        entry.configure(state="normal")
        entry.delete(0, tk.END)
        entry.insert(0, folder_path)
        entry.configure(state="disabled")
    else:
        print("No folder selected")

def on_stop_button_click():
    global server_thread
    if server_thread is not None and server_thread.is_alive():
        # server_thread.stop()
        thread_id = server_thread.ident
        res = ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(thread_id), ctypes.py_object(SystemExit))
        if res > 1:
            ctypes.pythonapi.PyThreadState_SetAsyncExc(ctypes.c_long(thread_id), 0)
        print("Daemon thread forcefully terminated.")
        server_entry.configure(state="normal")
        server_entry.delete(0, tk.END)
        server_entry.insert(0, "0   .   0   .   0   .   0")
        server_entry.configure(state="disabled")
        port_entry.configure(state="normal")
        port_entry.delete(0, tk.END)
        port_entry.insert(0, "0000")
        port_entry.configure(state="disabled")
    print("Stop Photo Assistant button clicked")

def on_start_button_click():
    global server_thread, tk_image, image_label, server_entry, port_entry, config
    # check if path is set
    if config['path'] == "":
        print("Alert")
        print("Path is not set")
        return
    if server_thread is None or not server_thread.is_alive():
        server_thread = threading.Thread(target=app.start_this, daemon=True,)
        server_thread.start()
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        server_entry.configure(state="normal")
        server_entry.delete(0, tk.END)
        server_entry.insert(0, ip.replace('.', '   .   '))
        server_entry.configure(state="disabled")
        port_entry.configure(state="normal")
        port_entry.delete(0, tk.END)
        port_entry.insert(0, "7251")
        port_entry.configure(state="disabled")
        img = qrcode.make("http://"+ip+":7251")
        img.save("qr.png")
        pil_image = Image.open('qr.png')
        # crop 10 px from all edges
        much = 25
        area = (much, much, pil_image.width - much, pil_image.height - much)
        pil_image = pil_image.crop(area)
        image_label.destroy()
        resized_image = pil_image.resize((int(pil_image.width / 2.5), int(pil_image.height / 2.5)))
        tk_image = ImageTk.PhotoImage(resized_image)
        image_label = tk.Label(root, image=tk_image)
        image_label.place(x=70,y=210)
        s.close()
    print("Start Photo Assistant button clicked")

# def on_new_user_button_click():
#     print("New User button clicked")

# def on_import_button_click():
#     print("Import button clicked")

root = ctk.CTk()
root.title("PicFolio Photo Assistant Setting & Control Panel")
root.geometry("500x545")

# Display Menu label
uname = ctk.CTkLabel(root, text="Menu")
uname.place(x=0, y=0)

# First Box - Set Data directory
set_data_label = ctk.CTkLabel(root, text="Set Data directory: the data will save to this directory")
set_data_label.grid(row=1, column=0, padx=20, pady=30)
home_label = ctk.CTkLabel(root, text="Home Directory")
home_label.place(x=30, y=60)
set_button = ctk.CTkButton(root, text="Set", width=75, height=1, command=on_set_button_click)
set_button.place(x=318,y=90)
open_button = ctk.CTkButton(root, text="Open", width=75, height=1, command=on_open_button_click)
open_button.place(x=395,y=90)
entry_var = tk.StringVar()
entry = ctk.CTkEntry(root, textvariable=entry_var, width=260)
entry.insert(0, config['path']) 
entry.place(x=30,y=85)
entry.configure(state="disabled")
redundancy_checkbox_var = ctk.IntVar()
redundancy_checkbox = ctk.CTkCheckBox(root, variable=redundancy_checkbox_var, text="Redundancy Backup Directory")
redundancy_checkbox.place(x=30, y=130)

# Second Box - PicFolio Status
status_label = ctk.CTkLabel(root, text="PicFolio Photo Assistant Was Started")
status_label.place(x=23, y=170)
stop_button = ctk.CTkButton(root, text="Stop Photo Assistant", width=150, height=1, command=on_stop_button_click)
stop_button.place(x=320,y=200)
start_button = ctk.CTkButton(root, text="Start Photo Assistant", width=150, height=1, command=on_start_button_click)
start_button.place(x=320,y=233)
# new_user_button = ctk.CTkButton(root, text="Create New User...", width=150, height=1, command=on_new_user_button_click)
# new_user_button.place(x=320,y=265)
# import_button = ctk.CTkButton(root, text="Import...", width=150, height=1, command=on_import_button_click)
# import_button.place(x=320,y=297)
server_label = ctk.CTkLabel(root, text="Server Address:")
server_label.place(x=320, y=345)
server_entry_var = ctk.StringVar()
server_entry = ctk.CTkEntry(root, textvariable=server_entry_var, width=150)
server_entry.insert(0, "0   .   0   .   0   .   0")
server_entry.place(x=320, y=372)
server_entry.configure(state="disabled")
port_label = ctk.CTkLabel(root, text="Port:")
port_label.place(x=320, y=405)
port_entry_var = ctk.StringVar()
port_entry = ctk.CTkEntry(root, textvariable=port_entry_var, width=150)
port_entry.insert(0, "0000")
port_entry.configure(state="disabled")
port_entry.place(x=320, y=432)
run_checkbox_var = ctk.IntVar()
run_checkbox = ctk.CTkCheckBox(root, variable=run_checkbox_var, text="Run PicFolio Photo Assistant while Windows")
run_checkbox.place(x=30, y=470)
auto_hide_checkbox_var = ctk.IntVar()
auto_hide_checkbox = ctk.CTkCheckBox(root, variable=auto_hide_checkbox_var, text="Auto hide this window while restart")
auto_hide_checkbox.place(x=30, y=500)
debug_checkbox_var = ctk.IntVar()
debug_checkbox = ctk.CTkCheckBox(root, variable=debug_checkbox_var, text="Debug mode")
debug_checkbox.place(x=335, y=500)
download_label = ctk.CTkLabel(root, text="Please download PicFolio Mobile App.",font=("Bahnschrift",13),text_color="white")
download_label.place(x=30,y=340)
service_label = ctk.CTkLabel(root, text="If the service can not be found automatically by",font=("Bahnschrift",13),text_color="white")
service_label.place(x=30,y=360)
qr_label = ctk.CTkLabel(root, text="PicFolio App,Please scan the QR code",font=("Bahnschrift",13),text_color="white")
qr_label.place(x=30,y=380)
pil_image = Image.open('loo.png')
resized_image = pil_image.resize((pil_image.width // 2, pil_image.height // 2))
tk_image = ImageTk.PhotoImage(resized_image)
image_label = tk.Label(root, image=tk_image)
image_label.place(x=70,y=210)

def doSomething():
    # check if saving
    # if not:
    stop_button.invoke()
    root.destroy()
    exit()

root.protocol('WM_DELETE_WINDOW', doSomething)  # root is your root window

root.mainloop()