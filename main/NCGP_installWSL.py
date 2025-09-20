import ctypes
import os
import re
import shutil
import subprocess
import sys
import tempfile
import base64
from pathlib import Path

# ============================
# CONFIGURATION (EDIT ME)
# ============================
# Provide your FreeSurfer license file path on Windows (e.g., r"C:\Users\Omar\Downloads\license.txt")
FREESURFER_LICENSE_PATH = r"G:\NCGP\data\scripts\00preproc\license.txt"
# ============================


# ----------------------------
# Helpers
# ----------------------------
def is_admin():
    try:
        return ctypes.windll.shell32.IsUserAnAdmin()
    except Exception:
        return False


def relaunch_as_admin():
    # Re-launch the current script with admin rights
    params = " ".join([f'"{arg}"' for arg in sys.argv])
    ctypes.windll.shell32.ShellExecuteW(None, "runas", sys.executable, params, None, 1)


def run(cmd, check=True, capture_output=True, text=True):
    return subprocess.run(cmd, check=check, capture_output=capture_output, text=text)


def which(cmd):
    try:
        out = run(["where", cmd]).stdout.strip()
        return out.splitlines()[0] if out else None
    except Exception:
        return None


def powershell(ps_command):
    return run(["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", ps_command])


def wsl(cmdline, distro=None):
    # wsl [-d name] -- <bash -lc "...">
    base = ["wsl"]
    if distro:
        base += ["-d", distro]
    base += ["--"] + cmdline
    return run(base)


def parse_wsl_list_v():
    """
    Returns a list of dicts: [{'name': 'Ubuntu-20.04', 'state': 'Running/Stopped', 'version': 1/2, 'default': True/False}, ...]
    """
    try:
        out = run(["wsl", "-l", "-v"]).stdout
    except Exception:
        return []
    lines = [l.strip() for l in out.splitlines() if l.strip()]
    if len(lines) < 2:
        return []
    rows = []
    for line in lines[1:]:
        default = line.startswith("*")
        if default:
            line = line[1:].strip()
        parts = re.split(r"\s{2,}", line)
        if len(parts) < 3:
            name = parts[0].strip()
            state = ""
            version = ""
        else:
            name, state, version = parts[0].strip(), parts[1].strip(), parts[2].strip()
        try:
            version = int(version)
        except Exception:
            version = None
        rows.append({"name": name, "state": state, "version": version, "default": default})
    return rows


def distro_exists(name):
    return any(d["name"].lower() == name.lower() for d in parse_wsl_list_v())


def get_default_distro_name():
    for d in parse_wsl_list_v():
        if d["default"]:
            return d["name"]
    return None


def get_distro_version(name):
    for d in parse_wsl_list_v():
        if d["name"].lower() == name.lower():
            return d["version"]
    return None


def feature_enabled(feature_name):
    res = run(["dism.exe", "/online", "/get-featureinfo", f"/featurename:{feature_name}"])
    return "State : Enabled" in res.stdout or "State : Enable Pending" in res.stdout


def enable_feature_and_maybe_reboot(feature_name):
    if not feature_enabled(feature_name):
        print(f"Enabling Windows feature: {feature_name} ...")
        res = run(["dism.exe", "/online", "/enable-feature", f"/featurename:{feature_name}", "/all", "/norestart"])
        if "Restart Windows to complete this operation" in res.stdout or "restart" in res.stdout.lower():
            print("\nA reboot is required to finish enabling WSL. Please reboot Windows, then run this script again.\n")
            sys.exit(0)
        print(f"Feature {feature_name} enabled.")
    else:
        print(f"Feature {feature_name} already enabled.")


def ensure_wsl_cli_available():
    if which("wsl.exe") is None:
        print("WSL is not available on this system (wsl.exe missing). Make sure you are on Windows 10/11 with WSL support.")
        sys.exit(1)


def set_wsl_default_version(version=1):
    print(f"Setting WSL default version = {version} ...")
    try:
        run(["wsl", "--set-default-version", str(version)])
    except subprocess.CalledProcessError:
        print("Warning: Could not set default version explicitly (older WSL?). Continuing.")

