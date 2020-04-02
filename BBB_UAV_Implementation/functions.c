/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdlib.h>

#include <native/task.h>
#include <native/timer.h>
#include <native/alarm.h>
#include <native/event.h>
#include <native/sem.h>
#include  <rtdk.h>
#include <sys/io.h>

#include <stdint.h> /* for uint64 definition */
#include <stdlib.h> /* for exit() definition */
#include <time.h> /* for clock_gettime */

// My include files
#include "functions.h"
#include "globals.h"


// ARM Cycle Counter functions

static inline uint32_t get_cyclecount(void)
{
    //unsigned int value;
    uint32_t value;
    // Read CCNT Register
    asm volatile ("MRC p15, 0, %0, c9, c13, 0\t\n" : "=r"(value));
    return value;
}

static inline void init_perfcounters(int32_t do_reset, int32_t enable_divider)
{
    // in general enable all counters (including cycle counter)
    int32_t value = 1;

    // peform reset:  
    if (do_reset) {
        value |= 2; // reset all counters to zero.
        value |= 4; // reset cycle counter to zero.
    }

    if (enable_divider)
        value |= 8; // enable "by 64" divider for CCNT.

    value |= 16;

    // program the performance-counter control-register:
    asm volatile ("MCR p15, 0, %0, c9, c12, 0\t\n" ::"r"(value));

    // enable all counters:  
    asm volatile ("MCR p15, 0, %0, c9, c12, 1\t\n" ::"r"(0x8000000f));

    // clear overflows:
    asm volatile ("MCR p15, 0, %0, c9, c12, 3\t\n" ::"r"(0x8000000f));
}

// a random number generator in a range
// source: http://stackoverflow.com/questions/2509679/how-to-generate-a-random-number-from-within-a-range
unsigned int rand_interval(unsigned int min, unsigned int max)
{
    int r;
    const unsigned int range = 1 + max - min;
    const unsigned int buckets = RAND_MAX / range;
    const unsigned int limit = buckets * range;

    /* Create equal size buckets all in a row, then fire randomly towards
     * the buckets until you land in one of them. All buckets are equally
     * likely. If you land off the end of the line of buckets, try again. */
    do
    {
        srand(time(NULL));
        r = rand();
    } while (r >= limit);

    return min + (r / buckets);
}

void initialize_rt_env() {
    /* Avoids memory swapping for this program */
    mlockall(MCL_CURRENT | MCL_FUTURE);

    /* Perform auto-init of rt_print buffers if the task doesn't do so */
    rt_print_auto_init(1);
}

// define an empty signal handler

void catch_signal(int sig) {
}

/* wait for CTRL+C to exit the program */
void safe_exit() {
    signal(SIGTERM, catch_signal);
    signal(SIGINT, catch_signal);
    // wait for SIGINT (CTRL-C) or SIGTERM signal
    pause();
}

//startup code

void startup_code(char* arg) 
{
    
    if (atoi(arg) == 0) {
        exp_type = WITHOUT_MODE_CHANGE;
    }
    else if (atoi(arg) == 1) {
        exp_type = WITH_MODE_CHANGE;
    }
    else {
        rt_printf("\nArgument should only be 0 or 1!\n\n");
        exit(1);
    }
    
    if (exp_type == WITH_MODE_CHANGE) {
        rt_printf("Mode Change Allowed!\n");
        startup_with_mode_change();
    } else if (exp_type == WITHOUT_MODE_CHANGE) {
        rt_printf("Security Tasks will be running only in PASSIVE Mode!\n");
        startup_without_mode_change();
    }

    
    // save start time
    clock_gettime(CLOCK_MONOTONIC, &base_start_time);	/* mark start time */
}


void startup_with_mode_change() {
    
    // set timing to ns
    rt_timer_set_mode(BASEPERIOD);
    
    startup_mode_change_manager();
    // semaphore to sync task startup on
    rt_sem_create(&sync_start, "BBBSemaphore", 0, S_FIFO);        
    startup_rt();
    startup_se_passive();
    // broadcast semaphore
    rt_sem_broadcast(&sync_start);
    
}

void startup_without_mode_change() {
    
    // set timing to ns
    rt_timer_set_mode(BASEPERIOD);
    
    //startup_mode_change_manager();
    // semaphore to sync task startup on
    rt_sem_create(&sync_start, "BBBSemaphore", 0, S_FIFO);        
    startup_rt();
    startup_se_passive();
    // broadcast semaphore
    rt_sem_broadcast(&sync_start);
    
}

