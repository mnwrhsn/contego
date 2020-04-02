/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

/* 
 * File:   bbb_main.c
 * Author: mhasan11
 *
 * Created on June 8, 2016, 8:50 AM
 */



#include <stdio.h>
#include <signal.h>
#include <unistd.h>
#include <sys/mman.h>

#include <native/task.h>
#include <native/timer.h>
#include <native/alarm.h>
#include  <rtdk.h>
#include <sys/io.h>

#include <stdlib.h> /* for exit() definition */

// My include files
#include "functions.h"
//#include "globals.h"

int main(int argc, char* argv[]) {
    
    //printf("\nType CTRL-C to end this program\n\n");
  
    if (argc < 4) {
        printf("Input argument should be: mode, dos_attack_time, dos_and_fs_interval \n");
        exit(1);
    }

    // xenomai initialization
    initialize_rt_env();

    // set attack time
    setAttackTime(argv[2], argv[3]);


    //startup code
    startup_code(argv[1]);
   
    
    
    // monitor for mode change request
    //passive_2_active_event();
    //active_2_passive_event();

    // wait for CTRL-c to exit the program
    safe_exit();


    //cleanup code
    cleanup();

    // should print this for clean exit!
    printf("\n\nTerminating program...\n\n");
    
    exit(EXIT_SUCCESS);
}