import tkinter as tk
from tkinter import ttk
from tweaks import reg_tweaks
import sys, ctypes, os

# --- Check for admin rights and relaunch if not ---
def run_as_admin():
    try:
        is_admin = ctypes.windll.shell32.IsUserAnAdmin()
    except:
        is_admin = False

    if not is_admin:
        # Switch to pythonw.exe to suppress console
        python_exe = sys.executable.replace("python.exe", "pythonw.exe")
        params = " ".join([f'"{arg}"' for arg in sys.argv[1:]]) if len(sys.argv) > 1 else ""
        ctypes.windll.shell32.ShellExecuteW(
            None, "runas", python_exe, f'"{sys.argv[0]}" {params}', None, 1
        )
        sys.exit()
        
run_as_admin()

# Function to execute a specific tweak and log the output
def run_tweak(tweak_func):
    try:
        success = tweak_func()
        if success:
            logs_text.insert(tk.END, f"'{tweak_func.__name__}' applied successfully.\n")
        else:
            logs_text.insert(tk.END, f"'{tweak_func.__name__}' failed.\n")
    except Exception as e:
        logs_text.insert(tk.END, f"Error running {tweak_func.__name__}: {e}\n")
    logs_text.see(tk.END)

# Function to run all tweaks at once
def run_all_tweaks():
    tweaks = [
        reg_tweaks.win_32_priority,
        reg_tweaks.network_throttling,
        reg_tweaks.set_tcp_ack_frequency,
        reg_tweaks.games_tweaks,
        reg_tweaks.gamebar_tweaks,
        reg_tweaks.enable_game_mode,
        reg_tweaks.enable_gpu_hardware_scheduling
    ]
    for tweak in tweaks:
        run_tweak(tweak)

# Create main window
root = tk.Tk()
root.title("Reg Tweaks UI")
root.geometry("500x400")
root.configure(bg='black')

# Create a Notebook (tabs)
notebook = ttk.Notebook(root)
notebook.pack(expand=True, fill='both')

# Tab 1: Buttons
frame_buttons = tk.Frame(notebook, bg='black')
frame_buttons.pack(fill='both', expand=True)
notebook.add(frame_buttons, text='Tweaks')

# Single button to run all tweaks
btn_all = tk.Button(frame_buttons, text="Run All Tweaks", bg='red', fg='white', width=25, height=3,
                    command=run_all_tweaks)
btn_all.pack(pady=40)

# Tab 2: Logs
frame_logs = tk.Frame(notebook, bg='black')
frame_logs.pack(fill='both', expand=True)
notebook.add(frame_logs, text='Logs')

logs_text = tk.Text(frame_logs, bg='black', fg='white')
logs_text.pack(expand=True, fill='both', padx=10, pady=10)

# Add vertical scrollbar to logs
scrollbar = tk.Scrollbar(frame_logs, command=logs_text.yview)
logs_text.config(yscrollcommand=scrollbar.set)
scrollbar.pack(side=tk.RIGHT, fill=tk.Y)

root.mainloop()