void startup_mode_change_manager() {
    
    char task_name[30];

    int err;
    int i = 100; // manager ID
    sprintf(task_name, "rt_task:mode_change_manager");
        err = rt_task_create(&rt_task_mode_change_manager, task_name, 0, 99, 0);
        if (err) {
            rt_printf("Error creating RT Task %d!\n", i);
        } else {
            rt_task_start(&rt_task_mode_change_manager, &rt_task_function_manager, &i);
        }
    
}

void startup_rt() {
    
    int i = 0;
    char task_name[15];

    int err;

    for (i = 0; i < N_RT_TASK; i++) {
        sprintf(task_name, "rt_task%d", i);
        err = rt_task_create(&rt_task_array[i], task_name, 0, rt_prio_array_passive[i], 0);
        if (err) {
            rt_printf("Error creating RT Task %d!\n", i);
        } else {
            se_task_mode_info = PASSIVE;
            rt_task_start(&rt_task_array[i], &rt_task_function, &i);
        }

    }
    
    
}


void startup_se_passive() {

    int i;
    char task_name[15];
    
    int err;
    
//    int task_id[N_SE_TASK_ACTIVE];
//    
//    // initialize task id
//    for (i = 0; i < N_SE_TASK_ACTIVE; i++) {
//        task_id[i] = i;
//        //rt_printf("task id arr: %d", task_id[i]);
//    }

    for (i = 0; i < N_SE_TASK_PASSIVE; i++) {
        sprintf(task_name, "se_task%d", i);
        err = rt_task_create(&se_task_array_passive[i], task_name, 0, se_prio_array_passive[i], 0);
        if (err) {
            rt_printf("Error creating Passive Security Task %d!\n", i);
        } else {
            se_task_mode_info = PASSIVE;
            // pass task id to the task function
            int *arg = malloc(sizeof(*arg));
            *arg = i;
            
            //rt_task_start(&se_task_array_passive[i], &se_task_function_passive, &i);
            rt_task_start(&se_task_array_passive[i], &se_task_function_passive, arg);
        }

    }
    
    
}


void startup_se_active() {
    
    //int i = 0;
    int i;
    char task_name[15];

    int err;
    int j;
//    int task_id[N_SE_TASK_ACTIVE];
    
//    for (i = 0; i < N_SE_TASK_ACTIVE; i++) {
//        task_id[i] = i;
//        //rt_printf("task id arr: %d\n", task_id[i]);
//    }
    
    

    //rt_printf("Will start a bunch of new task!\n");
    for (i = 0; i < N_SE_TASK_ACTIVE; i++) {
        sprintf(task_name, "se_task%d", i);
        err = rt_task_create(&se_task_array_active[i], task_name, 0, se_prio_array_active[i], 0);
        if (err) {
            rt_printf("Error creating Active Security Task %d!\n", i);
        } else {
            se_task_mode_info = ACTIVE;
            
            // pass task id to the task function
            int *arg = malloc(sizeof(*arg));
            *arg = i;
            //rt_task_start(&se_task_array_active[i], &se_task_function_active, &i);
            rt_task_start(&se_task_array_active[i], &se_task_function_active, arg);
        }

    }
    
  
}



//cleanup code

void cleanup() {
    int i;
    
    for (i = 0; i < N_RT_TASK; i++) {
        rt_task_delete(&rt_task_array[i]);
    }
    
    if (se_task_mode_info == PASSIVE) {
        for (i = 0; i < N_SE_TASK_PASSIVE; i++) {
            rt_task_delete(&se_task_array_passive[i]);
        }
    }

    if (se_task_mode_info == ACTIVE) {
        for (i = 0; i < N_SE_TASK_ACTIVE; i++) {
            rt_task_delete(&se_task_array_active[i]);
        }
    }

   rt_task_delete(&rt_task_mode_change_manager);
    
}


// helper functions for launching attacks
void setAttackTime(char* arg1, char* arg2)
{
    //int randval;
    int attack_time, interval;
    attack_time = atoi(arg1); // in second
    interval = atoi(arg2); // in second
    
    //randval = rand_interval(1, 5 * attack_time); // get a random duration
    
    //randval = 1;
    
    dos_attack_launch_time = (long long unsigned int) attack_time; // in seconds
    fs_attack_launch_time = (long long unsigned int) (attack_time + interval); // in seconds
    
    //printf("randval: %d \n", randval);
    //printf("interval: %d \n", interval);
    //printf("DoS attack launch time: %llu \n", dos_attack_launch_time);
    //printf("FS Attack Launch time: %llu \n", fs_attack_launch_time);
}


