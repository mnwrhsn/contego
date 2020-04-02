function [ isFeasible ] = checkRT_Deadline_Tol_Feasibility( rt_tc, low_prio_tol, rt_deadline_tol )
% Check whether deadline + tolerance is less than period for low priority
% RT tasks

isFeasible = 1;
n_low_prio = ceil(rt_tc.ntask * low_prio_tol);

startIndex = rt_tc.ntask - n_low_prio + 1; % calculate the starting index of low prio RT task

for i=startIndex:rt_tc.ntask
    D_prime = rt_tc.deadlines(i) + rt_tc.deadlines(i)*rt_deadline_tol;
    
    if rt_tc.periods(i) - D_prime < 0
        isFeasible = 0;
        break;
    end
end


end

