function [ isSched ] = get_RT_schedulability( rt_tc )
% calculate the schedulability of Real-time tasksets using WCRT analysis

isSched = 1;

for i=1:rt_tc.ntask
    wcrt = getWCRT_i( i, rt_tc );
    if wcrt > rt_tc.deadlines(i)
        isSched = 0;
        break;
    end
end


end

