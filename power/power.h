/*
 * Copyright (C) 2015 The CyanogenMod Project
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

enum {
    PROFILE_POWER_SAVE = 0,
    PROFILE_BIAS_POWER,
    PROFILE_BALANCED,
    PROFILE_BIAS_PERFORMANCE,
    PROFILE_HIGH_PERFORMANCE,
    PROFILE_MAX
};

typedef struct governor_settings {
    int is_interactive;
    /* Little cluster */
    int little_boost;
    int little_boostpulse_duration;
    int little_go_hispeed_load;
    int little_hispeed_freq;
    int little_io_is_busy;
    int little_timer_rate;
    char *little_above_hispeed_delay;
    int little_min_sample_time;
    int little_max_freq_hysteresis;
    char *little_target_loads;
    int little_scaling_min_freq;
    int little_scaling_max_freq;
    /* Big cluster */
    int big_boost;
    int big_boostpulse_duration;
    int big_go_hispeed_load;
    int big_hispeed_freq;
    int big_io_is_busy;
    int big_timer_rate;
    char *big_above_hispeed_delay;
    int big_min_sample_time;
    int big_max_freq_hysteresis;
    char *big_target_loads;
    int big_scaling_min_freq;
    int big_scaling_max_freq;
    int big_min_cpus;
    int big_max_cpus;
} power_profile;

static power_profile profiles[PROFILE_MAX] = {
    [PROFILE_POWER_SAVE] = {
        /* Little cluster */
        .little_boost = 0,
        .little_boostpulse_duration = 0,
        .little_go_hispeed_load = 99,
        .little_hispeed_freq = 600000,
        .little_io_is_busy = 1,
        .little_timer_rate = 50000,
        .little_above_hispeed_delay = "19000",
        .little_min_sample_time = 50000,
        .little_max_freq_hysteresis = 0,
        .little_target_loads = "71 384000:75 460000:69 600000:80 672000:76 787000:81 864000:81 960000:69 1248000:78",
        .little_scaling_min_freq = 302400,
        .little_scaling_max_freq = 1440000,
        /* Big cluster */
        .big_min_cpus = 0,
        .big_max_cpus = 0,
    },
    [PROFILE_BIAS_POWER] = {
        /* Little cluster */
        .little_boost = 0,
        .little_boostpulse_duration = 0,
        .little_go_hispeed_load = 99,
        .little_hispeed_freq = 600000,
        .little_io_is_busy = 1,
        .little_timer_rate = 50000,
        .little_above_hispeed_delay = "19000",
        .little_min_sample_time = 50000,
        .little_max_freq_hysteresis = 0,
        .little_target_loads = "71 384000:75 460000:69 600000:80 672000:76 787000:81 864000:81 960000:69 1248000:78",
        .little_scaling_min_freq = 302400,
        .little_scaling_max_freq = 1440000,
        /* Big cluster */
        .big_min_cpus = 0,
        .big_max_cpus = 0,
    },
    [PROFILE_BALANCED] = {
        /* Little cluster */
        .little_boost = 0,
        .little_boostpulse_duration = 40,
        .little_go_hispeed_load = 99,
        .little_hispeed_freq = 600000,
        .little_io_is_busy = 1,
        .little_timer_rate = 50000,
        .little_above_hispeed_delay = "19000",
        .little_min_sample_time = 20000,
        .little_max_freq_hysteresis = 0,
        .little_target_loads = "71 384000:75 460000:69 600000:80 672000:76 787000:81 864000:81 960000:69 1248000:78",
        .little_scaling_min_freq = 302400,
        .little_scaling_max_freq = 1440000,
        /* Big cluster */
        .big_boost = 0,
        .big_boostpulse_duration = 0,
        .big_go_hispeed_load = 80,
        .big_hispeed_freq = 633600,
        .big_io_is_busy = 1,
        .big_timer_rate = 50000,
        .big_above_hispeed_delay = "50000",
        .big_min_sample_time = 50000,
        .big_max_freq_hysteresis = 0,
        .big_target_loads = "71 384000:72 480000:68 633000:74 768000:80 864000:81 960000:69 1248000:84 1344000:84 1440000:84 1536000:85 1632000:85 1728000:85 1824000:84",
        .big_scaling_min_freq = 302400,
        .big_scaling_max_freq = 1824000,
        .big_min_cpus = 0,
        .big_max_cpus = 2,
    },
    [PROFILE_BIAS_PERFORMANCE] = {
        /* Little cluster */
        .little_boost = 1,
        .little_boostpulse_duration = 40,
        .little_go_hispeed_load = 90,
        .little_hispeed_freq = 1248000,
        .little_io_is_busy = 1,
        .little_timer_rate = 20000,
        .little_above_hispeed_delay = "19000",
        .little_min_sample_time = 20000,
        .little_max_freq_hysteresis = 80000,
        .little_target_loads = "71 384000:75 460000:69 600000:80 672000:76 787000:81 864000:81 960000:69 1248000:78",
        .little_scaling_min_freq = 302400,
        .little_scaling_max_freq = 1440000,
        /* Big cluster */
        .big_boost = 1,
        .big_boostpulse_duration = 40,
        .big_go_hispeed_load = 80,
        .big_hispeed_freq = 1248000,
        .big_io_is_busy = 1,
        .big_timer_rate = 20000,
        .big_above_hispeed_delay = "19000",
        .big_min_sample_time = 40000,
        .big_max_freq_hysteresis = 80000,
        .big_target_loads = "71 384000:72 480000:68 633000:74 768000:80 864000:81 960000:69 1248000:84 1344000:84 1440000:84 1536000:85 1632000:85 1728000:85 1824000:84",
        .big_scaling_min_freq = 302400,
        .big_scaling_max_freq = 1824000,
        .big_min_cpus = 2,
        .big_max_cpus = 2,
    },
    [PROFILE_HIGH_PERFORMANCE] = {
        /* Little cluster */
        .little_boost = 1,
        .little_boostpulse_duration = 40,
        .little_go_hispeed_load = 99,
        .little_hispeed_freq = 600000,
        .little_io_is_busy = 1,
        .little_timer_rate = 50000,
        .little_above_hispeed_delay = "19000",
        .little_min_sample_time = 20000,
        .little_max_freq_hysteresis = 0,
        .little_target_loads = "71 384000:75 460000:69 600000:80 672000:76 787000:81 864000:81 960000:69 1248000:78",
        .little_scaling_min_freq = 302400,
        .little_scaling_max_freq = 1440000,
        /* Big cluster */
        .big_boost = 1,
        .big_boostpulse_duration = 100,
        .big_go_hispeed_load = 80,
        .big_hispeed_freq = 1248000,
        .big_io_is_busy = 1,
        .big_timer_rate = 20000,
        .big_above_hispeed_delay = "19000",
        .big_min_sample_time = 40000,
        .big_max_freq_hysteresis = 80000,
        .big_target_loads = "71 384000:72 480000:68 633000:74 768000:80 864000:81 960000:69 1248000:84 1344000:84 1440000:84 1536000:85 1632000:85 1728000:85 1824000:84",
        .big_scaling_min_freq = 302400,
        .big_scaling_max_freq = 1824000,
        .big_min_cpus = 2,
        .big_max_cpus = 2,
    },
};
