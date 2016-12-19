/*
 * Copyright (C) 2016 The CyanogenMod Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#define LOG_TAG "libra PowerHAL"

#include <hardware/hardware.h>
#include <hardware/power.h>

#include <stdbool.h>
#include <errno.h>
#include <fcntl.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#include <utils/Log.h>

#include "power.h"

#define NODE_MAX (64)
#define LITTLE_CPUFREQ_LIMIT_PATH "/sys/devices/system/cpu/cpu0/cpufreq/"
#define LITTLE_INTERACTIVE_PATH "/sys/devices/system/cpu/cpu0/cpufreq/interactive/"
#define BIG_CPUFREQ_LIMIT_PATH "/sys/devices/system/cpu/cpu4/cpufreq/"
#define BIG_INTERACTIVE_PATH "/sys/devices/system/cpu/cpu4/cpufreq/interactive/"
#define BIG_MIN_CPU_PATH "/sys/devices/system/cpu/cpu4/core_ctl/"
#define BIG_MAX_CPU_PATH "/sys/devices/system/cpu/cpu4/core_ctl/"
#define TAP_TO_WAKE_NODE "/proc/touchscreen/double_tap_enable"

static pthread_mutex_t lock = PTHREAD_MUTEX_INITIALIZER;
static int boostpulse_fd = -1;

static int current_power_profile = -1;
static int requested_power_profile = -1;

static int sysfs_write_str(char *path, char *s)
{
    char buf[80];
    int len;
    int ret = 0;
    int fd;

    fd = open(path, O_WRONLY);
    if (fd < 0) {
        strerror_r(errno, buf, sizeof(buf));
        ALOGE("Error opening %s: %s\n", path, buf);
        return -1 ;
    }

    len = write(fd, s, strlen(s));
    if (len < 0) {
        strerror_r(errno, buf, sizeof(buf));
        ALOGE("Error writing to %s: %s\n", path, buf);
        ret = -1;
    }

    close(fd);

    return ret;
}

static int sysfs_write_int(char *path, int value)
{
    char buf[80];
    snprintf(buf, 80, "%d", value);
    return sysfs_write_str(path, buf);
}

static bool check_governor(void)
{
    struct stat s;
    int err = stat(LITTLE_INTERACTIVE_PATH, &s);
    if (err != 0) return false;
    if (S_ISDIR(s.st_mode)) return true;
    return false;
}

static int is_profile_valid(int profile)
{
    return profile >= 0 && profile < PROFILE_MAX;
}

static void power_init(__attribute__((unused)) struct power_module *module)
{
    ALOGI("%s", __func__);
}

static int boostpulse_open()
{
    pthread_mutex_lock(&lock);
    if (boostpulse_fd < 0) {
        boostpulse_fd = open(LITTLE_INTERACTIVE_PATH "boostpulse", O_WRONLY);
    }
    pthread_mutex_unlock(&lock);

    return boostpulse_fd;
}

static void power_set_interactive(__attribute__((unused)) struct power_module *module, int on)
{
    if (!is_profile_valid(current_power_profile)) {
        ALOGD("%s: no power profile selected yet", __func__);
        return;
    }

    // break out early if governor is not interactive
    if (!check_governor()) return;

    if (current_power_profile == PROFILE_POWER_SAVE || current_power_profile == PROFILE_BIAS_POWER) {
		ALOGD("Device is in power save mode, disabling big CPU cluster");
		sysfs_write_str(BIG_MAX_CPU_PATH "max_cpus", "0");
        sysfs_write_str(BIG_MIN_CPU_PATH "min_cpus", "0");
    } else if (current_power_profile == PROFILE_BALANCED) {
        if (!on) {
		    ALOGD("Screen is OFF, disabling big CPU cluster");
            sysfs_write_str(BIG_MAX_CPU_PATH "max_cpus", "0");
            sysfs_write_str(BIG_MIN_CPU_PATH "min_cpus", "0");
        } else {
		    ALOGD("Screen is ON, enabling big CPU cluster");
	        sysfs_write_str(BIG_MAX_CPU_PATH "max_cpus", "2");
            sysfs_write_str(BIG_MIN_CPU_PATH "min_cpus", "0");
        }
    } else if (current_power_profile == PROFILE_BIAS_PERFORMANCE || current_power_profile == PROFILE_HIGH_PERFORMANCE) {
		if (!on) {
		    ALOGD("Screen is OFF, disabling big CPU cluster");
            sysfs_write_str(BIG_MAX_CPU_PATH "max_cpus", "0");
            sysfs_write_str(BIG_MIN_CPU_PATH "min_cpus", "0");
        } else {
		    ALOGD("Screen is ON, enabling big CPU cluster");
	        sysfs_write_str(BIG_MAX_CPU_PATH "max_cpus", "2");
            sysfs_write_str(BIG_MIN_CPU_PATH "min_cpus", "2");
        }
    }
}

static void set_power_profile(int profile)
{
    if (!is_profile_valid(profile)) {
        ALOGE("%s: unknown profile: %d", __func__, profile);
        return;
    }

    // break out early if governor is not interactive
    if (!check_governor()) return;

    if (profile == current_power_profile)
        return;

    ALOGD("%s: setting profile %d", __func__, profile);

    /* Little cluster */
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "boost",
                    profiles[profile].little_boost);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "boostpulse_duration",
                    profiles[profile].little_boostpulse_duration);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "go_hispeed_load",
                    profiles[profile].little_go_hispeed_load);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "hispeed_freq",
                    profiles[profile].little_hispeed_freq);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "io_is_busy",
                    profiles[profile].little_io_is_busy);
    sysfs_write_str(LITTLE_INTERACTIVE_PATH "above_hispeed_delay",
                    profiles[profile].little_above_hispeed_delay);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "timer_rate",
                    profiles[profile].little_timer_rate);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "min_sample_time",
                    profiles[profile].little_min_sample_time);
    sysfs_write_int(LITTLE_INTERACTIVE_PATH "max_freq_hysteresis",
                    profiles[profile].little_max_freq_hysteresis);
    sysfs_write_str(LITTLE_INTERACTIVE_PATH "target_loads",
                    profiles[profile].little_target_loads);
    sysfs_write_int(LITTLE_CPUFREQ_LIMIT_PATH "scaling_min_freq",
                    profiles[profile].little_scaling_min_freq);
    sysfs_write_int(LITTLE_CPUFREQ_LIMIT_PATH "scaling_max_freq",
                    profiles[profile].little_scaling_max_freq);
    /* Big cluster */
    sysfs_write_int(BIG_INTERACTIVE_PATH "boost",
                    profiles[profile].big_boost);
    sysfs_write_int(BIG_INTERACTIVE_PATH "boostpulse_duration",
                    profiles[profile].big_boostpulse_duration);
    sysfs_write_int(BIG_INTERACTIVE_PATH "go_hispeed_load",
                    profiles[profile].big_go_hispeed_load);
    sysfs_write_int(BIG_INTERACTIVE_PATH "hispeed_freq",
                    profiles[profile].big_hispeed_freq);
    sysfs_write_int(BIG_INTERACTIVE_PATH "io_is_busy",
                    profiles[profile].big_io_is_busy);
    sysfs_write_str(BIG_INTERACTIVE_PATH "above_hispeed_delay",
                    profiles[profile].big_above_hispeed_delay);
    sysfs_write_int(BIG_INTERACTIVE_PATH "timer_rate",
                    profiles[profile].big_timer_rate);
    sysfs_write_int(BIG_INTERACTIVE_PATH "min_sample_time",
                    profiles[profile].big_min_sample_time);
    sysfs_write_int(BIG_INTERACTIVE_PATH "max_freq_hysteresis",
                    profiles[profile].big_max_freq_hysteresis);
    sysfs_write_str(BIG_INTERACTIVE_PATH "target_loads",
                    profiles[profile].big_target_loads);
    sysfs_write_int(BIG_CPUFREQ_LIMIT_PATH "scaling_min_freq",
                    profiles[profile].big_scaling_min_freq);
    sysfs_write_int(BIG_CPUFREQ_LIMIT_PATH "scaling_max_freq",
                    profiles[profile].big_scaling_max_freq);
    sysfs_write_int(BIG_MIN_CPU_PATH "min_cpus",
                    profiles[profile].big_min_cpus);
    sysfs_write_int(BIG_MAX_CPU_PATH "max_cpus",
                    profiles[profile].big_max_cpus);

    current_power_profile = profile;
}

