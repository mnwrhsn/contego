function [ sig_val ] = getMostSigValues( P, steady_state_resp_time, epsilon )
% returns the most significant values of the window size X

sig_val = zeros(10000000, 1); % wild guess preallocation

sv = 0;
i = 1;
while sv <= steady_state_resp_time + 1 % add 1 for padding
    sig_val(i) = sv;
    sv = sv + (i-1) * P + epsilon;
    i = i + 1;
end

sig_val(i-1:end) = []; % remove unused slots



end