def winget_available():
    return which("winget.exe") is not None

def install_ubuntu_2004_if_needed():
    # Already there?
    if distro_exists("Ubuntu-20.04"):
        print("Ubuntu-20.04 already installed.")
        return True

    print("Trying WinGet → Store → Rootfs import to install Ubuntu-20.04 ...")

    # --- A) WinGet path (preferred if available and Store works in background) ---
    if winget_available():
        try:
            # Silent install, accept agreements
            print("Attempting: winget install -e --id Canonical.Ubuntu.2004 ...")
            run([
                "winget", "install", "-e", "--id", "Canonical.Ubuntu.2004",
                "--accept-source-agreements", "--accept-package-agreements", "--silent"
            ], check=True)
            # WinGet returns quickly; the actual app install may still finish in background.
            # Poll for presence (up to ~2 minutes).
            import time
            for _ in range(24):
                if distro_exists("Ubuntu-20.04"):
                    print("WinGet installed Ubuntu-20.04.")
                    return True
                time.sleep(5)
            print("WinGet did not finalize within the wait window.")
        except subprocess.CalledProcessError:
            print("WinGet path failed or package source unavailable.")

    # --- B) Open the Microsoft Store page (requires user click; script will pause) ---
    try:
        print("Opening Microsoft Store to Ubuntu 20.04 page. Click 'Get/Install', then come back here.")
        # Newer listing (Ubuntu 20.04): product id 9MTTCL66CPXJ
        # We also try the older id afterward as a fallback.
        store_uris = [
            r"ms-windows-store://pdp/?productid=9MTTCL66CPXJ",
            r"ms-windows-store://pdp/?productid=9N6SVWS3RX71",
        ]
        for uri in store_uris:
            powershell(f'Start-Process "{uri}"')

        input("\nPress ENTER after the Store finished installing **Ubuntu 20.04 LTS** ... ")

        if distro_exists("Ubuntu-20.04"):
            print("Store installed Ubuntu-20.04.")
            return True
        else:
            print("Ubuntu-20.04 not detected yet.")
    except Exception:
        print("Could not open Microsoft Store (policy/connection issue?).")

    # --- C) Last resort: direct Canonical rootfs import (no Store required) ---
    print("Falling back to direct import of Canonical 20.04 WSL rootfs (offline-friendly).")
    # Official Canonical WSL rootfs for focal (20.04)
    rootfs_url = "https://cloud-images.ubuntu.com/releases/focal/release/ubuntu-20.04-server-cloudimg-amd64-wsl.rootfs.tar.gz"
    download_dir = Path(os.environ.get("TEMP", tempfile.gettempdir()))
    rootfs_tar = download_dir / "ubuntu-20.04-focal-wsl.rootfs.tar.gz"

    try:
        if not rootfs_tar.exists():
            print(f"Downloading rootfs (~500MB) to: {rootfs_tar}")
            powershell(f'Invoke-WebRequest -Uri "{rootfs_url}" -OutFile "{rootfs_tar}" -UseBasicParsing')
        else:
            print(f"Rootfs already present: {rootfs_tar}")

        # Import as Ubuntu-20.04 in ProgramData
        target_dir = Path(os.environ.get("ProgramData", r"C:\ProgramData")) / "WSL" / "Ubuntu20.04"
        target_dir.mkdir(parents=True, exist_ok=True)

        print("Importing rootfs as 'Ubuntu-20.04' (WSL distro) ...")
        run(["wsl", "--import", "Ubuntu-20.04", str(target_dir), str(rootfs_tar), "--version", "1"], check=True)

        if distro_exists("Ubuntu-20.04"):
            print("Imported Ubuntu-20.04 successfully.")
            return True

        print("Import completed but distro not visible; something went wrong.")
        sys.exit(1)

    except subprocess.CalledProcessError as e:
        print(f"Rootfs import failed: {e}")
        sys.exit(1)



