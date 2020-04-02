

% plot the eta/effetiveness

clc;
clear;
%clear all;
clf;




% load from the mat file
load('data_all.mat',...
    'total_util_passive', 'total_util_0', 'total_util_5', 'total_util_10', 'total_util_20', ...
    'xi_passive', 'xi_0', 'xi_5', 'xi_10', 'xi_20',...
    'eta_passive', 'eta_0', 'eta_5', 'eta_10', 'eta_20',...
    'se_sched_arr_passive', 'se_sched_arr_0', 'se_sched_arr_5', 'se_sched_arr_10', 'se_sched_arr_20',...
    'se_sched_arrV2_passive', 'se_sched_arrV2_0', 'se_sched_arrV2_5', 'se_sched_arrV2_10', 'se_sched_arrV2_20');


% change xi to percentage

xi_passive = 1-xi_passive;
% xi_passive = xi_passive .* 100;

xi_0 = 1- xi_0;
% xi_0 = xi_0 .* 100;

xi_5 = 1- xi_5;
% xi_5 = xi_5 .* 100;

xi_10 = 1- xi_10;
% xi_10 = xi_10 .* 100;

xi_20 = 1- xi_20;
% xi_20 = xi_20 .* 100;


diff_active_passive = eta_0 - eta_passive;

diff_eta_5 = ((eta_5 - eta_0) ./ eta_0) .* 100;
diff_eta_10 = ((eta_10 - eta_0) ./ eta_0) .* 100;
diff_eta_20 = ((eta_20 - eta_0) ./ eta_0) .* 100;


avg_diff_eta_5 = nanmean(diff_eta_5, 2);
avg_diff_eta_10 = nanmean(diff_eta_10, 2);
avg_diff_eta_20 = nanmean(diff_eta_20, 2);

std_diff_eta_5 = nanstd(diff_eta_5, 1, 2);
std_diff_eta_10 = nanstd(diff_eta_10, 1, 2);
std_diff_eta_20 = nanstd(diff_eta_20, 1, 2);

legend_font_size = 25;
axis_font_size = 25;
tick_font_size = 13;





figure(1)
hold on;
grid on;
box on;

[r,c] = size(total_util_0);
for i=1:r
    %scatter(total_util_0(i, :), diff_active_passive(i, :), 'MarkerFaceColor', cmap(50+ i*10,:));
    scatter(total_util_0(i, :), diff_active_passive(i, :));
end
%title('Tolerance: 10%')
xlim([0, 1])
ylim([0, 0.5])
set(gca,'FontSize',tick_font_size)

% Create xlabel
xlabel('Total Utilization',  'FontSize',axis_font_size);
% Create ylabel
ylabel({'Difference in Cumulative Tightness'},  'FontSize',axis_font_size);
%ylabel({'hello';'there'});

saveas(gcf,'diff_eta_active_passive_color','epsc')






figure(2)
hold on;
grid on;
box on;



[r,c] = size(total_util_0);
for i=1:r
    %scatter(total_util_0(i, :), xi_0(i, :), 'MarkerFaceColor', cmap(6*i,:));
    scatter(total_util_0(i, :), xi_0(i, :));
end
%title('Tolerance: 10%')
xlim([0, 1])
ylim([0, 1])
%ylim([0, 0.5])
set(gca,'FontSize',tick_font_size)

% Create xlabel
xlabel('Total Utilization',  'FontSize',axis_font_size);
% Create ylabel
ylabel('Effectiveness of Security',  'FontSize',axis_font_size);


saveas(gcf,'xi_active_no_tol_color','epsc')





figure(3)
hold on;
grid on;
box on;


% total utilization group
x = (1:10);

% initial cleanup
se_sched_arr_passive(1) = (se_sched_arr_passive(2) + se_sched_arr_passive(3) + se_sched_arr_passive(4))/3; 



plot(x, se_sched_arr_0 .* 100, 'Marker','o', 'MarkerSize',8,'LineWidth',1.5, 'DisplayName', 'Active Mode');
plot(x, se_sched_arr_passive .* 100, 'Marker','*','MarkerSize',8, 'LineWidth',1.5, 'DisplayName', 'Passive Mode',...
    'Color',[0.164705882352941 0.384313725490196 0.274509803921569]);



%xlim([0, 1])
%ylim([0, 0.05])
set(gca,'FontSize',tick_font_size)

set(gca,'XTick',[1 2 3 4 5 6 7 8 9 10],'XTickLabel',...
    {'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'});

% Create xlabel
xlabel('Total Utilization',  'FontSize',axis_font_size);
% Create ylabel
ylabel('Acceptance Ratio (%)',  'FontSize',axis_font_size);

% Create legend
l1 = legend(gca,'show');
set(l1,'FontSize',axis_font_size, 'Location', 'SouthWest');

saveas(gcf,'active_passive_schedulability_color','epsc')


