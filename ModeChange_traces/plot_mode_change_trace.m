clc;
clear;
close all;

data_all = csvread('data_all.csv');

data_without_mode_change = data_all(:, 2);
data_with_mode_change = data_all(:, 1);

% data_without_mode_change = csvread('no_mode_change.txt');
% data_with_mode_change = csvread('mode_change.txt');

figure(1)
hold on
grid on
box on

set(gca,'FontSize',12);

[f,x] = ecdf(data_with_mode_change);
% plot(x,f,'DisplayName','With Mode Change','Marker','o','LineWidth',1,...
%     'Color',[0.850980401039124 0.325490206480026 0.0980392172932625]);

% Create plot
plot(x,f,'ZDataSource','','DisplayName','With Mode Change','Marker','.',...
    'LineWidth',1.5,...
    'Color',[0.313725501298904 0.313725501298904 0.313725501298904]);


[f,x] = ecdf(data_without_mode_change);
% plot(x,f,'DisplayName','Without Mode Change','Marker','square',...
%     'LineWidth',1,...
%     'Color',[0 0.447058826684952 0.74117648601532]);

% Create plot
plot(x,f,'ZDataSource','','DisplayName','Without Mode Change',...
    'Marker','.',...
    'LineWidth',2.5,...
    'LineStyle',':',...
    'Color',[0.24705882370472 0.24705882370472 0.24705882370472]);

% Create xlabel
xlabel('Detection Time (Cycle Count)',  'FontSize',14);
% Create ylabel
ylabel('Empirical CDF',  'FontSize',14);

% Create legend
legend1 = legend(gca,'show');
set(legend1,'FontSize',14, 'Location', 'southeast');





%{
figure(2)

%data_all = [data_passive, data_active];

bar(data_all);

figure(3)

data_diff = data_without_mode_change - data_with_mode_change;
bar(data_diff);
%}

m_a = mean(data_with_mode_change);
m_p = mean(data_without_mode_change);

decrease = m_p - m_a;
decreasePercentage = decrease / m_p;

std_val = ( std(data_without_mode_change) - std(data_with_mode_change) )/ std(data_without_mode_change);

fprintf('Improvement in detection time %f (with standard deviation %f) \n', decreasePercentage*100, std_val );



disp('Done everything');

