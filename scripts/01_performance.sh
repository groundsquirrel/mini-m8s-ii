#!/system/bin/sh
# ==============================================================================
# Performance & Streaming Optimization for Netxeon MINI M8S II (Amlogic S905X)
# ==============================================================================
# Location on device: /system/su.d/01_performance.sh
# Permissions: chmod 755
# Executed automatically at boot by SuperSU daemonsu
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. CPU Configuration: Keep all 4 cores active & switch governor to interactive
# ------------------------------------------------------------------------------
# Stock firmware uses aggressive 'hotplug' that permanently sleeps cores 1-3.
echo 1 > /sys/devices/system/cpu/cpu1/online 2>/dev/null
echo 1 > /sys/devices/system/cpu/cpu2/online 2>/dev/null
echo 1 > /sys/devices/system/cpu/cpu3/online 2>/dev/null

# Switch governor to interactive
echo interactive > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null

# Boost minimum frequency to 500 MHz (prevents UI frame drops from 100 MHz idle)
echo 500000 > /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 2>/dev/null

# Interactive governor parameters for snappy UI and video responsiveness
if [ -d /sys/devices/system/cpu/cpufreq/interactive ]; then
    echo 1 > /sys/devices/system/cpu/cpufreq/interactive/io_is_busy 2>/dev/null
    echo 1000000 > /sys/devices/system/cpu/cpufreq/interactive/hispeed_freq 2>/dev/null
    echo 70 > /sys/devices/system/cpu/cpufreq/interactive/go_hispeed_load 2>/dev/null
    echo 20000 > /sys/devices/system/cpu/cpufreq/interactive/min_sample_time 2>/dev/null
fi

# ------------------------------------------------------------------------------
# 2. Flash Storage I/O Optimization (eMMC)
# ------------------------------------------------------------------------------
# Default 'cfq' scheduler has high seek/dispatch overhead on eMMC.
# 'deadline' ensures low latency for read operations (smooth app launching).
if [ -f /sys/block/mmcblk0/queue/scheduler ]; then
    echo deadline > /sys/block/mmcblk0/queue/scheduler 2>/dev/null
    echo 512 > /sys/block/mmcblk0/queue/read_ahead_kb 2>/dev/null
    echo 0 > /sys/block/mmcblk0/queue/iostats 2>/dev/null
fi

# ------------------------------------------------------------------------------
# 3. Virtual Memory & Cache Tuning
# ------------------------------------------------------------------------------
# Keep directory/inode caches in RAM longer (default is 100)
sysctl -w vm.vfs_cache_pressure=70 2>/dev/null
# Flush dirty memory pages gradually to avoid I/O stalls
sysctl -w vm.dirty_ratio=20 2>/dev/null
sysctl -w vm.dirty_background_ratio=5 2>/dev/null

# ------------------------------------------------------------------------------
# 4. Network Socket Buffers (Streaming & TorrServer Optimization)
# ------------------------------------------------------------------------------
# Expand TCP buffers to 2 MB to prevent stutter on 1080p/4K bitrate spikes
sysctl -w net.core.rmem_max=2097152 2>/dev/null
sysctl -w net.core.wmem_max=2097152 2>/dev/null
sysctl -w net.ipv4.tcp_rmem="4096 87380 2097152" 2>/dev/null
sysctl -w net.ipv4.tcp_wmem="4096 65536 2097152" 2>/dev/null

# ------------------------------------------------------------------------------
# 5. UI Animations & Hardware Acceleration
# ------------------------------------------------------------------------------
settings put global window_animation_scale 0.0 2>/dev/null
settings put global transition_animation_scale 0.0 2>/dev/null
settings put global animator_duration_scale 0.0 2>/dev/null
setprop debug.sf.hw 1 2>/dev/null
setprop debug.egl.hw 1 2>/dev/null

# ------------------------------------------------------------------------------
# 6. Persistent ADB Network Port
# ------------------------------------------------------------------------------
# Keep port 5555 open across reboots without requiring USB reconnection
setprop service.adb.tcp.port 5555

exit 0