int lunch_dos_attack()
{
    int errorflag = 0;
    if (system("cp bf_trace/bruteforce.pcap .; mv bruteforce.pcap mypackets.trace") == -1) {
        errorflag = -1;
    }

    return errorflag;
    
}

// handler for real-time tasks

void rt_task_function(void *arg) {
    int j = 0, maxcnt = 30;
    int task_id = *(int *) arg;
    //int isDeleted = 0;
     uint64_t diff;

    //rt_printf("I am RT task %d \n", task_id);


    // make this task periodic
    rt_task_set_periodic(NULL, TM_NOW, rt_period_array[task_id]);
    
    // sync using semaphore
    rt_sem_p(&sync_start, TM_INFINITE);
    
    // AHRS task
    if (task_id == 0) {
        init_ahrs_task();
    }
    
    // flight_control task
    else if (task_id == 1) {
        init_flight_control_task();
    }
    
    while (1) {
        //while (++j < maxcnt) {

        // measure should we lunch attack
        clock_gettime(CLOCK_MONOTONIC, &current_time);
        diff = current_time.tv_sec - base_start_time.tv_sec; //in second

        // call Real-Time (FlightControl) tasks

        if (task_id == 0) {

            //rt_printf("RT Task %d AHRS running...\n",task_id); 
            my_ahrs_task();
            //rt_printf("RT Task %d AHRS finished...\n",task_id);

        } else if (task_id == 1) {

            //rt_printf("RT Task %d FlightControl running...\n",task_id);            
            my_flight_control_task();
            //rt_printf("RT Task %d FlightControl finished...\n",task_id);

        } else if (task_id == 2) {

            // we will lunch attack only replacing lowest priority one

            if ((long long unsigned int) diff > dos_attack_launch_time && dos_attackLunched == 0) {
                // lunch dos attack

                if (lunch_dos_attack() == -1) {
                    rt_printf("Error Launching DoS Attack!\n");
                } else {

                    dos_attackLunched = 1; // we have lunched DoS attack, no more attack please!
                    init_perfcounters(1, 0);
                    dos_start_cc = get_cyclecount();

                    rt_printf("DoS Attack launched at: %u Cycles\n", dos_start_cc);
                }

            }
            
            if ((long long unsigned int) diff > fs_attack_launch_time && dos_attackLunched == 1 && fs_attackLunched == 0) {

                // lunch FS attack
                
                
                //if (system("sudo touch /bin/twattack.txt") == -1) {
                // use shellcode!
                if (system("sudo ./create_file > /bin/twattack.txt") == -1) {
                    rt_printf("Error Launching FS Attack!\n");
                } else {

                    fs_attackLunched = 1; // we have lunched FS attack, no more attack please!
                    
                    fs_start_cc = get_cyclecount();

                    //rt_printf("FS Attack launched at: %u Cycles\n", fs_start_cc);
                }

            }
            //else 
            {
                // run un-compromised code
                //rt_printf("RT Task %d Telemetry running...\n", task_id);
                my_telemetry_task();
                //rt_printf("RT Task %d Telemetry finished...\n", task_id);
            }

        }// Simple error checking
        else {
            rt_printf("Unknown error in RT Task parameter setup!\n");
        }

        // wait for next period
        rt_task_wait_period(NULL);
    }
    /* we'll never get here */
    return;
}


// handler for security tasks

