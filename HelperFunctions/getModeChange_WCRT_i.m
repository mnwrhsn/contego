function [ wcrt ] = getModeChange_WCRT_i( index, x, rt_tc, Q, P )
% Calculate mode change WCRT for a given window size x for task with 
% ID index


wcrt_old = rt_tc.wcets(index);
wcrt = -1;
countMax = 1500;
count =0;


while 1
    
    intf  = 0;
    for i=1:index-1
        intf = intf + ceil(wcrt_old/rt_tc.periods(i)) * rt_tc.wcets(i);
    end
    % see Eq. 1 in monowar_server_8.2.pdf
    wcrt_new = rt_tc.wcets(index) + ceil(x / P) * Q + intf; 
    count = count + 1;
    
    if count >= countMax
        disp('WCRT not found!');
        wcrt = -1;
        return;
    end
    
    if wcrt_new == wcrt_old
        wcrt = wcrt_new;
        %disp('End WCRT!!');
        return;
        %break;
    else
        
        wcrt_old = wcrt_new;
    end
    
end


end

