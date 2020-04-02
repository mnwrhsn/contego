function [ server_util, Q, P,...
    server_status, count, obj_value,...
    Tstar, period_status, server_priority_level ] = GetPeriod_N_ServerParam_active( rt_tc, se_tc, low_prio_tol, rt_deadline_tol )

% get the optimal server parameters and Security tasks periods

%{
server_util = -1; Q = -1; P = -1;
server_status = -1; count = -1; obj_value = -1;
Tstar = -1; period_status = -1;
%}


% n_low_prio : to be calculated

%server_status = -1;
%period_status = -1;

n_low_prio = ceil(rt_tc.ntask * low_prio_tol);
%n_low_prio
%fprintf('Server priority promotion level: %d. \n', n_low_prio);

ecdist_arr = -1 .* ones(1, n_low_prio);
P_arr = -1 .* ones(1, n_low_prio);
Q_arr = -1 .* ones(1, n_low_prio);
count_arr = -1 .* ones(1, n_low_prio);
eta_arr = -1 .* ones(1, n_low_prio);
Tstar_arr = cell(1, n_low_prio);

server_status_arr = cell(1, n_low_prio);
period_status_arr = cell(1, n_low_prio);



% i=0 means opportunistic execution

% we start with 1

for i=1:n_low_prio
    % initialize to garbage value
    server_util = -1; Q = -1; P = -1;
    server_status = -1; count = -1; obj_value = -1;
    Tstar = -1; period_status = -1;
    
    %fprintf('Current level: %d. \n', i);
    
    [server_util, Q, P, server_status, count ] = getServerParamGP_Active( rt_tc, se_tc,...
        i, rt_deadline_tol );
    % server_util, Q, P, server_status, count
    
    % no server parameter found, check for next priority level
    if ~strcmp(server_status,'Solved')
        fprintf('Cannot find any server parameter at priority level %d. \n', i);
        %return;
        continue;
    end
    
    budget = getBudget(se_tc.ntask, Q, P);
    
    % fprintf('Rajkumar Paper Constraint %0.3f. \n',(3*P- 2*Q));
    
    % Rajkumar bound is not satisfied, check for next priority level
    if (3*P- 2*Q) < 0
        fprintf('Rajkumar Bound Error P %d, Q %d. \n',P, Q);
        %break;
        %return;
        continue;
    end
    
    [ obj_value, Tstar, period_status ] = getOptimalPeriodGP_passive( se_tc.ntask, se_tc.wcets', ...
        se_tc.periods_des', se_tc.periods_max', budget, Q, P  );
    
    %obj_value, Tstar, period_status, %se_tc.periods_des', se_tc.periods'
    
    % no feasible period found, check for next priority level
    if ~strcmp(period_status,'Solved')
        fprintf('Cannot find suitable periods. \n');
        %break;
        %return;
        continue;
    end
    
    % solution found! Return the values from optimization routine
    if strcmp(server_status,'Solved') && strcmp(period_status,'Solved')
         fprintf('Solution found for server parameter at priority level %d. \n', i);
        %fprintf('There are %d task(s) lower priority than server.\n', i);
        %break;
        % calculate Euclidean distacne
        ecdist = get_eta( se_tc, Tstar );
        ecdist_arr(i+1) = ecdist;
        P_arr(i+1) = P;
        Q_arr(i+1) = Q;
        count_arr(i+1) = count;
        eta_arr(i+1) = 1/obj_value;
        Tstar_arr{i+1} = Tstar;
        
        server_status_arr{i+1} = server_status;
        period_status_arr{i+1} = period_status;
        
        %fprintf('Effectiveness in level %d is: %f.\n', i, ecdist);
    end
    
end

%fprintf('Ecdist: %5.2e\n',ecdist_arr);
%fprintf('Eta: %5.2e\n',eta_arr);

% ecdist_arr
% [M, I] = min(ecdist_arr)




% get the maximum security parameters
[~, indx] = max(eta_arr);
%fprintf('Index: %d\n',indx);

% return the maximum parameters
Q = Q_arr(indx); P = P_arr(indx);
count = count_arr(indx); obj_value = 1/eta_arr(indx);
Tstar = Tstar_arr{indx};
server_status = server_status_arr{indx};
period_status = period_status_arr{indx};

server_priority_level = indx - 1;

%     server_status
%     period_status

end

