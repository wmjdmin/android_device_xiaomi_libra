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
    PROFILE_BALANCED,
    PROFILE_HIGH_PERFORMANCE,
    PROFILE_BIAS_POWER_SAVE,
    PROFILE_BIAS_PERFORMANCE,
    PROFILE_MAX
};

typedef struct governor_settings {
    int is_interactive;
    /* Little cluster */
    char *little_scaling_governor;
    int little_use_sched_load;
    int little_use_migration_notif;
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
    char *big_scaling_governor;
    int big_use_sched_load;
    int big_use_migration_notif;
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
    /* GPU */
    char *gpu_governor;
    int gpu_max_freq;
    int gpu_min_freq;
    int gpu_min_pwrlevel;
    int gpu_max_pwrlevel;
    int gpu_default_pwrlevel;
    /* Input bost */
    char *input_boost_freq;
    int input_boost_ms;
} power_profile;

static power_profile profiles[PROFILE_MAX] = {
    [PROFILE_POWER_SAVE] = {
        /* Little cluster */
        .little_scaling_governor = "interactive",
        .little_use_sched_load = 1,
        .little_use_migration_notif = 1,
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
        /* Input boost */
        .input_boost_freq = "0",
        .input_boost_ms = 0,
        /* GPU */
        .gpu_governor = "powersave",
        .gpu_max_freq = 180000000,
        .gpu_min_freq = 180000000,
        .gpu_min_pwrlevel = 5,
        .gpu_max_pwrlevel = 5,
        .gpu_default_pwrlevel = 5,
    },
    [PROFILE_BALANCED] = {
        /* Little cluster */
        .little_scaling_governor = "interactive",
        .little_use_sched_load = 1,
        .little_use_migration_notif = 1,
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
        .big_scaling_governor = "interactive",
        .big_use_sched_load = 1,
        .big_use_migration_notif = 1,
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
        /* Input boost */
        .input_boost_freq = "0:600000 1:600000 2:600000 3:600000 4:0 5:0",
        .input_boost_ms = 40,
        /* GPU */
        .gpu_governor = "msm-adreno-tz",
        .gpu_max_freq = 367000000,
        .gpu_min_freq = 180000000,
        .gpu_min_pwrlevel = 5,
        .gpu_max_pwrlevel = 3,
        .gpu_default_pwrlevel = 5,
    },
    [PROFILE_HIGH_PERFORMANCE] = {
        /* Little cluster */
        .little_scaling_governor = "performance",
        .little_scaling_min_freq = 302400,
        .little_scaling_max_freq = 1440000,
        /* Big cluster */
        .big_scaling_governor = "interactive",
        .big_use_sched_load = 1,
        .big_use_migration_notif = 1,
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
        /* Input boost */
        .input_boost_freq = "0:1440000 1:1440000 2:1440000 3:1440000 4:1824000 5:1824000",
        .input_boost_ms = 100,
        /* GPU */
        .gpu_governor = "msm-adreno-tz",
        .gpu_max_freq = 600000000,
        .gpu_min_freq = 600000000,
        .gpu_min_pwrlevel = 5,
        .gpu_max_pwrlevel = 0,
        .gpu_default_pwrlevel = 5,
    },
    [PROFILE_BIAS_POWER_SAVE] = {
        /* Little cluster */
        .little_scaling_governor = "interactive",
        .little_use_sched_load = 1,
        .little_use_migration_notif = 1,
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
        /* Input boost */
        .input_boost_freq = "0",
        .input_boost_ms = 0,
        /* GPU */
        .gpu_governor = "powersave",
        .gpu_max_freq = 180000000,
        .gpu_min_freq = 180000000,
        .gpu_min_pwrlevel = 5,
        .gpu_max_pwrlevel = 5,
        .gpu_default_pwrlevel = 5,
    },
    [PROFILE_BIAS_PERFORMANCE] = {
        /* Little cluster */
        .little_scaling_governor = "interactive",
        .little_use_sched_load = 1,
        .little_use_migration_notif = 1,
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
        .big_scaling_governor = "interactive",
        .big_use_sched_load = 1,
        .big_use_migration_notif = 1,
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
        /* Input boost */
        .input_boost_freq = "0:1248000 1:1248000 2:1248000 3:1248000 4:1248000 5:1248000",
        .input_boost_ms = 40,
        /* GPU */
        .gpu_governor = "msm-adreno-tz",
        .gpu_max_freq = 600000000,
        .gpu_min_freq = 180000000,
        .gpu_min_pwrlevel = 5,
        .gpu_max_pwrlevel = 0,
        .gpu_default_pwrlevel = 5,
    },
};
