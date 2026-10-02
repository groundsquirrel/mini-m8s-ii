#!/bin/bash
# ==============================================================================
# One-click installer for Netxeon MINI M8S II (Amlogic S905X) optimizations
# ==============================================================================

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Checking ADB connection..."
adb get-state >/dev/null 2>&1 || {
    echo "Error: Device not connected via ADB."
    echo "Connect using: adb connect <TV_BOX_IP>:5555"
    exit 1
}

echo "1. Remounting /system read-write..."
adb shell "su -c 'mount -o remount,rw /system'"

echo "2. Pushing performance script to /system/su.d/01_performance.sh..."
adb push "${SCRIPT_DIR}/01_performance.sh" /sdcard/01_performance.sh
adb shell "su -c 'mkdir -p /system/su.d && cp /sdcard/01_performance.sh /system/su.d/01_performance.sh && chmod 755 /system/su.d/01_performance.sh && rm /sdcard/01_performance.sh'"

echo "3. Applying kernel and system tweaks immediately..."
adb shell "su -c 'sh /system/su.d/01_performance.sh'"

echo "4. Running debloat to free ~500 MB RAM..."
bash "${SCRIPT_DIR}/debloat.sh"

echo "5. Remounting /system read-only..."
adb shell "su -c 'mount -o remount,ro /system'"

echo ""
echo "=== All optimizations installed and running! ==="
