import os
import shutil
import ctypes
import subprocess
from pathlib import Path

def delete_temp_files():
    temp = os.environ.get("TEMP")
    if temp:
        try:
            for item in Path(temp).iterdir():
                if item.is_file():
                    item.unlink(missing_ok=True)
                elif item.is_dir():
                    shutil.rmtree(item, ignore_errors=True)
            return "[OK] Temp files cleared"
        except Exception as e:
            return f"[ERROR] Temp cleanup failed: {e}"
    return "[WARN] Temp folder not found"

def empty_recycle_bin():
    try:
        # Using Windows API to empty recycle bin safely
        SHERB_NOCONFIRMATION = 0x00000001
        SHERB_NOPROGRESSUI = 0x00000002
        SHERB_NOSOUND = 0x00000004
        ctypes.windll.shell32.SHEmptyRecycleBinW(None, None,
                                                 SHERB_NOCONFIRMATION |
                                                 SHERB_NOPROGRESSUI |
                                                 SHERB_NOSOUND)
        return "[OK] Recycle Bin emptied"
    except Exception as e:
        return f"[ERROR] Recycle Bin failed: {e}"

def clear_recent_docs():
    try:
        recent = Path(os.environ['APPDATA']) / "Microsoft" / "Windows" / "Recent"
        for item in recent.iterdir():
            if item.is_file():
                item.unlink(missing_ok=True)
            elif item.is_dir():
                shutil.rmtree(item, ignore_errors=True)
        return "[OK] Recent documents cleared"
    except Exception as e:
        return f"[ERROR] Recent docs cleanup failed: {e}"

def run_trace_remover():
    results = []
    results.append(delete_temp_files())
    results.append(empty_recycle_bin())
    results.append(clear_recent_docs())
    return results

# Test run
if __name__ == "__main__":
    for res in run_trace_remover():
        print(res)
