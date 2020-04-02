function [ wcrt ] = getWCRT_Approx_ceil_off( index, rt_tc, D_prime, Q, P )
% returns the WCRT using ceil-off approximation (Eq. 8, CERTS)

intf  = 0;
for i=1:index-1
    intf = intf + ceil(D_prime/rt_tc.periods(i)) * rt_tc.wcets(i);
end

% add the interference from Server
intf = intf  + ( (D_prime/P) + 1) * Q;

wcrt = rt_tc.wcets(index) + intf;

end

