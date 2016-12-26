#!/system/bin/sh

################################################################################
# helper functions to allow Android init like script

function write() {
    echo -n $2 > $1
}

function copy() {
    cat $1 > $2
}

function get-set-forall() {
    for f in $1 ; do
        cat $f
        write $f $2
    done
}

################################################################################

LOG_TAG="TS PowerHAL (sh)"
LOG_NAME="${0}:"

loge ()
{
  /system/bin/log -t $LOG_TAG -p e "$@"
}

logi ()
{
  /system/bin/log -t $LOG_TAG -p i "$@"
}

action=$1
value=$2
logi "action is ($action)"
logi "value is ($value)"

profile=`getprop persist.ts.profile`
logi "persist.ts.profile is ($profile)"

# Handle display on/off
if [ "$action" = "set_interactive" ]; then
    if [ "$value" = "0" ]; then
        # Display off
        # Turn off big cluster while display is off
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 0
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 0
    else
        # Display on
        # Turn on big cluster while display is on
        case "$profile" in
            "0"|"3")
                # POWER_SAVE / PROFILE_BIAS_POWER_SAVE -> big cluster off
                write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 0
                write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 0
            ;;
            "2"|"4")
                # HIGH_PERFORMANCE / BIAS_PERFORMANCE -> big cluster on
                write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
                write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 2
            ;;
            *)
                # BALANCED
                write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
                write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 0
            ;;
        esac
    fi
    exit 0
fi

perfd_running=$(getprop "init.svc.perfd")
if [ "$perfd_running" = "running" ]; then
    # Stop perfd while tuning params
    logi "Stopping perfd"
    stop perfd
fi

# Make sure core_ctl does not hotplug big cluster
write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 2

# Disable thermal and bcl hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
bcl_hotplug_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask 0`
bcl_hotplug_soc_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask 0`
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# Make sure CPU4 is online for config
write /sys/devices/system/cpu/cpu4/online 1

# some files in /sys/devices/system/cpu are created after the restorecon of
# /sys/. These files receive the default label "sysfs".
# Restorecon again to give new files the correct label.
restorecon -R /sys/devices/system/cpu

# Just note to self
# /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_frequencies
# 302400 384000 460800 600000 672000 787200 864000 960000 1248000 1440000
# /sys/devices/system/cpu/cpu4/cpufreq/scaling_available_frequencies
# 302400 384000 480000 633600 768000 864000 960000 1248000 1344000 1440000 1536000 1632000 1689600 1824000
# /sys/class/kgsl/kgsl-3d0/gpu_available_frequencies
# 600000000 490000000 450000000 367000000 300000000 180000000
# /sys/class/kgsl/kgsl-3d0/devfreq/available_governors
# spdm_bw_hyp bw_hwmon bw_vbif gpubw_mon msm-adreno-tz cpufreq userspace powersave performance simple_ondemand

