

% data traces are in nanosecond
data_ahrs = csvread('ahrs.txt');
data_flightcontrol = csvread('flightcontrol.txt');
data_telemetry = csvread('telemetry.txt');


% just discard some initial jitter
data_ahrs = data_ahrs(5:end);
data_flightcontrol = data_flightcontrol(5:end);
data_telemetry = data_telemetry(5:end);


rt_timing_param_all = [max(data_ahrs), ...
    max(data_flightcontrol), max(data_telemetry)];


figure(1);
hold on;
box on;
bar(rt_timing_param_all);

% Create ylabel
ylabel('Execution Time (ns)');

% Set the remaining axes properties
set(gca,'XTick',[1 2 3],'XTickLabel',{'AHRS','FL\_CNTL','TEL'});

% Save to a MAT file
save('rt_timing.mat', 'rt_timing_param_all');

