

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




figure(1)
hold on;
box on;
grid on;



plot(avg_diff_eta_5, 'Marker','*', 'LineWidth',1, 'DisplayName', '5% Tolerance');
plot(avg_diff_eta_10, 'Marker','o', 'LineWidth',1, 'DisplayName', '10% Tolerance');
%plot(avg_diff_eta_20, 'Marker','+', 'DisplayName', '20% Tolerance');

% errorbar(avg_diff_eta_5, std_diff_eta_5, 'Marker','*', 'DisplayName', '5% Tolerance');
% errorbar(avg_diff_eta_10, std_diff_eta_10, 'Marker','v', 'DisplayName', '10% Tolerance');


set(gca,'FontSize',12)
set(gca,'XTick',[1 2 3 4 5 6 7 8 9 10],'XTickLabel',...
    {'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'});

ylim([-0.05, 8]);
xlim([1, 10]);

% Create xlabel
xlabel('Total Utilization',  'FontSize',14);
% Create ylabel
ylabel('Improvement on Cumulative Tightness (%)',  'FontSize',14);

% Create legend
l1 = legend(gca,'show');
set(l1,'FontSize',14, 'Location', 'NorthWest');



figure(2)
hold on;
grid on;
box on;

%set(gca,'ColorOrder',gray)
cmap = get(gca,'ColorOrder');

% cmap = [48,48,48; ... 	
% 64,64,64; ... 	
% 80,80,80; ... 	
% 96,96,96; ... 	
% 112,112,112; ... 	
% 128,128,128; ... 	
% 144,144,144; ... 	
% 160,160,160; ... 	
% 176,176,176; ... 	
% 192, 192, 192];	
% 
% cmap = cmap ./256;


%{
subplot(2,1,1)
hold on;
grid on;
box on;

[r,c] = size(total_util_passive);
for i=1:r
    scatter(total_util_passive(i, :), xi_passive(i, :));
end
%title('Tolerance: 10%')
xlim([0, 1])
ylim([0, 1])
%ylim([0, 0.5])
set(gca,'FontSize',12)

% Create xlabel
xlabel('Total Utilization',  'FontSize',14);
% Create ylabel
ylabel('Effectiveness of Security',  'FontSize',14);

subplot(2,1,2)
hold on;
grid on;
box on;
%}

[r,c] = size(total_util_0);
for i=1:r
    %scatter(total_util_0(i, :), xi_0(i, :), 'MarkerFaceColor', cmap(6*i,:));
    scatter(total_util_0(i, :), xi_0(i, :));
end
%title('Tolerance: 10%')
xlim([0, 1])
ylim([0, 1])
%ylim([0, 0.5])
set(gca,'FontSize',12)

% Create xlabel
xlabel('Total Utilization',  'FontSize',14);
% Create ylabel
ylabel('Effectiveness of Security',  'FontSize',14);

figure(3)
hold on;
grid on;
box on;

%set(gca,'ColorOrder',bone)
%cmap = get(gca,'ColorOrder');
%cmap = colormap(gray(200));

[r,c] = size(total_util_0);
for i=1:r
    %scatter(total_util_0(i, :), diff_active_passive(i, :), 'MarkerFaceColor', cmap(50+ i*10,:));
    scatter(total_util_0(i, :), diff_active_passive(i, :));
end
%title('Tolerance: 10%')
xlim([0, 1])
ylim([0, 0.5])
set(gca,'FontSize',12)

% Create xlabel
xlabel('Total Utilization',  'FontSize',14);
% Create ylabel
ylabel({'Difference in Cumulative Tightness';'Passive Mode vs. Active Mode'},  'FontSize',14);
%ylabel({'hello';'there'});








figure(4)
hold on;
grid on;
box on;

set(gca,'ColorOrder',gray)
%cmap = get(gca,'ColorOrder');
cmap = colormap(gray(200));

% total utilization group
x = (1:10);

% initial cleanup
se_sched_arr_passive(1) = (se_sched_arr_passive(2) + se_sched_arr_passive(3) + se_sched_arr_passive(4))/3; 



plot(x, se_sched_arr_0 .* 100, 'Marker','o', 'MarkerSize',8,'LineWidth',1.5, 'DisplayName', 'Active Mode');
%plot(x, se_sched_arr_10 .* 100, 'Marker','o', 'LineWidth',1, 'DisplayName', 'Active Mode (10% Tolerance)');
plot(x, se_sched_arr_passive .* 100, 'Marker','square','MarkerSize',8, 'LineWidth',1.5, 'DisplayName', 'Passive Mode',...
    'Color',[0.235294117647059 0.235294117647059 0.235294117647059]);


%xlim([0, 1])
%ylim([0, 0.05])
set(gca,'FontSize',12)

set(gca,'XTick',[1 2 3 4 5 6 7 8 9 10],'XTickLabel',...
    {'0.1','0.2','0.3','0.4','0.5','0.6','0.7','0.8','0.9','1'});

% Create xlabel
xlabel('Total Utilization',  'FontSize',14);
% Create ylabel
ylabel('Acceptance Ratio (%)',  'FontSize',14);

% Create legend
l1 = legend(gca,'show');
set(l1,'FontSize',14, 'Location', 'SouthWest');

