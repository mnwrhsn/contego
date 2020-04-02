function [ mode_change_wcrt ] = getModeChangeWCRT( index, x_vector, rt_tc, Q, P )
% Returns the maximum WCRT in the window size

mode_change_wcrt = 0;

for j=1:length(x_vector)
    x = x_vector(j);
    tmp_mc_wcrt = getModeChange_WCRT_i( index, x, rt_tc, Q, P );
    
    % saves the maximum in range [0, steady-state-res-time]
    if tmp_mc_wcrt > mode_change_wcrt
        mode_change_wcrt = tmp_mc_wcrt;
    end
end

end

