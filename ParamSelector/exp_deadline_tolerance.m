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

n_tc_eachGrp = 500; % number of task set in each utlization group

base_util_ngroup = 10; % number of base utilization group (0 to 1, total 10)

% determine how many tasks can be ...
% lower priority than the security server
low_prio_tol = 0.4; % ceil(N_RT_TASK * low_prio_tol)
%rt_deadline_tol = 0.2; % 20% deadline tolerance


% get the RT and SE taskset
% each row of the struct represents the base utilization group

[ rt_taskset, se_taskset ] = get_RT_SE_TaskSets( base_util_ngroup, n_tc_eachGrp,...
    rt_ntask_min, rt_ntask_max, rt_periodmin, rt_periodmax, rt_deadline_factor,...
    se_ntask_min, se_ntask_max, se_periodmin, se_periodmax, ...
    se_period_des_factor, se_util_portion);



% initialize with NaN values for better plotting

xi_passive = NaN(base_util_ngroup, n_tc_eachGrp);
xi_0 = NaN(base_util_ngroup, n_tc_eachGrp);
xi_5 = NaN(base_util_ngroup, n_tc_eachGrp);
xi_10 = NaN(base_util_ngroup, n_tc_eachGrp);
xi_20 = NaN(base_util_ngroup, n_tc_eachGrp);


eta_passive = NaN(base_util_ngroup, n_tc_eachGrp);
eta_0 = NaN(base_util_ngroup, n_tc_eachGrp);
eta_5 = NaN(base_util_ngroup, n_tc_eachGrp);
eta_10 = NaN(base_util_ngroup, n_tc_eachGrp);
eta_20 = NaN(base_util_ngroup, n_tc_eachGrp);

total_util_passive = NaN(base_util_ngroup, n_tc_eachGrp);
total_util_0 = NaN(base_util_ngroup, n_tc_eachGrp);
total_util_5 = NaN(base_util_ngroup, n_tc_eachGrp);
total_util_10 = NaN(base_util_ngroup, n_tc_eachGrp);
total_util_20 = NaN(base_util_ngroup, n_tc_eachGrp);

rt_sched_arr = NaN(base_util_ngroup, 1);
se_sched_arr_passive = NaN(base_util_ngroup, 1);
se_sched_arr_0 = NaN(base_util_ngroup, 1);
se_sched_arr_5 = NaN(base_util_ngroup, 1);
se_sched_arr_10 = NaN(base_util_ngroup, 1);
se_sched_arr_20 = NaN(base_util_ngroup, 1);