static void power_hint(__attribute__((unused)) struct power_module *module,
                       power_hint_t hint, void *data)
{
    char buf[80];
    int len;

    switch (hint) {
    case POWER_HINT_INTERACTION:
    case POWER_HINT_LAUNCH_BOOST:
    case POWER_HINT_CPU_BOOST:
        if (!is_profile_valid(current_power_profile)) {
            ALOGD("%s: no power profile selected yet", __func__);
            return;
        }

        if (!profiles[current_power_profile].little_boostpulse_duration)
            return;

        // break out early if governor is not interactive
        if (!check_governor()) return;

        if (boostpulse_open() >= 0) {
            snprintf(buf, sizeof(buf), "%d", 1);
            len = write(boostpulse_fd, &buf, sizeof(buf));
            if (len < 0) {
                strerror_r(errno, buf, sizeof(buf));
                ALOGE("Error writing to boostpulse: %s\n", buf);

                pthread_mutex_lock(&lock);
                close(boostpulse_fd);
                boostpulse_fd = -1;
                pthread_mutex_unlock(&lock);
            }
        }
        break;
    case POWER_HINT_SET_PROFILE:
        pthread_mutex_lock(&lock);
        set_power_profile(*(int32_t *)data);
        pthread_mutex_unlock(&lock);
        break;
    case POWER_HINT_LOW_POWER:
        /* This hint is handled by the framework */
        break;
    default:
        break;
    }
}

static struct hw_module_methods_t power_module_methods = {
    .open = NULL,
};

void set_feature(struct power_module *module, feature_t feature, int state)
{
    char tmp_str[NODE_MAX];
    if (feature == POWER_FEATURE_DOUBLE_TAP_TO_WAKE) {
        snprintf(tmp_str, NODE_MAX, "%d", state);
        sysfs_write_str(TAP_TO_WAKE_NODE, tmp_str);
        return;
    }
}

static int get_feature(__attribute__((unused)) struct power_module *module,
                       feature_t feature)
{
    if (feature == POWER_FEATURE_SUPPORTED_PROFILES) {
        return PROFILE_MAX;
    }
    return -1;
}

struct power_module HAL_MODULE_INFO_SYM = {
    .common = {
        .tag = HARDWARE_MODULE_TAG,
        .module_api_version = POWER_MODULE_API_VERSION_0_2,
        .hal_api_version = HARDWARE_HAL_API_VERSION,
        .id = POWER_HARDWARE_MODULE_ID,
        .name = "libra Power HAL",
        .author = "Gabriele M",
        .methods = &power_module_methods,
    },

    .init = power_init,
    .setInteractive = power_set_interactive,
    .powerHint = power_hint,
    .setFeature = set_feature,
    .getFeature = get_feature
};
