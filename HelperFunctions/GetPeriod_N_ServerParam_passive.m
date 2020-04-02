function [ server_util, Q, P,...
    server_status, count, obj_value,...
    Tstar, period_status ] = GetPeriod_N_ServerParam_passive( rt_tc, se_tc )

% get the optimal server parameters and Security tasks periods

server_util = -1; Q = -1; P = -1;
server_status = -1; count = -1; obj_value = -1;
Tstar = -1; period_status = -1; 

%server_status = -1; 
%period_status = -1;


[server_util, Q, P, server_status, count ] = getServerParamGP_Passive( rt_tc, se_tc );
% server_util, Q, P, server_status, count

if ~strcmp(server_status,'Solved')
     fprintf('Cannot find any server parameter. \n');
   return;
end


budget = getBudget(se_tc.ntask, Q, P);

% fprintf('Rajkumar Paper Constraint %0.3f. \n',(3*P- 2*Q));
if (3*P- 2*Q) < 0
    fprintf('Rajkumar Bound Error P %d, Q %d. \n',P, Q);
    %break;
    return;
end

[ obj_value, Tstar, period_status ] = getOptimalPeriodGP_passive( se_tc.ntask, se_tc.wcets', ...
    se_tc.periods_des', se_tc.periods_max', budget, Q, P  );

%obj_value, Tstar, period_status, %se_tc.periods_des', se_tc.periods'


if ~strcmp(period_status,'Solved')
    fprintf('Cannot find suitable periods. \n');
    %break;
    return;
end





end