for i=1:base_util_ngroup
    
    % counts total number of schedulable RT and SE tasksets in each
    % utilization group
    rt_sched_count = 0; 
    se_sched_count_passive = 0;
    se_sched_count_0 = 0;
    se_sched_count_5 = 0;
    se_sched_count_10 = 0;
    se_sched_count_20 = 0;
    
    for j=1:n_tc_eachGrp
        
        rt_tc = rt_taskset(i,j);
        se_tc = se_taskset(i,j);
        

        isSched = get_RT_schedulability( rt_tc );
        
        if isSched == 0
            fprintf('Util group %d, RT taskset %d is NOT SCHEDULABLE!\n', i, j);
            continue;
        end
        
        rt_sched_count = rt_sched_count+1;
        
        % get the server parameters and optimal Secuirty periods
        % (PASSIVE/OPPORTUNISTIC Mode)
        [server_util_passive, Q_passive, P_passive,...
            server_status_passive, count_passive, obj_value_passive,...
            Tstar_passive, period_status_passive ] = GetPeriod_N_ServerParam_passive( rt_tc, se_tc );
        
        if strcmp(server_status_passive,'Solved') && strcmp(period_status_passive,'Solved')
            total_util_passive(i,j) = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
            xi_passive(i,j) = get_eta(se_tc, Tstar_passive);
            eta_passive(i,j) = 1/obj_value_passive;
            
            % incerease schedulability counter
            se_sched_count_passive = se_sched_count_passive + 1;
        end
        


        % get the server parameters and optimal Secuirty periods
        % (ACTIVE Mode tolerance: 0)
        
        rt_deadline_tol = 0.00; % Zero deadline tolerance
        
        % check whether deadline toleracne is less than period
        if (checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol ) == 0)
            fprintf('Invalid deadline tolerance: %0.3f for Util group %d, RT taskset %d .\n',rt_deadline_tol, i, j);
            continue;
        end
        
        [server_util_0, Q_0, P_0,...
            server_status_0, count_0, obj_value_0,...
            Tstar_0, period_status_0, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc,...
            low_prio_tol, rt_deadline_tol );
        
        % if solution found, check mode-change overhead
        if strcmp(server_status_0,'Solved') && strcmp(period_status_0,'Solved')
            startIndex = rt_tc.ntask - server_priority_level + 1; % calculate the starting index of low prio RT task
            %fprintf('Total RT tasks %d, server priority %d, starting # of low-priority %d.\n',rt_tc.ntask, server_priority_level, startIndex);
            isShed = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q_0, P_0 );
            
            if isShed == 1
                %fprintf('\n == INFO (Tolerance %0.2f, Util group %d, RT taskset %d) == \n',rt_deadline_tol, i, j);
                %fprintf('RT tasks are schedulable with mode change!\n');
                
                total_util_0(i,j) = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
                xi_0(i,j) = get_eta(se_tc, Tstar_0);
                eta_0(i,j) = 1/obj_value_0;
            
                % incerease schedulability counter
                se_sched_count_0 = se_sched_count_0 + 1;
                
            
            end
        end
        
        
        % get the server parameters and optimal Secuirty periods
        % (ACTIVE Mode tolerance: 5%)
        
        rt_deadline_tol = 0.05; % 5% deadline tolerance
        
        % check whether deadline toleracne is less than period
        if (checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol ) == 0)
            fprintf('Invalid deadline tolerance: %0.3f for Util group %d, RT taskset %d .\n',rt_deadline_tol, i, j);
            continue;
        end
        
        [server_util_5, Q_5, P_5,...
            server_status_5, count_5, obj_value_5,...
            Tstar_5, period_status_5, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc,...
            low_prio_tol, rt_deadline_tol );
        
        % if solution found, check mode-change overhead
        if strcmp(server_status_5,'Solved') && strcmp(period_status_5,'Solved')
            startIndex = rt_tc.ntask - server_priority_level + 1; % calculate the starting index of low prio RT task
            %fprintf('Total RT tasks %d, server priority %d, starting # of low-priority %d.\n',rt_tc.ntask, server_priority_level, startIndex);
            isShed = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q_5, P_5 );
            
            if isShed == 1
                %fprintf('\n == INFO (Tolerance %0.2f, Util group %d, RT taskset %d) == \n',rt_deadline_tol, i, j);
                %fprintf('RT tasks are schedulable with mode change!\n');
                
                total_util_5(i,j) = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
                xi_5(i,j) = get_eta(se_tc, Tstar_5);
                eta_5(i,j) = 1/obj_value_5;
            
                % incerease schedulability counter
                se_sched_count_5 = se_sched_count_5 + 1;
                
            
            end
        end
        
        
        % get the server parameters and optimal Secuirty periods
        % (ACTIVE Mode tolerance: 10%)
        
        rt_deadline_tol = 0.10; % 10% deadline tolerance
        
        % check whether deadline toleracne is less than period
        if (checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol ) == 0)
            fprintf('Invalid deadline tolerance: %0.3f for Util group %d, RT taskset %d .\n',rt_deadline_tol, i, j);
            continue;
        end
        
        [server_util_10, Q_10, P_10,...
            server_status_10, count_10, obj_value_10,...
            Tstar_10, period_status_10, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc,...
            low_prio_tol, rt_deadline_tol );
        
        % if solution found, check mode-change overhead
        if strcmp(server_status_10,'Solved') && strcmp(period_status_10,'Solved')
            startIndex = rt_tc.ntask - server_priority_level + 1; % calculate the starting index of low prio RT task
            %fprintf('Total RT tasks %d, server priority %d, starting # of low-priority %d.\n',rt_tc.ntask, server_priority_level, startIndex);
            isShed = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q_10, P_10 );
            
            if isShed == 1
                %fprintf('\n == INFO (Tolerance %0.2f, Util group %d, RT taskset %d) == \n',rt_deadline_tol, i, j);
                %fprintf('RT tasks are schedulable with mode change!\n');
                
                total_util_10(i,j) = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
                xi_10(i,j) = get_eta(se_tc, Tstar_10);
                eta_10(i,j) = 1/obj_value_10;
            
                % incerease schedulability counter
                se_sched_count_10 = se_sched_count_10 + 1;
                
            
            end
        end
        
        
        % get the server parameters and optimal Secuirty periods
        % (ACTIVE Mode tolerance: 20%)
        
        rt_deadline_tol = 0.20; % 20% deadline tolerance
        
        % check whether deadline toleracne is less than period
        if (checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol ) == 0)
            fprintf('Invalid deadline tolerance: %0.3f for Util group %d, RT taskset %d .\n',rt_deadline_tol, i, j);
            continue;
        end
        
        [server_util_20, Q_20, P_20,...
            server_status_20, count_20, obj_value_20,...
            Tstar_20, period_status_20, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc,...
            low_prio_tol, rt_deadline_tol );
        
        % if solution found, check mode-change overhead
        if strcmp(server_status_20,'Solved') && strcmp(period_status_20,'Solved')
            startIndex = rt_tc.ntask - server_priority_level + 1; % calculate the starting index of low prio RT task
            %fprintf('Total RT tasks %d, server priority %d, starting # of low-priority %d.\n',rt_tc.ntask, server_priority_level, startIndex);
            isShed = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q_20, P_20 );
            
            if isShed == 1
                %fprintf('\n == INFO (Tolerance %0.2f, Util group %d, RT taskset %d) == \n',rt_deadline_tol, i, j);
                %fprintf('RT tasks are schedulable with mode change!\n');
                
                total_util_20(i,j) = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
                xi_20(i,j) = get_eta(se_tc, Tstar_20);
                eta_20(i,j) = 1/obj_value_20;
            
                % incerease schedulability counter
                se_sched_count_20 = se_sched_count_20 + 1;
                
            
            end
        end
  
    end
    
    rt_sched_arr(i) = rt_sched_count;
    se_sched_arr_passive(i) = se_sched_count_passive / rt_sched_count;
    se_sched_arr_0(i) = se_sched_count_0 / rt_sched_count;
    se_sched_arr_5(i) = se_sched_count_5 / rt_sched_count;
    se_sched_arr_10(i) = se_sched_count_10 / rt_sched_count;
    se_sched_arr_20(i) = se_sched_count_20 / rt_sched_count;