void se_task_function_passive(void *arg) {
    //int j = 0, maxcnt = 30;
    int task_id = *(int *) arg;
    free(arg); // deallocate
    
    
    
    int isDeleted = 0;
    int checkError; // a flag to check attack

    FILE* fileHandler;
    if (exp_type == WITH_MODE_CHANGE) {
        fileHandler = fopen(filename[1], "a");
        if (fileHandler == NULL) {
            printf("Error opening file %s!\n", filename[0]);
            exit(1);
        }
    } else if (exp_type == WITHOUT_MODE_CHANGE) {
        fileHandler = fopen(filename[0], "a");
        if (fileHandler == NULL) {
            printf("Error opening file %s!\n", filename[1]);
            exit(1);
        }
    }

    //rt_printf("I am Security task %d (passive) \n", task_id);


    // make this task periodic
    rt_task_set_periodic(NULL, TM_NOW, se_period_array_passive[task_id]);
    
    // sync using semaphore
    rt_sem_p(&sync_start, TM_INFINITE);
    
    while (1) {
    //while (++j < maxcnt) {
        
        //++j;
        //rt_printf("  print from task %d\n", task_id);
        
        // call tripwire/bro here

        if (system(security_command_passive[task_id]) == -1) {
            printf("Error starting Passive Mode Security Task!\n");
        }
        
        //rt_printf("  PASSIVE security task %d completed!\n", task_id);
        
        //TODO this part needs modification
//        if (task_id == 0 && j > 2 && !isDeleted && exp_type == WITH_MODE_CHANGE) {
//            
//            rt_printf("I am passive se task %d -> I will issue request!\n", task_id);
//           
//            isDeleted = 1;
//            
//            se_task_mode_info = PASSIVE_2_ACTIVE; 
//           
//            //rt_printf("start new set of tasks\n");
//        }
        
        
        /* check for DoS attack */
        if (task_id == BRO_INDEX_PASSIVE && dos_attackLunched == 1 && dos_time_saved ==0) {

           
            

            if (access("notice.log", F_OK) != -1) {
                // log file exists
                //rt_printf("Log file exisits!\n");
                
                checkError = system("grep -q \"FTP::Bruteforcing\" notice.log");
                //printf("Checkerror %d!\n", checkError);
                if (checkError == 0) {

                    dos_time_saved = 1;
                    end_cc = get_cyclecount();
                    //rt_printf("End CC= %u\n", end_cc);
                    //diff_cc = end_cc - start_cc;
                    dos_detect_cc = end_cc - dos_start_cc;
                    //rt_printf("We have got some violations! Time to DoS detect: %u Cycles\n", dos_detect_cc);
                    
                    // fix attack
                    /*
                    if (system("cp bf_trace/mypackets.trace .") == -1) {
                        rt_printf("Error Fixing DoS!\n");
                    }
                    */

                    if (!isDeleted && exp_type == WITH_MODE_CHANGE) {

                        //rt_printf("PASSIVE-2-ACTIVE mode change request issued!\n");

                        isDeleted = 1;
                        se_task_mode_info = PASSIVE_2_ACTIVE;

                        //rt_printf("start new set of tasks\n");
                    }
                    
                    
                    
                }
                
            } 
            
            
        }
        
        /* check for attack on FS */
        if (task_id == FSBIN_INDEX_PASSIVE && dos_attackLunched == 1 && fs_attackLunched==1 && dos_time_saved ==1 && exp_type==WITHOUT_MODE_CHANGE) {
            
            checkError = system("grep -q \"Total violations found:  0\" twout.txt");
            //printf("Checkerror %d!\n", checkError);
            if (checkError != 0) {

                end_cc = get_cyclecount();
                //rt_printf("End CC= %u\n", end_cc);
                //fs_detect_cc = end_cc - dos_detect_cc;
                fs_detect_cc = end_cc - dos_start_cc;
                
                // write to the file (in ns)
                
                fprintf(fileHandler, "%Lf\n", (long double) (fs_detect_cc / BBB_CLOCK_FREQ) * BILLION);
                fclose(fileHandler); //close the file
                
                rt_printf("We have got FS violations in PASSIVE! Time to detect: %u Cycles\n", fs_detect_cc);

                // end of experiment
                
                exit(EXIT_SUCCESS);

            }
        }

        
        // wait for next period
        rt_task_wait_period(NULL);
    }
    /* we'll never get here */
    return;
}