def ensure_user_initialized(distro_name):
    print(f"Ensuring '{distro_name}' has completed first-run initialization (user creation).")
    try:
        wsl(["bash", "-lc", "echo WSL init OK"], distro=distro_name)
    except subprocess.CalledProcessError:
        print(f"Please launch '{distro_name}' once from Start Menu to finalize setup, then re-run this script.")
        sys.exit(1)


def rename_ubuntu_to_ncgp_and_force_version_1():
    if distro_exists("NCGP"):
        print("Distro 'NCGP' already exists.")
        ver = get_distro_version("NCGP")
        if ver != 1:
            print("Converting NCGP to WSL 1 (may take time) ...")
            run(["wsl", "--set-version", "NCGP", "1"])
        run(["wsl", "--set-default", "NCGP"])
        return

    if not distro_exists("Ubuntu-20.04"):
        print("Ubuntu-20.04 is not installed; cannot rename. (The installer step should have handled this.)")
        sys.exit(1)

    ensure_user_initialized("Ubuntu-20.04")

    curr_ver = get_distro_version("Ubuntu-20.04")
    if curr_ver != 1:
        print("Converting 'Ubuntu-20.04' to WSL 1 (may take time) ...")
        run(["wsl", "--set-version", "Ubuntu-20.04", "1"])

    print("Exporting 'Ubuntu-20.04' and importing as 'NCGP' ...")
    tmp_dir = Path(tempfile.mkdtemp(prefix="wsl_export_"))
    tar_path = tmp_dir / "ubuntu2004.tar"
    run(["wsl", "--export", "Ubuntu-20.04", str(tar_path)])

    ncgp_root = Path(os.environ.get("ProgramData", r"C:\ProgramData")) / "WSL" / "NCGP"
    ncgp_root.mkdir(parents=True, exist_ok=True)

    run(["wsl", "--import", "NCGP", str(ncgp_root), str(tar_path), "--version", "1"])

    run(["wsl", "--set-default", "NCGP"])

    print("Unregistering original 'Ubuntu-20.04' to keep things tidy ...")
    run(["wsl", "--unregister", "Ubuntu-20.04"])

    try:
        shutil.rmtree(tmp_dir, ignore_errors=True)
    except Exception:
        pass


def assert_license_file_and_get_b64():
    p = Path(FREESURFER_LICENSE_PATH)
    if not p.is_file():
        print(f"ERROR: FreeSurfer license not found at: {p}")
        sys.exit(1)
    data = p.read_bytes()
    # FreeSurfer license is tiny; safe to embed as base64 in one go
    return base64.b64encode(data).decode("ascii")


