

% data traces are in nanosecond
data_idsbin = csvread('idsbin.txt');
data_fsbin = csvread('fsbin.txt');
data_fslib = csvread('fslib.txt');
data_ker = csvread('ker.txt');
data_conf = csvread('conf.txt');
data_nwpckt = csvread('nwpckt.txt');

% just discard some initial jitter
data_idsbin = data_idsbin(5:end);
data_fsbin = data_fsbin(5:end);
data_fslib = data_fslib(5:end);
data_ker = data_ker(5:end);
data_conf = data_conf(5:end);
data_nwpckt = data_nwpckt(5:end);

security_timing_param_passive = [
    max(data_fsbin), max(data_nwpckt)];

security_timing_param_active = [max(data_idsbin),...
     max(data_fsbin), ...
     max(data_fslib), max(data_nwpckt)];

security_timing_param_all = [max(data_idsbin), ...
    max(data_fsbin), max(data_fslib), max(data_ker),...
    max(data_conf), max(data_nwpckt)];


figure(1);
hold on;
box on;
bar(security_timing_param_all);

% Create ylabel
ylabel('Execution Time (ns)');

% Set the remaining axes properties
set(gca,'XTick',[1 2 3 4 5 6],'XTickLabel',{'IDS\_BIN','FS\_BIN','FS\_LIB','KER','CONF', 'NW\_PCKT'});

% Save to a MAT file
save('se_timing.mat',...
    'security_timing_param_passive', 'security_timing_param_active');