void se_task_function_active(void *arg) {
    //int j = 0, maxcnt = 30;
    int task_id = *(int *) arg;
    free(arg); // deallocate
    
    
    //int isDeleted = 0;
    int checkError; // a flag to check attack
    
    FILE* fileHandler;
    if (exp_type == WITH_MODE_CHANGE) {
        fileHandler = fopen(filename[1], "a");
        if (fileHandler == NULL) {
            printf("Error opening file %s!\n", filename[0]);
            exit(1);
        }
    } else if (exp_type == WITHOUT_MODE_CHANGE) {
        fileHandler = fopen(filename[0], "a");
        if (fileHandler == NULL) {
            printf("Error opening file %s!\n", filename[1]);
            exit(1);
        }
    }
    
   //rt_printf("I am Security task %d (active) \n", task_id);

    //rt_printf("I am ACTIVE Security task %d \n", task_id);


    // make this task periodic
    rt_task_set_periodic(NULL, TM_NOW, se_period_array_active[task_id]);
    
    // sync using semaphore
    rt_sem_p(&sync_start, TM_INFINITE);
    
    while (1) {
    //while (++j < maxcnt) {
        //++j;
        
        //rt_printf("  print from ACTIVE task %d\n", task_id);
        
        // call tripwire/bro here

        if (system(security_command_active[task_id]) == -1) {
            printf("Error starting Active Mode Security Task!\n");
        }

        //rt_printf("  ACTIVE security task %d completed!\n", task_id);
        
        
        //TO DO need to fix
        /*
        if (task_id == 0 && j > 2 && !isDeleted && exp_type == WITH_MODE_CHANGE) {
            
            rt_printf("I am active se task %d -> I will issue request!\n", task_id);
           
            isDeleted = 1;
            
            se_task_mode_info = ACTIVE_2_PASSIVE; 
           
            //rt_printf("start new set of tasks\n");
        }
         */
        
        
        /* check for attack on FS */
        if (task_id == FSBIN_INDEX_ACTIVE && dos_attackLunched == 1 && fs_attackLunched==1 && dos_time_saved ==1 && exp_type==WITH_MODE_CHANGE) {
            
            
            checkError = system("grep -q \"Total violations found:  0\" twout.txt");
            //printf("Checkerror %d!\n", checkError);
            if (checkError != 0) {

                end_cc = get_cyclecount();
                //rt_printf("End CC= %u\n", end_cc);
                //fs_detect_cc = end_cc - dos_detect_cc;
                fs_detect_cc = end_cc - dos_start_cc;
                

                // write to the file (in ns)
                fprintf(fileHandler, "%Lf\n", (long double) (fs_detect_cc / BBB_CLOCK_FREQ) * BILLION);
                fclose(fileHandler); //close the file
                
                rt_printf("We have got FS violations in ACTIVE! Time to detect: %u Cycles\n", fs_detect_cc);

                // end of experiment
                
                exit(EXIT_SUCCESS);

            }
        }

        
        
        // wait for next period
        rt_task_wait_period(NULL);
    }
    /* we'll never get here */
    return;
}


void change_rt_prio_active_to_passive()
{
    int i;
    
    for (i = 0; i < N_RT_TASK; i++) {
        rt_task_set_priority(&rt_task_array[i], rt_prio_array_passive[i]);
    }
    
}

void change_rt_prio_passive_to_active()
{
    int i;
    
    for (i = 0; i < N_RT_TASK; i++) {
        rt_task_set_priority(&rt_task_array[i], rt_prio_array_active[i]);
    }
}

void delete_active_se_task()
{
    int i;
    for (i = 0; i < N_SE_TASK_ACTIVE; i++) {
        rt_task_delete(&se_task_array_active[i]);
    }
    
}

void delete_passive_se_task()
{
    int i;
    for (i = 0; i < N_SE_TASK_PASSIVE; i++) {
        rt_task_delete(&se_task_array_passive[i]);
    }
}

// handler for mode change manager

void rt_task_function_manager(void *arg) {
    //int j = 0, maxcnt = 30;
    //int task_id = *(int *) arg;
    //int isDeleted = 0;

    //rt_printf("I am Mode change Manager, ID %d \n", task_id);


    // make this task periodic
    rt_task_set_periodic(NULL, TM_NOW, manager_period_ns);
    while (1) {
    //while (++j < maxcnt) {
        
        
        //rt_printf("  print from MANAGER task %d\n", task_id);
        /*
        if (se_task_mode_info == PASSIVE) {
            rt_printf("  passive mode \n");
        }
        else if (se_task_mode_info == ACTIVE) {
            rt_printf("  active mode \n");
        }
        */
        
        if (se_task_mode_info == PASSIVE_2_ACTIVE) {
            //rt_printf("Mode switch request (passive 2 active) \n");

            delete_passive_se_task();
            //rt_printf("Deleted passive mode Security tasks!\n");
            
            change_rt_prio_passive_to_active();
            //rt_printf("Changed RT priority PASSIVE to ACTIVE!\n");
            
            // delete semaphore for safety
            //rt_sem_delete(&sync_start);	
            // semaphore to sync task startup on
            rt_sem_create(&sync_start, "BBBSemaphore", 0, S_FIFO);
            startup_se_active();
            rt_sem_broadcast(&sync_start);
            
            

            

        }
        
        // Not Implemented!
        if (se_task_mode_info == ACTIVE_2_PASSIVE) {
            rt_printf("Mode switch request (active 2 passive) \n");

            delete_active_se_task(); 
            rt_printf("Deleted active mode Security tasks!\n");
            change_rt_prio_active_to_passive();
            rt_printf("Changed RT priority ACTIVE to PASSIVE!\n");
            // delete semaphore for safety
            //rt_sem_delete(&sync_start);	
            // semaphore to sync task startup on
            rt_sem_create(&sync_start, "BBBSemaphore", 0, S_FIFO);
            startup_se_passive();
            rt_sem_broadcast(&sync_start);
            

           

        }
         

        
        // wait for next period
        rt_task_wait_period(NULL);
    }
    /* we'll never get here */
    return;
}