def install_freesurfer_732_and_afni_suma_in_ncgp(license_b64):
    print("Installing FreeSurfer 7.3.2 and AFNI+SUMA inside 'NCGP' ...")

    # Base system prep
    base_cmds = r"""
        set -e
        sudo apt-get update
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            ca-certificates curl wget tar bzip2 build-essential \
            tcsh libgomp1 libxext6 libxt6 libxi6 libxmu6 libxrender1 \
            libsm6 libice6 libgl1-mesa-glx libglu1-mesa \
            libglib2.0-0 libjpeg-turbo8 libxft2 libx11-6 libx11-dev \
            libxm4 xfonts-base bc python3 python3-pip git netcat
    """
    wsl(["bash", "-lc", base_cmds], distro="NCGP")

    # -------- FreeSurfer 7.3.2 --------
    fs_cmds = r"""
        set -e
        sudo mkdir -p /opt/freesurfer
        cd /opt
        if [ ! -f freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz ]; then
            wget -q --show-progress https://surfer.nmr.mgh.harvard.edu/pub/dist/freesurfer/7.3.2/freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz
        fi
        sudo tar -xzf freesurfer-linux-ubuntu20_amd64-7.3.2.tar.gz -C /opt

        # Add environment to bashrc (idempotent)
        FS_BASHRC_SNIPPET='
# >>> FreeSurfer 7.3.2 >>>
export FREESURFER_HOME=/opt/freesurfer
export FS_LICENSE=/opt/freesurfer/license.txt
. $FREESURFER_HOME/SetUpFreeSurfer.sh
# <<< FreeSurfer 7.3.2 <<<
'
        if ! grep -q "FREESURFER_HOME=/opt/freesurfer" ~/.bashrc; then
            echo "$FS_BASHRC_SNIPPET" >> ~/.bashrc
        fi
    """
    wsl(["bash", "-lc", fs_cmds], distro="NCGP")

    # Inject license via base64 (robust against path/quote issues)
    # This avoids depending on /mnt/c mounting or quoting Windows paths.
    inject_license = f"""
        set -e
        sudo mkdir -p /opt/freesurfer
        echo "{license_b64}" | base64 -d | sudo tee /opt/freesurfer/license.txt >/dev/null
        sudo chmod 644 /opt/freesurfer/license.txt
    """
    wsl(["bash", "-lc", inject_license], distro="NCGP")

    # -------- AFNI + SUMA (Ubuntu 20.04) --------
    afni_cmds = r"""
        set -e
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
            libglib2.0-0 libxext6 libxmu6 libxft2 libxi6 libxpm4 \
            libxm4 libgsl-dev gsl-bin netpbm xvfb xterm mesa-utils \
            libglw1-mesa libgl1-mesa-glx libglu1-mesa libjpeg-turbo8 \
            libxrender1 ca-certificates curl tcsh python3 python3-pip

        cd /opt
        if [ ! -f linux_ubuntu_20_64.tgz ]; then
            curl -fsSLO https://afni.nimh.nih.gov/pub/dist/bin/linux_ubuntu_20_64.tgz
        fi
        sudo mkdir -p /opt/afni
        sudo tar -xzf linux_ubuntu_20_64.tgz -C /opt/afni --strip-components=1

        AFNI_BASHRC_SNIPPET='
# >>> AFNI+SUMA >>>
export PATH=/opt/afni:$PATH
export AFNI_PLUGINPATH=/opt/afni
export SUMA_HOME=/opt/afni
# <<< AFNI+SUMA <<<
'
        if ! grep -q "export PATH=/opt/afni" ~/.bashrc; then
            echo "$AFNI_BASHRC_SNIPPET" >> ~/.bashrc
        fi

        /opt/afni/afni -ver || true
        /opt/afni/suma -ver || true

        echo "AFNI+SUMA install complete."
    """
    wsl(["bash", "-lc", afni_cmds], distro="NCGP")

    print("\nInside NCGP:\n- FreeSurfer 7.3.2 installed in /opt/freesurfer (license placed)\n- AFNI+SUMA installed in /opt/afni\n")
    print("Reminder: If you ever replace the license, keep it at /opt/freesurfer/license.txt")


# ----------------------------
# Main Orchestration
# ----------------------------
def main():
    # 0) Validate the license file now (fail-fast)
    license_b64 = assert_license_file_and_get_b64()

    # 1) Auto-elevate to Administrator
    if not is_admin():
        print("Requesting Administrator privileges ...")
        try:
            relaunch_as_admin()
        except Exception:
            print("Unable to elevate to Administrator. Exiting.")
        sys.exit(0)

    # 2) Ensure WSL feature (WSL 1)
    ensure_wsl_cli_available()
    enable_feature_and_maybe_reboot("Microsoft-Windows-Subsystem-Linux")

    # 3) Make WSL1 the default
    set_wsl_default_version(1)

    # 4) Install Ubuntu-20.04 if needed
    install_ubuntu_2004_if_needed()

    # 5) Rename to NCGP, ensure WSL 1, set default
    rename_ubuntu_to_ncgp_and_force_version_1()

    # 6) Install FreeSurfer + AFNI/SUMA (and inject license)
    install_freesurfer_732_and_afni_suma_in_ncgp(license_b64)

    print("\nAll done ✅\n")
    print("Open a new terminal and run:  wsl -d NCGP")
    print("Then verify:")
    print("  source ~/.bashrc && afni -ver && suma -ver")
    print("And for FreeSurfer:")
    print("  source ~/.bashrc && mri_convert --help")


if __name__ == "__main__":
    main()
