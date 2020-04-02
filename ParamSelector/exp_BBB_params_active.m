clc;
clear;
close all;


% add GGPLAB to MATLAB path
folderName = fullfile(matlabroot,'toolbox','ggplab');
addpath(genpath(folderName));

% add helper fuctions directory
addpath(genpath('HelperFunctions/'));
addpath(genpath('BBB_Traces/'));

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


% sort according to RM order
% index 1 has the shortest period (eg, higher RM priority)

% load timing data from BBB experiments
load('rt_timing.mat', 'rt_timing_param_all');

% Priority AHRS -> FlightControl -> Telemetry
% where AHRS is the highest priority (shortest period)

rt_tc.ntask = 3;
rt_tc.periods = [1000, 5000, 10000];
rt_tc.deadlines = floor(rt_deadline_factor .* rt_tc.periods);
rt_tc.wcets = 1e-6 .* rt_timing_param_all; % change from ns to ms
rt_tc.wcets = rt_tc.wcets .* 10; % add padding
rt_tc.utilizations = rt_tc.wcets ./ rt_tc.periods;

isSched = get_RT_schedulability( rt_tc );

if isSched == 0
    fprintf('RT taskset is NOT SCHEDULABLE!\n');
    %continue;
    return;
end



% load timing data from BBB experiments
load('se_timing.mat', 'security_timing_param_active');

% ACTIVE Mode Priority order:
% FS_LIB > IDS_BIN > FS_BIN > NW_PCKT

se_tc.ntask = 4; % we have 4 Security tasks in ACTIVE Mode
se_tc.wcets = 1e-6 .* security_timing_param_active; % change from ns to ms
se_tc.wcets = sort(se_tc.wcets); % sort to maintain RM priority (lower WCET in fig, higher prio)
se_tc.utilizations = [0.1, 0.1, 0.1, 0.1];
se_tc.periods_des = se_tc.wcets ./ se_tc.utilizations;
%se_tc.periods_des = se_tc.periods_des + 10000;
se_tc.periods_max = se_period_des_factor .* se_tc.periods_des;
se_tc.periods = se_tc.periods_des;

% get the server parameters and optimal Secuirty periods
% (ACTIVE Mode tolerance: 0)

rt_deadline_tol = 0.00; % Zero deadline tolerance

% check whether deadline toleracne is less than period
if (checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol ) == 0)
    fprintf('Invalid deadline tolerance: %0.3f.\n',rt_deadline_tol);
    return;
end

[server_util_active, Q_active, P_active,...
    server_status_active, count_active, obj_value_active,...
    Tstar_active, period_status_active, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc,...
    low_prio_tol, rt_deadline_tol );

% if solution found, check mode-change overhead
if strcmp(server_status_active,'Solved') && strcmp(period_status_active,'Solved')
    startIndex = rt_tc.ntask - server_priority_level + 1; % calculate the starting index of low prio RT task
    %fprintf('Total RT tasks %d, server priority %d, starting # of low-priority %d.\n',rt_tc.ntask, server_priority_level, startIndex);
    isShed = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q_active, P_active );
    
    if isShed == 1
        
        fprintf('RT tasks are schedulable with mode change!\n');
        
        total_util_active = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
        xi_active = get_eta(se_tc, Tstar_active);
        eta_active = 1/obj_value_active;
        
        
        
    end
end




% display statistics

% ACTIVE Mode Priority order:
% FS_LIB > IDS_BIN > FS_BIN > NW_PCKT


fprintf('\n == Server Priority Level: %d ==\n\n', server_priority_level);


disp('Security Task parameters (ACTIVE MODE):');
fprintf('\n#########\nWCET:\n#########\n');
fprintf('FS_LIB: %f (ns)\n', se_tc.wcets(1)*1e6); % in nanosecond
fprintf('IDS_BIN: %f (ns)\n', se_tc.wcets(2)*1e6); % in nanosecond
fprintf('FS_BIN: %f (ns)\n', se_tc.wcets(3)*1e6); % in nanosecond
fprintf('NW_PCKT: %f (ns)\n', se_tc.wcets(4)*1e6); % in nanosecond



fprintf('\n\n#########\nPeriods (ACTIVE):\n#########\n');
fprintf('FS_LIB: %f (ns)\n', Tstar_active(1)*1e6); % in nanosecond
fprintf('IDS_BIN: %f (ns)\n', Tstar_active(2)*1e6); % in nanosecond
fprintf('FS_BIN: %f (ns)\n', Tstar_active(3)*1e6); % in nanosecond
fprintf('NW_PCKT: %f (ns)\n', Tstar_active(4)*1e6); % in nanosecond


disp('Done everything');

clear global QUIET; % turn on reporting from GP
