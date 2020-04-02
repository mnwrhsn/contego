function [ ecdist ] = get_eta( se_tc, Tstar )
% Return the Euclidean distacne

ecdist = norm(Tstar' - se_tc.periods_des)/norm(se_tc.periods_max - se_tc.periods_des);


end

