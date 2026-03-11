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
from huggingface_hub import hf_hub_download

server_thread = None
download_thread = None
assets_downloaded = False

config = None

def read_config():
    global config
    if os.path.exists('config.json'):
        with open('config.json') as f:
            config = json.load(f)
    else:
        config = {"users": [], "path": "", "passwords":[] }
        save_config()
    print("Config loaded")

def save_config():
    global config
    with open('config.json', 'w') as f:
        json.dump(config, f)
    print("Config saved")

read_config()

def check_assets():
    """Check if RAM model is downloaded"""
    global assets_downloaded
    model_path = 'backend/ram_swin_large_14m.pth'
    assets_downloaded = os.path.exists(model_path)
    return assets_downloaded

def download_ram_model():
    """Download RAM model from HuggingFace"""
    global download_thread, assets_downloaded
    
    if download_thread is not None and download_thread.is_alive():
        print("Download already in progress")
        return
    
    def download_task():
        global assets_downloaded
        try:
            progress_label.configure(text="Downloading RAM model...")
            start_button.configure(state="disabled")
            
            # Repository info
            repo_id = "xinyu1205/recognize-anything"
            target_file = "ram_swin_large_14m.pth"
            save_dir = "backend"
            
            # Download only the model file
            progress_label.configure(text="Downloading from HuggingFace...")
            downloaded_path = hf_hub_download(
                repo_id=repo_id,
                filename=target_file,
                repo_type="space",
                local_dir=save_dir,
                local_dir_use_symlinks=False
            )
            
            assets_downloaded = True
            progress_label.configure(text="✅ Download complete!")
            start_button.configure(text="Start Photo Assistant", state="normal")
            
            root.after(2000, lambda: progress_label.configure(text=""))
            print(f"✅ Download complete. File saved to: {downloaded_path}")
            
        except Exception as e:
            progress_label.configure(text=f"❌ Download failed: {str(e)}")
            start_button.configure(state="normal")
            print(f"Error downloading model: {e}")
    
    download_thread = threading.Thread(target=download_task, daemon=True)
    download_thread.start()

def on_open_button_click():
    if server_thread is not None and server_thread.is_alive():
        print('Alert')
        print('Please server stop first')
        show_toast()
        return
    global config
    folder_path = filedialog.askdirectory()
    if folder_path:
        entry.configure(state="normal")
        entry.delete(0, tk.END)
        entry.insert(0, folder_path)
        entry.configure(state="disabled")
        config['path'] = entry.get()
        save_config()
        toasting()
    else:
        print("No folder selected")

def on_stop_button_click():
    global server_thread, image_label, tk_image
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

        pil_image = Image.open('backend/loo.png')
        resized_image = pil_image.resize((145, 145))
        much = 25
        area = (much, much, pil_image.width - much, pil_image.height - much)
        pil_image = pil_image.crop(area)
        image_label.destroy()
        resized_image = pil_image.resize((145,145))
        tk_image = ImageTk.PhotoImage(resized_image)
        image_label = tk.Label(root, image=tk_image)
        image_label.place(x=120,y=220)
        toaster()
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
        img = qrcode.make(f"https://picfolio.vercel.app/scan/http://{ip}:7251")
        img.save("backend/qr.png")
        pil_image = Image.open('backend/qr.png')
        # crop 10 px from all edges
        much = 25
        area = (much, much, pil_image.width - much, pil_image.height - much)
        pil_image = pil_image.crop(area)
        image_label.destroy()
        resized_image = pil_image.resize((145,145))
        tk_image = ImageTk.PhotoImage(resized_image)
        image_label = tk.Label(root, image=tk_image)
        image_label.place(x=120,y=220)
        s.close()
        toast()
    print("Start Photo Assistant button clicked")

started = False
def start_stop():
    global started, assets_downloaded
    
    # Check if assets are downloaded
    if not assets_downloaded:
        download_ram_model()
        return
    
    if started:
        started = False
        on_stop_button_click()
    else:
        started = True
        on_start_button_click()

    start_button.configure(text="Stop Photo Assistant" if started else "Start Photo Assistant")



def toast():
    notification.place(x=110,y=10)
    root.after(3000, hide)
def toaster():
    noti.place(x=110,y=10)
    root.after(3000, hide)
def hide():
    if notified.winfo_exists():
        notified.place_forget()
    if noti.winfo_exists():
        noti.place_forget()
    if noti2.winfo_exists():
        noti2.place_forget()
    if notification.winfo_exists():
        notification.place_forget()
def toasting():
    notified.place(x=110,y=10)
    root.after(3000, hide)
def show_toast():
    noti2.place(x=110,y=10)
    root.after(3000, hide)



ctk.set_appearance_mode("System")  # Modes: system (default), light, dark
ctk.set_default_color_theme("backend/dark-red.json")  # Themes: blue (default), dark-blue, green


