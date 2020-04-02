function [ isShed ] = check_mode_change_RT_sched( rt_tc, startIndex, rt_deadline_tol, Q, P )
% Determine whether the low-priority RT tasks are still schedulable with
% mode change


isShed = 1;
%n_low_prio = ceil(rt_tc.ntask * low_prio_tol);

%startIndex = rt_tc.ntask - n_low_prio + 1; % calculate the starting index of low prio RT task

for i=startIndex:rt_tc.ntask
    
    D_prime = rt_tc.deadlines(i) + rt_tc.deadlines(i)*rt_deadline_tol;
    steady_state_resp_time = getWCRT_withServer_i( i, rt_tc, Q, P );
    
    %disp('std state res time');
    %disp(steady_state_resp_time);
    % disp(P);
    
    %x = rt_tc.periods(i) + 1;
    
    %x_vector = getMostSigValues( P, steady_state_resp_time, 1 );
    
    
    
    %wcrt_approx = getWCRT_Approx_ceil_off( i, rt_tc, D_prime, Q, P );
    
    
    %disp('WCRT_approx');
    %disp(wcrt_approx);
    
    x_vector = steady_state_resp_time; % use steady-state WCRT as upper bound
    
    
    %x_vector = wcrt_approx;
    
    % use CERTS approximation as WCRT upper bound
    % x_vector = getMostSigValues( P, wcrt_approx, 1 );
    
    % get the most significant values of window based on steady-state
    % responce time
    % x_vector = getMostSigValues( P, steady_state_resp_time, 1 );
    
    mode_change_wcrt = getModeChangeWCRT( i, x_vector, rt_tc, Q, P );
    
    %mode_change_wcrt = ceil(mode_change_wcrt); % rounding off
    
    %disp('mode change res time');
    %disp(mode_change_wcrt);
    
    
    
    
    %disp('D_prime');
    %disp(D_prime);
    
    
    if mode_change_wcrt > D_prime
        isShed = 0; % task in not schedulable, return False
        break;
    end
  
end

end

