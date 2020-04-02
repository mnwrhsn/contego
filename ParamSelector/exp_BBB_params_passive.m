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
load('se_timing.mat', 'security_timing_param_passive');

% PASSIVE Mode Priority order:
% IDS_BIN > NW_PCKT


se_tc.ntask = 2; % we have 2 Security tasks in PASSIVE Mode
se_tc.wcets = 1e-6 .* security_timing_param_passive; % change from ns to ms
se_tc.wcets = sort(se_tc.wcets); % sort to maintain RM priority (lower WCET in fig, higher prio)
se_tc.utilizations = [0.2, 0.2];
se_tc.periods_des = se_tc.wcets ./ se_tc.utilizations; 
%se_tc.periods_des = se_tc.periods_des + 10000;
se_tc.periods_max = se_period_des_factor .* se_tc.periods_des;
se_tc.periods = se_tc.periods_des;

% get the server parameters and optimal Secuirty periods
% (PASSIVE/OPPORTUNISTIC Mode)

[server_util_passive, Q_passive, P_passive,...
    server_status_passive, count_passive, obj_value_passive,...
    Tstar_passive, period_status_passive ] = GetPeriod_N_ServerParam_passive( rt_tc, se_tc );

if strcmp(server_status_passive,'Solved') && strcmp(period_status_passive,'Solved')
    total_util_passive = sum(rt_tc.utilizations) + sum(se_tc.utilizations);
    xi_passive = get_eta(se_tc, Tstar_passive);
    eta_passive = 1/obj_value_passive;
    
end

% display statistics


disp('Security Task parameters (PASSIVE MODE):');
fprintf('\n#########\nWCET:\n#########\n');
fprintf('FS_BIN: %f (ns)\n', se_tc.wcets(1)*1e6); % in nanosecond
fprintf('NW_PCKT: %f (ns)\n', se_tc.wcets(2)*1e6); % in nanosecond

fprintf('\n\n#########\nPeriods (PASSIVE):\n#########\n');
fprintf('FS_BIN: %f (ns)\n', Tstar_passive(1)*1e6); % in nanosecond
fprintf('NW_PCKT: %f (ns)\n', Tstar_passive(2)*1e6); % in nanosecond


disp('Done everything');

clear global QUIET; % turn on reporting from GP