root = ctk.CTk()
root.title("PicFolio Photo Assistant")
root.geometry("515x515")
root.iconbitmap('backend/icon/logo.ico')
root.resizable(False, False)


# First Box - Set Data directory
set_data_label = ctk.CTkLabel(root, text="Set Data directory: the Images will save to this directory")
set_data_label.grid(row=1, column=0, padx=20, pady=30)
home_label = ctk.CTkLabel(root, text="Home Directory:")
home_label.place(x=30, y=60)
update_button = ctk.CTkButton(root, text="Change", width=150, height=1,command=on_open_button_click,fg_color=("#FFB4A6","#AF2F1C"),hover_color=("#FFDAD4","#8D1605"),text_color=("black","white"))
update_button.place(x=318,y=90)
entry_var = tk.StringVar()
entry = ctk.CTkEntry(root, textvariable=entry_var, width=260)
entry.place(x=30,y=85)
entry.configure(state="disabled")

start_button = ctk.CTkButton(root, text="Download Assets", width=150, height=2, command=start_stop,fg_color=("#FFB4A6","#AF2F1C"),hover_color=("#FFDAD4","#8D1605"),text_color=("black","white"))
start_button.place(x=320,y=220)

# Progress label for download
progress_label = ctk.CTkLabel(root, text="", font=("Bahnschrift", 11), text_color=('black', "white"))
progress_label.place(x=320, y=260)

server_label = ctk.CTkLabel(root, text="Server Address:")
server_label.place(x=320, y=340)
server_entry_var = ctk.StringVar()
server_entry = ctk.CTkEntry(root, textvariable=server_entry_var, width=160)
server_entry.insert(0, "0   .   0   .   0   .   0")
server_entry.place(x=320, y=372)
server_entry.configure(state="disabled")
port_label = ctk.CTkLabel(root, text="Port:")
port_label.place(x=320, y=405)
port_entry_var = ctk.StringVar()
port_entry = ctk.CTkEntry(root, textvariable=port_entry_var, width=160)
port_entry.insert(0, "0000")
port_entry.configure(state="disabled")
port_entry.place(x=320, y=432)
run_checkbox_var = ctk.IntVar()
run_checkbox = ctk.CTkCheckBox(root, variable=run_checkbox_var, text="Run PicFolio Photo Assistant on start",font=("Bahnschrift",13),text_color=('black',"white"),fg_color=("#FFB4A6","#AF2F1C"),hover_color=("#FFDAD4","#8D1605"))
run_checkbox.place(x=22, y=470)

download_label = ctk.CTkLabel(root, text="Please download PicFolio Mobile App.",font=("Bahnschrift",13),text_color=('black',"white"))
download_label.place(x=30,y=340)
service_label = ctk.CTkLabel(root, text="If the service can not be found automatically by",font=("Bahnschrift",13),text_color=('black',"white"))
service_label.place(x=30,y=360)
qr_label = ctk.CTkLabel(root, text="PicFolio App, Please scan the QR code",font=("Bahnschrift",13),text_color=('black',"white"))
qr_label.place(x=30,y=380)
pil_image = Image.open('backend/loo.png')
resized_image = pil_image.resize((145, 145))
much = 25
area = (much, much, pil_image.width - much, pil_image.height - much)
pil_image = pil_image.crop(area)
resized_image = pil_image.resize((145,145))
tk_image = ImageTk.PhotoImage(resized_image)
image_label = tk.Label(root, image=tk_image)
image_label.place(x=120,y=220)

#notification
notification = ctk.CTkButton(root, text="Picfolio assistant has been started", width=250, height=1, text_color="black", fg_color="white", hover=False)
#notification.place(x=110,y=10)
noti = ctk.CTkButton(root, text="Picfolio assistant has been stopped", width=250, height=1, text_color="black", fg_color="white", hover=False)
noti2 = ctk.CTkButton(root, text="Please stop the server", width=250, height=1, text_color="black", fg_color="white", hover=False)
notified = ctk.CTkButton(root, text="Folder updated", width=250, height=1, text_color="black", fg_color="white", hover=False)

def doSomething():
    on_stop_button_click()
    root.destroy()
    exit()

def firstLoad():
    global assets_downloaded
    # set text of entery if dir is not none in config
    if config['path'] != "":
        entry.configure(state="normal")
        entry.delete(0, tk.END)
        entry.insert(0, config['path'])
        entry.configure(state="disabled")
    
    # Check if assets are downloaded
    if check_assets():
        start_button.configure(text="Start Photo Assistant")
        progress_label.configure(text="Assets ready ✓")
        root.after(2000, lambda: progress_label.configure(text=""))
    else:
        start_button.configure(text="Download Assets")
        progress_label.configure(text="Please download assets first")

firstLoad()



root.protocol('WM_DELETE_WINDOW', doSomething)  # root is your root window

root.mainloop()