# Handle power profile change
case "$profile" in
    # PROFILE_POWER_SAVE = 0
    # Power save profile
    #   This mode sacrifices performance for maximum power saving.
    "0")
        logi "POWER_SAVE"

        # Configure governor settings for little cluster
        #write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor smartmax
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 99
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 50000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 600000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "65 460800:63 600000:45 672000:35 787200:47 864000:78 960000:82 1248000:86 1440000:99"      
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 50000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 0
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration 0
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 864000

        # Big cluster always off
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 0
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 0

        # 0ms input boost
        write /sys/module/cpu_boost/parameters/input_boost_freq 0
        write /sys/module/cpu_boost/parameters/input_boost_ms 0

        # 180Mhz GPU max speed
        write /sys/class/kgsl/kgsl-3d0/devfreq/governor powersave
        write /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 180000000
        write /sys/class/kgsl/kgsl-3d0/min_pwrlevel 5
        write /sys/class/kgsl/kgsl-3d0/max_pwrlevel 5
        write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5
        ;;

    # PROFILE_BIAS_POWER_SAVE = 3
    # Power save bias profile
    #   This mode decreases performance slightly to improve power savings.
    "3")
        logi "PROFILE_BIAS_POWER_SAVE"

        # Configure governor settings for little cluster
        #write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor smartmax
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 99
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 50000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 600000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "65 460800:63 600000:45 672000:35 787200:47 864000:78 960000:82 1248000:86 1440000:99"      
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 50000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 0
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration 0
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1440000

        # Big cluster always off
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 0
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 0

        # 0ms input boost
        write /sys/module/cpu_boost/parameters/input_boost_freq 0
        write /sys/module/cpu_boost/parameters/input_boost_ms 0

        # 180Mhz GPU max speed
        write /sys/class/kgsl/kgsl-3d0/devfreq/governor powersave
        write /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 180000000
        write /sys/class/kgsl/kgsl-3d0/min_pwrlevel 5
        write /sys/class/kgsl/kgsl-3d0/max_pwrlevel 5
        write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5
        ;;

    # PROFILE_BALANCED = 1
    # Balanced power profile
    #   The default mode for balanced power savings and performance
    "1")
        logi "BALANCED"

        # Configure governor settings for little cluster
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 99
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 50000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 600000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads "65 460800:63 600000:45 672000:35 787200:47 864000:78 960000:82 1248000:86 1440000:99"
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 20000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 0
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration 40
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1440000

        # Configure governor settings for big cluster
        write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay "50000 1440000:20000"
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 80
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 50000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 633600
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads "95 633600:75 768000:80 864000:81 960000:81 1248000:85 1344000:85 1440000:85 1536000:85 1632000:86 1824000:87"
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration 0
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 50000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 0

        # Big cluster hotplugged by core_ctl
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 0

        # 40ms input boost @ 600Mhz (only little cluster)
        write /sys/module/cpu_boost/parameters/input_boost_freq "0:600000 1:600000 2:600000 3:600000 4:0 5:0"
        write /sys/module/cpu_boost/parameters/input_boost_ms 40

        # 367Mhz GPU max speed
        write /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
        write /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 367000000
        write /sys/class/kgsl/kgsl-3d0/min_pwrlevel 5
        write /sys/class/kgsl/kgsl-3d0/max_pwrlevel 3
        write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5
        ;;

    # PROFILE_BIAS_PERFORMANCE = 4
    # Performance bias profile
    #   This mode improves performance at the cost of some power.
    "4")
        logi "BIAS_PERFORMANCE"

        # Configure governor settings for little cluster
        write "interactive" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/go_hispeed_load 90
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/timer_rate 20000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/hispeed_freq 1248000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/target_loads 65
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/min_sample_time 20000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/max_freq_hysteresis 80000
        write /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration 40
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1440000

        # Configure governor settings for big cluster
        write /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 80
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 20000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 1248000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads 85
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration 40
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 40000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 80000

        # Big cluster always on
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 2

        # 40ms input boost @ 1.2Ghz
        write /sys/module/cpu_boost/parameters/input_boost_freq "0:1248000 1:1248000 2:1248000 3:1248000 4:1248000 5:1248000"
        write /sys/module/cpu_boost/parameters/input_boost_ms 40

        # 600Mhz GPU max speed
        write /sys/class/kgsl/kgsl-3d0/devfreq/governor msm-adreno-tz
        write /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 600000000
        write /sys/class/kgsl/kgsl-3d0/min_pwrlevel 5
        write /sys/class/kgsl/kgsl-3d0/max_pwrlevel 0
        write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5
        ;;

    # PROFILE_HIGH_PERFORMANCE = 2
    # High-performance profile
    #   This mode sacrifices power for maximum performance
    "2")
        logi "HIGH_PERFORMANCE"

        # Configure governor settings for little cluster
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_max_freq 1440000
        write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor performance
        restorecon -R /sys/devices/system/cpu # must restore after performance

        # Configure governor settings for big cluster
        write "interactive" > /sys/devices/system/cpu/cpu4/cpufreq/scaling_governor interactive
        restorecon -R /sys/devices/system/cpu # must restore after interactive
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_sched_load 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/use_migration_notif 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/above_hispeed_delay 19000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/go_hispeed_load 80
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/timer_rate 20000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/hispeed_freq 1248000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/io_is_busy 1
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/target_loads 85
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration 100
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 40000
        write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 80000

        # Big cluster always on
        write /sys/devices/system/cpu/cpu4/core_ctl/max_cpus 2
        write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 2

        # 100ms input boost @ 1.4Ghz / 1.8Ghz
        write /sys/module/cpu_boost/parameters/input_boost_freq "0:1440000 1:1440000 2:1440000 3:1440000 4:1824000 5:1824000"
        write /sys/module/cpu_boost/parameters/input_boost_ms 100

        # 600Mhz GPU min and max speed
        # GPU locked at 600Mhz
        write /sys/class/kgsl/kgsl-3d0/devfreq/governor performance
        write /sys/class/kgsl/kgsl-3d0/devfreq/min_freq 600000000
        write /sys/class/kgsl/kgsl-3d0/devfreq/max_freq 600000000
        write /sys/class/kgsl/kgsl-3d0/min_pwrlevel 0
        write /sys/class/kgsl/kgsl-3d0/max_pwrlevel 0
        write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 0
        ;;

    *)
        ;;
esac

# Re-enable thermal and BCL hotplug
write /sys/module/msm_thermal/core_control/enabled 1
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask $bcl_hotplug_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask $bcl_hotplug_soc_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

if [ "$perfd_running" = "running" ]; then
    # Restart perfd
    logi "Restarting perfd"
    rm /data/system/perfd/default_values
    start perfd
fi

