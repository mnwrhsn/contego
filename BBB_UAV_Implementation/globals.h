/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/* 
 * File:   globals.h
 * Author: mhasan11
 *
 * Created on June 8, 2016, 9:33 AM
 */


#ifndef GLOBALS_H_INCLUDED
#define GLOBALS_H_INCLUDED

/* Define global variables here. */




#define NTASK 3

#define N_RT_TASK 3
//#define N_SE_TASK 5

#define N_SE_TASK_ACTIVE 4
#define N_SE_TASK_PASSIVE 2

#define BILLION 1E9
#define BBB_CLOCK_FREQ 1E9 // clock frequency of BBB (1GHz)

#define BASEPERIOD 0   // baseperiod 0 to get ns (used in xenomai example)


// use defined index for better attack experiments

#define BRO_INDEX_PASSIVE 1
#define BRO_INDEX_ACTIVE 3
#define FSBIN_INDEX_PASSIVE 0
#define FSBIN_INDEX_ACTIVE 2


RT_SEM sync_start; // a semaphore to sync the start of the tasks

RT_TASK rt_task_array[N_RT_TASK];


RT_TASK se_task_array_active[N_SE_TASK_ACTIVE];
RT_TASK se_task_array_passive[N_SE_TASK_PASSIVE];


//RT_TASK se_task_array_passive[NTASK];
//RT_TASK se_task_array_active[NTASK];
RT_TASK rt_task_mode_change_manager;


// RT task Priority 
// AHRS -> FlightControl -> Telemetry
// where AHRS is the highest priority (shortest period)

int rt_prio_array_passive[N_RT_TASK] = {98, 97, 96};
// Server priority level:2 for active. So 2 real-time tasks will be lower priority than the server.
//int rt_prio_array_active[N_RT_TASK] = {98, 93, 92};
int rt_prio_array_active[N_RT_TASK] = {93, 88, 87};

// Security priority order (Passive):
// FS_BIN > NW_PCKT

// Security priority order (Active):
// FS_LIB > IDS_BIN > FS_BIN > NW_PCKT

int se_prio_array_passive[N_SE_TASK_PASSIVE] = {95, 94};
//int se_prio_array_active[N_SE_TASK_ACTIVE] = {97, 96, 95, 94};
int se_prio_array_active[N_SE_TASK_ACTIVE] = {92, 91, 90, 89};
//int se_prio_array_active[N_SE_TASK_ACTIVE] = {93, 92, 91, 90}; // this one is incorrect




/* Periods are in nanoseconds */
RTIME rt_period_array[N_RT_TASK] = {1e9, 5e9, 10e9};

RTIME se_period_array_passive[N_SE_TASK_PASSIVE] ={88225785955, 88225785958};
RTIME se_period_array_active[N_SE_TASK_ACTIVE] ={26701619869, 39753595713, 40314712724, 42203610797};

RTIME manager_period_ns = 26701619860; // TO DO: need to check



enum ModeInfo {
    PASSIVE,
    PASSIVE_2_ACTIVE,
    ACTIVE_2_PASSIVE,
    ACTIVE
} se_task_mode_info;

// Security task commands

const char *security_command_active[] ={
    "sudo tripwire --check -s --rule-name \"Root file-system libraries\" > twout.txt",
    "sudo tripwire --check -s --rule-name \"Tripwire Binaries\" > twout.txt",
    "sudo tripwire --check -s --rule-name \"Root file-system executables\" > twout.txt",
    "bro -r mypackets.trace detect-bruteforcing.bro > twout.txt"
};

const char *security_command_passive[] ={
    "sudo tripwire --check -s --rule-name \"Root file-system executables\" > twout.txt",
    "bro -r mypackets.trace detect-bruteforcing.bro > twout.txt"
};

// What type of experiment we are running

enum EXPTYPE {
    WITHOUT_MODE_CHANGE,
    WITH_MODE_CHANGE
} exp_type;

// a flag to see whether attack is launched or not

int dos_attackLunched = 0; 
int fs_attackLunched = 0;

//int attack_time; // a random time given as input to launch attack
uint64_t dos_attack_launch_time, fs_attack_launch_time;
int dos_time_saved = 0; // a flag to determine whether we save DoS attack time

// a constant to denote when 2nd attack will be launched
uint64_t fs_attack_launch_interval;


struct timespec base_start_time, current_time;

uint32_t dos_start_cc, end_cc,
            dos_detect_cc, fs_start_cc, fs_detect_cc; // used for cycle count

 // filename for writing detecting time
static const char *filename[] = {"no_mode_change.txt", "mode_change.txt" };


#endif /* GLOBALS_H */

