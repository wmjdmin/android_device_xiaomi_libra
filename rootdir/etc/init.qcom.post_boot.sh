#!/system/bin/sh
# Copyright (c) 2012-2013, The Linux Foundation. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of The Linux Foundation nor
#       the names of its contributors may be used to endorse or promote
#       products derived from this software without specific prior written
#       permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NON-INFRINGEMENT ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR
# CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
# OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
# ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#

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

LOG_TAG="init_qcom_post"
LOG_NAME="${0}:"

loge ()
{
  /system/bin/log -t $LOG_TAG -p e "$@"
}

logi ()
{
  /system/bin/log -t $LOG_TAG -p i "$@"
}

logi "Begin"

# ensure at most one A57 is online when thermal hotplug is disabled
write /sys/devices/system/cpu/cpu5/online 0

# in case CPU4 is online, limit its frequency
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 960000

# Limit A57 max freq from msm_perf module in case CPU 4 is offline
write /sys/module/msm_performance/parameters/cpu_max_freq "4:960000 5:960000"

# disable thermal bcl hotplug to switch governor
write /sys/module/msm_thermal/core_control/enabled 0
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
bcl_hotplug_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask 0`
bcl_hotplug_soc_mask=`get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask 0`
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# some files in /sys/devices/system/cpu are created after the restorecon of
# /sys/. These files receive the default label "sysfs".
# Restorecon again to give new files the correct label.
restorecon -R /sys/devices/system/cpu

# Disable CPU retention
write /sys/module/lpm_levels/system/a53/cpu0/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu1/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu2/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a53/cpu3/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/cpu4/retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/cpu5/retention/idle_enabled 0

# Disable L2 retention
write /sys/module/lpm_levels/system/a53/a53-l2-retention/idle_enabled 0
write /sys/module/lpm_levels/system/a57/a57-l2-retention/idle_enabled 0

# Configure governor settings for little cluster
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor interactive
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
write /sys/devices/system/cpu/cpu0/cpufreq/interactive/boostpulse_duration 0
write /sys/devices/system/cpu/cpu0/cpufreq/scaling_min_freq 302400

# online CPU4
write /sys/devices/system/cpu/cpu4/online 1
restorecon -R /sys/devices/system/cpu # must restore after online

# Best effort limiting for first time boot if msm_performance module is absent
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq 960000

# configure governor settings for big cluster
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
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/boostpulse_duration 0
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/min_sample_time 40000
write /sys/devices/system/cpu/cpu4/cpufreq/interactive/max_freq_hysteresis 80000
write /sys/devices/system/cpu/cpu4/cpufreq/scaling_min_freq 302400
# restore A57's max
copy /sys/devices/system/cpu/cpu4/cpufreq/cpuinfo_max_freq /sys/devices/system/cpu/cpu4/cpufreq/scaling_max_freq

# Plugin remaining A57s
write /sys/devices/system/cpu/cpu5/online 1
write /sys/module/lpm_levels/parameters/sleep_disabled 0

# Restore CPU 4 max freq from msm_performance
write /sys/module/msm_performance/parameters/cpu_max_freq "4:4294967295 5:4294967295"

# input boost configuration
#write 0:864000 > /sys/module/cpu_boost/parameters/input_boost_freq
write /sys/module/cpu_boost/parameters/input_boost_freq "0:600000 1:0 2:0 3:0 4:0 5:0"
write /sys/module/cpu_boost/parameters/input_boost_ms 40

# core_ctl module
write /sys/devices/system/cpu/cpu4/core_ctl/min_cpus 2
write /sys/devices/system/cpu/cpu4/core_ctl/busy_up_thres 60
write /sys/devices/system/cpu/cpu4/core_ctl/busy_down_thres 30
write /sys/devices/system/cpu/cpu4/core_ctl/offline_delay_ms 100
write /sys/devices/system/cpu/cpu4/core_ctl/is_big_cluster 1
write /sys/devices/system/cpu/cpu4/core_ctl/task_thres 2

# Setting b.L scheduler parameters
write /proc/sys/kernel/sched_migration_fixup 1
write /proc/sys/kernel/sched_small_task 15 
write /proc/sys/kernel/sched_mostly_idle_load 20
write /proc/sys/kernel/sched_mostly_idle_nr_run 3
write /proc/sys/kernel/sched_upmigrate 85
write /proc/sys/kernel/sched_downmigrate 70
write /proc/sys/kernel/sched_cpu_high_irqload 7500000
write /proc/sys/kernel/sched_heavy_task 60
write /proc/sys/kernel/sched_init_task_load 65
write /proc/sys/kernel/sched_min_runtime 200000000
write /proc/sys/kernel/sched_freq_inc_notify 400000
write /proc/sys/kernel/sched_freq_dec_notify 400000

#enable rps static configuration
write /sys/class/net/rmnet_ipa0/queues/rx-0/rps_cpus 8
get-set-forall /sys/class/devfreq/qcom,cpubw*/governor bw_hwmon
restorecon -R /sys/class/devfreq/qcom,cpubw*
get-set-forall /sys/class/devfreq/qcom,mincpubw*/governor cpufreq

# set GPU default power level to 5 (180MHz) instead of 4 (305MHz)
write /sys/class/kgsl/kgsl-3d0/default_pwrlevel 5

# android background processes are set to nice 10. Never schedule these on the a57s.
write /proc/sys/kernel/sched_upmigrate_min_nice 9

# Disable sched_boost
write /proc/sys/kernel/sched_boost 0

# perfd
ext=$(getprop "ro.vendor.extension_library")
if [ "$ext" = "libqti-perfd-client.so" ]; then
	rm /data/system/perfd/default_values
	setprop ro.min_freq_0 302400
	setprop ro.min_freq_4 302400
	start perfd
fi

# system permissions for performance profiles
chown -h system -R /sys/devices/system/cpu/
chown -h system -R /sys/module/msm_thermal/
chown -h system -R /sys/module/msm_performance/
chown -h system -R /sys/module/cpu_boost/
chown -h system -R /sys/devices/soc.0/qcom,bcl.*/
chown -h system -R /sys/class/devfreq/qcom,cpubw*/
chown -h system -R /sys/class/devfreq/qcom,mincpubw*/
chown -h system -R /sys/class/kgsl/kgsl-3d0/
chown -h system -R /sys/class/kgsl/kgsl-3d0/devfreq/

# ts power scripts permissions
chown -h system /system/etc/ts_power.sh
chown -h system /data/ts_power.sh

# re-enable thermal and BCL hotplug
write /sys/module/msm_thermal/core_control/enabled 1
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode disable
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_mask $bcl_hotplug_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/hotplug_soc_mask $bcl_hotplug_soc_mask
get-set-forall /sys/devices/soc.0/qcom,bcl.*/mode enable

# Let kernel know our image version/variant/crm_version
image_version="10:"
image_version+=`getprop ro.build.id`
image_version+=":"
image_version+=`getprop ro.build.version.incremental`
image_variant=`getprop ro.product.name`
image_variant+="-"
image_variant+=`getprop ro.build.type`
oem_version=`getprop ro.build.version.codename`
write /sys/devices/soc0/select_image 10
write /sys/devices/soc0/image_version $image_version
write /sys/devices/soc0/image_variant $image_variant
write /sys/devices/soc0/image_crm_version $oem_version

# Start RIDL/LogKit II client
#su -c /system/vendor/bin/startRIDL.sh &

# Fix GMS permissions regression..
# https://github.com/opengapps/opengapps/issues/200
pm grant com.google.android.gms android.permission.ACCESS_FINE_LOCATION
pm grant com.google.android.gms android.permission.ACCESS_COARSE_LOCATION
pm grant com.google.android.setupwizard android.permission.READ_PHONE_STATE

# Fix browser geolocation
pm grant com.android.browser android.permission.ACCESS_FINE_LOCATION
pm grant com.android.browser android.permission.ACCESS_COARSE_LOCATION

# Fix google contacts sync
pm grant com.google.android.syncadapters.contacts android.permission.READ_CONTACTS
pm grant com.google.android.syncadapters.contacts android.permission.WRITE_CONTACTS

# Fix google exchange contacts/calendar sync
pm grant com.google.android.gm.exchange android.permission.READ_CONTACTS
pm grant com.google.android.gm.exchange android.permission.WRITE_CONTACTS
pm grant com.google.android.gm.exchange android.permission.READ_CALENDAR
pm grant com.google.android.gm.exchange android.permission.WRITE_CALENDAR

# post init done
setprop ts.post_init_done 1

profile=`getprop persist.ts.profile`
if [ "$profile" = "" ]; then
	# balanced by default
	profile=1
fi

# Call ts_power.sh, if found
if [ -f /data/ts_power.sh ]; then
	logi "Call /data/ts_power.sh set_profile $profile"
	sh /data/ts_power.sh set_profile $profile
elif [ -f /system/etc/ts_power.sh ]; then
	logi "Call /system/etc/ts_power.sh set_profile $profile"
	sh /system/etc/ts_power.sh set_profile $profile
fi

logi "Done"

