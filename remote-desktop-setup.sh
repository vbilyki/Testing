#!/bin/bash
# Remote Desktop Setup Script
# Sets up a virtual desktop accessible via VNC or browser (noVNC)

set -e

VNC_PORT=5901
NOVNC_PORT=6080
DISPLAY_NUM=1
RESOLUTION="1280x800x24"
VNC_PASSWORD="${VNC_PASSWORD:-password}"

# Install required packages
install_packages() {
    echo "[*] Installing packages..."
    apt-get update -q
    apt-get install -y --fix-missing \
        x11vnc \
        novnc \
        websockify \
        openbox \
        dbus-x11 \
        Xvfb 2>/dev/null || true
    echo "[+] Packages installed."
}

# Stop any existing instances
stop_existing() {
    echo "[*] Stopping existing services..."
    pkill -f "Xvfb :${DISPLAY_NUM}" 2>/dev/null || true
    pkill -f x11vnc 2>/dev/null || true
    pkill -f websockify 2>/dev/null || true
    sleep 1
}

# Start the virtual display
start_display() {
    echo "[*] Starting virtual display :${DISPLAY_NUM} at ${RESOLUTION}..."
    Xvfb :${DISPLAY_NUM} -screen 0 ${RESOLUTION} &
    sleep 2
    echo "[+] Display :${DISPLAY_NUM} started."
}

# Start window manager
start_wm() {
    echo "[*] Starting Openbox window manager..."
    DISPLAY=:${DISPLAY_NUM} openbox-session &
    sleep 2
    echo "[+] Openbox started."
}

# Configure and start VNC
start_vnc() {
    echo "[*] Configuring VNC..."
    mkdir -p /root/.vnc
    x11vnc -storepasswd "${VNC_PASSWORD}" /root/.vnc/passwd

    echo "[*] Starting x11vnc on port ${VNC_PORT}..."
    x11vnc -display :${DISPLAY_NUM} \
        -rfbauth /root/.vnc/passwd \
        -rfbport ${VNC_PORT} \
        -forever \
        -noxdamage \
        -bg \
        -o /tmp/x11vnc.log
    echo "[+] VNC server started on port ${VNC_PORT}."
}

# Start noVNC web interface
start_novnc() {
    echo "[*] Starting noVNC on port ${NOVNC_PORT}..."
    websockify --web /usr/share/novnc/ ${NOVNC_PORT} localhost:${VNC_PORT} &
    sleep 1
    echo "[+] noVNC web interface started on port ${NOVNC_PORT}."
}

print_info() {
    echo ""
    echo "============================================"
    echo "  Remote Desktop is ready!"
    echo "============================================"
    echo ""
    echo "  Browser access (noVNC):"
    echo "    http://localhost:${NOVNC_PORT}/vnc.html"
    echo ""
    echo "  VNC client access:"
    echo "    Host: localhost"
    echo "    Port: ${VNC_PORT}"
    echo "    Password: ${VNC_PASSWORD}"
    echo ""
    echo "  To stop: pkill -f x11vnc; pkill -f websockify; pkill -f Xvfb"
    echo "============================================"
}

main() {
    if [[ "$1" == "--install" ]]; then
        install_packages
    fi
    stop_existing
    start_display
    start_wm
    start_vnc
    start_novnc
    print_info
}

main "$@"