end

% saves in major utilization group (like Budgeted GRAMS paper)

se_sched_arrV2_passive = NaN(4, 1);
se_sched_arrV2_0 = NaN(4, 1);
se_sched_arrV2_5 = NaN(4, 1);
se_sched_arrV2_10 = NaN(4, 1);
se_sched_arrV2_20 = NaN(4, 1);


se_sched_arrV2_passive(1) = sum(se_sched_arr_passive(1:3))/sum(rt_sched_arr(1:3));
se_sched_arrV2_passive(2) = sum(se_sched_arr_passive(3:5))/sum(rt_sched_arr(3:5));
se_sched_arrV2_passive(3) = sum(se_sched_arr_passive(5:7))/sum(rt_sched_arr(5:7));
se_sched_arrV2_passive(4) = sum(se_sched_arr_passive(7:10))/sum(rt_sched_arr(7:10));

se_sched_arrV2_0(1) = sum(se_sched_arr_0(1:3))/sum(rt_sched_arr(1:3));
se_sched_arrV2_0(2) = sum(se_sched_arr_0(3:5))/sum(rt_sched_arr(3:5));
se_sched_arrV2_0(3) = sum(se_sched_arr_0(5:7))/sum(rt_sched_arr(5:7));
se_sched_arrV2_0(4) = sum(se_sched_arr_0(7:10))/sum(rt_sched_arr(7:10));

se_sched_arrV2_5(1) = sum(se_sched_arr_5(1:3))/sum(rt_sched_arr(1:3));
se_sched_arrV2_5(2) = sum(se_sched_arr_5(3:5))/sum(rt_sched_arr(3:5));
se_sched_arrV2_5(3) = sum(se_sched_arr_5(5:7))/sum(rt_sched_arr(5:7));
se_sched_arrV2_5(4) = sum(se_sched_arr_5(7:10))/sum(rt_sched_arr(7:10));

se_sched_arrV2_10(1) = sum(se_sched_arr_10(1:3))/sum(rt_sched_arr(1:3));
se_sched_arrV2_10(2) = sum(se_sched_arr_10(3:5))/sum(rt_sched_arr(3:5));
se_sched_arrV2_10(3) = sum(se_sched_arr_10(5:7))/sum(rt_sched_arr(5:7));
se_sched_arrV2_10(4) = sum(se_sched_arr_10(7:10))/sum(rt_sched_arr(7:10));

se_sched_arrV2_20(1) = sum(se_sched_arr_20(1:3))/sum(rt_sched_arr(1:3));
se_sched_arrV2_20(2) = sum(se_sched_arr_20(3:5))/sum(rt_sched_arr(3:5));
se_sched_arrV2_20(3) = sum(se_sched_arr_20(5:7))/sum(rt_sched_arr(5:7));
se_sched_arrV2_20(4) = sum(se_sched_arr_20(7:10))/sum(rt_sched_arr(7:10));


% save to a mat file
save('data_all.mat',...
    'total_util_passive', 'total_util_0', 'total_util_5', 'total_util_10', 'total_util_20', ...
    'xi_passive', 'xi_0', 'xi_5', 'xi_10', 'xi_20',...
    'eta_passive', 'eta_0', 'eta_5', 'eta_10', 'eta_20',...
    'se_sched_arr_passive', 'se_sched_arr_0', 'se_sched_arr_5', 'se_sched_arr_10', 'se_sched_arr_20',...
    'se_sched_arrV2_passive', 'se_sched_arrV2_0', 'se_sched_arrV2_5', 'se_sched_arrV2_10', 'se_sched_arrV2_20');




disp('Done everything');

clear global QUIET; % turn on reporting from GP
