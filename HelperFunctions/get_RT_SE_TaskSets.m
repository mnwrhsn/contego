function [ RT_taskset, SE_taskset ] = get_RT_SE_TaskSets( base_util_ngroup, n_tc_eachGrp,...
    n_RT_task_min, n_RT_task_max, RT_periodmin, RT_periodmax, RT_deadline_factor,...
    n_SE_task_min, n_SE_task_max, SE_periodmin, SE_periodmax,...
    SE_period_des_factor, SE_util_portion)
% Given number of base utilization group and the number of taskset each group,
% returns the total Real-Time task sets

RT_taskset = struct('ntask', {}, 'utilizations',{},'periods',{}, 'deadlines',{}, 'wcets',{});
SE_taskset = struct('ntask', {}, 'utilizations',{},'periods_des',{},'periods_max',{},'periods',{},'wcets',{});

for i =1:base_util_ngroup
    
    ulow = 0.01+0.1*(i-1);
    uhigh = 0.1+0.1*(i-1);
    
    for j=1:n_tc_eachGrp
        
        u = (uhigh-ulow).*rand(1,1) + ulow; % get a random utilzation in this range
        u_RT = (1-SE_util_portion) * u; % calculate RT utilization portion
        u_SE = SE_util_portion * u; % calculate SE utilization portion
        
        %%%
        % generate RT task set
        n = randi([n_RT_task_min n_RT_task_max],1,1); % decide how many tasks in the task set
        
        periods = randi([RT_periodmin RT_periodmax],1,n);
        periods = sort(periods); % index 1 has the shortest period (eg, higher RM priority)
        utilizations = UUniFast(n, u_RT); % get utlization of each task
        wcets = utilizations .* periods;
        
        RT_taskset(i,j).ntask = n;
        RT_taskset(i,j).periods = periods;
        RT_taskset(i,j).deadlines = floor(RT_deadline_factor .* periods);
        RT_taskset(i,j).utilizations = utilizations;
        RT_taskset(i,j).wcets = wcets;
        %%%
        
       
        % generate SE task set
        n = randi([n_SE_task_min n_SE_task_max],1,1); % decide how many tasks in the task set
        
        periods_des = randi([SE_periodmin SE_periodmax],1,n);
        periods_des = sort(periods_des); % index 1 has the shortest period (eg, higher RM priority)
        utilizations = UUniFast(n, u_SE); % get utlization of each task
        wcets = utilizations .* periods_des;
        
        SE_taskset(i,j).ntask = n;
        SE_taskset(i,j).periods_des = periods_des;
        %SE_taskset(i,j).periods_max = periods_des + SE_period_des_factor .* periods_des;
        SE_taskset(i,j).periods_max = SE_period_des_factor .* periods_des;
        %taskset(i,j).periods = -1 .* ones(1, n); % initialized to -1 (later updated with optimization routine)
        %SE_taskset(i,j).periods = SE_taskset(i,j).periods_max; % initialized to max period (later updated with optimization routine)
        SE_taskset(i,j).periods = SE_taskset(i,j).periods_des; % initialized to desired period (later updated with optimization routine)
        SE_taskset(i,j).utilizations = utilizations;
        SE_taskset(i,j).wcets = wcets;
        
        
        
    end
end


end

