import winreg

def set_registry_value(root, path, name, value, value_type=winreg.REG_DWORD):
    try:
        key = winreg.CreateKey(root, path)
        winreg.SetValueEx(key, name, 0, value_type, value)
        winreg.CloseKey(key)
        return True
    except Exception as e:
        print(f"[ERROR] Failed to set '{path}\\{name}': {e}")
        return False

def win_32_priority():
    return set_registry_value(
        winreg.HKEY_CURRENT_USER,
        r"SYSTEM\CurrentControlSet\Control\PriorityControl",
        "Win32PrioritySeparation",
        38  # REG_DWORD value
    )  # Improves CPU scheduling for foreground apps (games)

def network_throttling():
    return set_registry_value(
        winreg.HKEY_CURRENT_USER,
        r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile",
        "NetworkThrottlingIndex",
        0xFFFFFFFF  # DISABLE network throttling
    )  # Disables network throttling for smoother network performance

def enable_game_mode():
    return set_registry_value(
        winreg.HKEY_CURRENT_USER,
        r"Software\Microsoft\GameBar",
        "AllowAutoGameMode",
        1 # Enable Game Mode
    )  # Turns on Windows Game Mode for better game performance

def enable_gpu_hardware_scheduling():
    return set_registry_value(
        winreg.HKEY_LOCAL_MACHINE,
        r"SYSTEM\CurrentControlSet\Control\GraphicsDrivers",
        "HwSchMode",
        2 # Enable GPU hardware scheduling
    )  # Enables GPU hardware scheduling for smoother graphics

def games_tweaks():
    base_path = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "GPU Priority", 8)  # Increase GPU priority for games
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "Priority", 6)      # Increase CPU priority for games
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "Scheduling Category", 1)  # Set scheduling to high performance
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "SFIO Priority", 1) # Improve I/O priority for games
    
    return True

def gamebar_tweaks():
    base_path = r"Software\Microsoft\GameBar"
    
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "ShowStartupPanel", 0)       # Hide Game Bar on startup
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "AllowGameDVR", 0)           # Disable Game DVR recording
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "AllowAutoGameMode", 0)      # Disable automatic Game Mode toggling
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "BroadcastingEnabled", 0)    # Disable Game Bar broadcasting
    set_registry_value(winreg.HKEY_CURRENT_USER, base_path, "ShowGameBarWhenGaming", 0)  # Prevent Game Bar from showing in-game
    
    return True

import winreg

def set_tcp_ack_frequency(value=1):
    try:
        tcpip_path = r"SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, tcpip_path)
        for i in range(winreg.QueryInfoKey(key)[0]):
            subkey_name = winreg.EnumKey(key, i)
            subkey_path = tcpip_path + "\\" + subkey_name
            try:
                subkey = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, subkey_path, 0, winreg.KEY_SET_VALUE)
                winreg.SetValueEx(subkey, "TcpAckFrequency", 0, winreg.REG_DWORD, value)
                winreg.CloseKey(subkey)
                print(f"TcpAckFrequency set to {value} for adapter {subkey_name}")
            except Exception as e:
                print(f"[ERROR] Failed for adapter {subkey_name}: {e}")
        winreg.CloseKey(key)
        return True
    except Exception as e:
        print(f"[ERROR] Failed to enumerate network adapters: {e}")
        return False


# --- Run all tweaks ---
if __name__ == "__main__":
    tweaks = [
        win_32_priority,                # Improve CPU scheduling for games
        network_throttling,             # Disable network throttling
        set_tcp_ack_frequency,          # TCP ACK tweak
        games_tweaks,                   # Set game task priorities
        gamebar_tweaks,                 # Disable Game Bar features
        enable_game_mode,               # Enable Windows Game Mode
        enable_gpu_hardware_scheduling  # Enable GPU hardware scheduling
    ] 

    for tweak in tweaks:
        if tweak():
            print(f"'{tweak.__name__}' applied successfully.")
        else:
            print(f"'{tweak.__name__}' failed.")
