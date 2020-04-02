clc;
clear;
close all;


% add GGPLAB to MATLAB path
folderName = fullfile(matlabroot,'toolbox','ggplab');
addpath(genpath(folderName));

% add helper fuctions directory
addpath(genpath('HelperFunctions/'));

%rng(0,'twister'); % seed the random numbers

global QUIET; % turn off reporting from GP
QUIET = 1;

rt_periodmin = 50;
rt_periodmax = 1000;

se_periodmin = 1000;
se_periodmax = 3000;

se_period_des_factor = 10; % a big number

se_util_portion = 0.3; % utilization of the Security tasks are 30% of the Real-time tasks

rt_ntask_min = 3;
rt_ntask_max = 10;

se_ntask_min = 2;
se_ntask_max = 5;

rt_deadline_factor = 0.8; % a multipliler to obtain RT tasks deadline

n_tc_eachGrp = 100; % number of task set in each utlization group

base_util_ngroup = 10;

% determine how many tasks can be ...
% lower priority than the security server
low_prio_tol = 0.4; % ceil(N_RT_TASK * low_prio_tol)
rt_deadline_tol = 0.2; % 20% deadline tolerance


% get the RT and SE taskset
% each row of the struct represents the base utilization group

[ rt_taskset, se_taskset ] = get_RT_SE_TaskSets( base_util_ngroup, n_tc_eachGrp,...
    rt_ntask_min, rt_ntask_max, rt_periodmin, rt_periodmax, rt_deadline_factor,...
    se_ntask_min, se_ntask_max, se_periodmin, se_periodmax, ...
    se_period_des_factor, se_util_portion);

% get a random taskset and run test


i = 8;
j = 30;

rt_tc = rt_taskset(i,j);
se_tc = se_taskset(i,j+16);

% rt_tc = rt_taskset(3,30);
% se_tc = se_taskset(3,5);

% rt_tc
% se_tc



% for i=1:base_util_ngroup
%     for j=1:n_tc_eachGrp
%         
%         rt_tc = rt_taskset(i,j);
%         se_tc = se_taskset(i,j);
        

        isSched = get_RT_schedulability( rt_tc );
        
        if isSched == 0
            fprintf('Util group %d, RT taskset %d is NOT SCHEDULABLE!\n', i, j);
            %continue;
        end
        
        
        % get the server parameters and optimal Secuirty periods
        % (PASSIVE/OPPORTUNISTIC Mode)
%         [server_util_passive, Q_passive, P_passive,...
%             server_status_passive, count_passive, obj_value_passive,...
%             Tstar_passive, period_status_passive ] = GetPeriod_N_ServerParam_passive( rt_tc, se_tc );
%         


% get the server parameters and optimal Secuirty periods
        % (ACTIVE Mode tolerance: 0)
        
        rt_deadline_tol = 0.00; % Zero deadline tolerance
        
        % check whether deadline toleracne is less than period
        if (checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol ) == 0)
            fprintf('Invalid deadline tolerance: %0.3f for Util group %d, RT taskset %d .\n',rt_deadline_tol, i, j);
            %continue;
            return;
        end
        
        [server_util_0, Q_0, P_0,...
            server_status_0, count_0, obj_value_0,...
            Tstar_0, period_status_0, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc,...
            low_prio_tol, rt_deadline_tol );
        
        % if solution found, check mode-change overhead
        if strcmp(server_status_0,'Solved') && strcmp(period_status_0,'Solved')
            startIndex = rt_tc.ntask - server_priority_level + 1; % calculate the starting index of low prio RT task
            fprintf('Total RT tasks %d, server priority %d, starting # of low-priority %d.\n',rt_tc.ntask, server_priority_level, startIndex);
            isShed = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q_0, P_0 );
            
            if isShed == 1
                fprintf('\n == INFO (Tolerance %0.2f, Util group %d, RT taskset %d) == \n',rt_deadline_tol, i, j);
                fprintf('RT tasks are schedulable with mode change!\n');
            else
                fprintf('\n == INFO (Tolerance %0.2f, Util group %d, RT taskset %d) == \n',rt_deadline_tol, i, j);
                fprintf('RT tasks are *NOT* schedulable with mode change!\n');
            end
        end
        


%     end
% end




disp('Done everything');

clear global QUIET; % turn on reporting from GP
