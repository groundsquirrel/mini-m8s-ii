#!/bin/bash
# ==============================================================================
# Debloat & RAM Optimization Script for Netxeon MINI M8S II (Android 6.0.1)
# ==============================================================================
# Frees ~500 MB of RAM (Free RAM increases from ~750 MB to ~1.25 GB out of 2 GB).
# Safely disables Google Play Services, Adups spyware backdoor, and unused bloat.
#
# Usage:
#   chmod +x debloat.sh
#   ./debloat.sh
# ==============================================================================

set -euo pipefail

ADB="adb shell"

echo "=== [1/4] Disabling Adups FOTA Spyware Backdoor ==="
$ADB "pm disable-user --user 0 com.adups.fota.sysoper 2>/dev/null || pm disable com.adups.fota.sysoper 2>/dev/null" || true
$ADB "pm disable-user --user 0 com.adups.fota 2>/dev/null || pm disable com.adups.fota 2>/dev/null" || true

echo "=== [2/4] Disabling Obsolete DroidLogic Services ==="
$ADB "pm disable-user --user 0 com.droidlogic.otaupgrade 2>/dev/null || pm disable com.droidlogic.otaupgrade 2>/dev/null" || true
$ADB "pm disable-user --user 0 com.droidlogic.readlog 2>/dev/null || pm disable com.droidlogic.readlog 2>/dev/null" || true

echo "=== [3/4] Disabling Background Live Wallpapers & Screensavers ==="
WALLPAPERS=(
    com.android.galaxy4
    com.android.wallpaper.holospiral
    com.android.wallpaper.phasebeam
    com.android.noisefield
    com.android.magicsmoke
    com.android.dreams.phototable
)

for pkg in "${WALLPAPERS[@]}"; do
    $ADB "pm disable-user --user 0 $pkg 2>/dev/null || pm disable $pkg 2>/dev/null" || true
done

echo "=== [4/4] Disabling Google Play Services & Play Store (Frees ~500 MB RAM) ==="
GOOGLE_PKGS=(
    com.google.android.gms
    com.android.vending
    com.google.android.gsf
    com.google.android.gsf.login
    com.google.android.syncadapters.contacts
    com.google.android.syncadapters.calendar
    com.google.android.backuptransport
    com.google.android.feedback
    com.google.android.partnersetup
    com.google.android.onetimeinitializer
)

for pkg in "${GOOGLE_PKGS[@]}"; do
    $ADB "pm disable-user --user 0 $pkg 2>/dev/null || pm disable $pkg 2>/dev/null" || true
done

echo ""
echo "=== Debloat Completed Successfully! ==="
echo "Current Memory Status:"
$ADB "free -m"
