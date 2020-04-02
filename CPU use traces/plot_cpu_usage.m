clc;
clear;
close all;

maxduration = 500;

% data_rt = csvread('rt1.txt');
data_pa = csvread('pa2.txt');
data_ac = csvread('ac2.txt');

% trim some observations
data_pa = data_pa(1:maxduration);
data_ac = data_ac(1:maxduration);

% make in percentage
data_pa = data_pa .* 100; 
data_ac = data_ac .* 100; 

mean_data_pa = mean(data_pa);
mean_data_ac = mean(data_ac);

legend_font_size = 25;
axis_font_size = 25;
tick_font_size = 17;



% figure(1)
% hold on;
% box on;


%plot(data_rt);
% plot(data_pa);
% plot(data_ac);

% repmat(mean_data_ac,1,length(data_ac));

figure(2)
colormap gray
% cmap = get(gca,'ColorOrder');
cmap = colormap;

subplot(2,1,2)

hold on;
box on;
grid on;



%cmap = colormap(parula(3));
%cmap = colormap(parula(50));
% cmap = get(gca,'ColorOrder');

% a black color: 'Color',[0.313725501298904 0.313725501298904 0.313725501298904]...
stem(data_ac, ...
    'MarkerSize',3,'Marker','o','LineWidth',1,...
    'Color', cmap(30,:));

plot(repmat(mean_data_ac,1,maxduration),...
    'LineWidth',2,'LineStyle',':',...
    'Color', cmap(15,:));

set(gca,'FontSize',tick_font_size)

% Create xlabel
xlabel('Time (s)',  'FontSize',axis_font_size);
% Create ylabel
ylabel({'Active Mode';'CPU Load (%)'},  'FontSize',axis_font_size);

% figure(3)

subplot(2,1,1)
hold on;
box on;
grid on;
stem(data_pa,...
    'MarkerSize',3,'Marker','o','LineWidth',1,...
    'Color', cmap(30,:));
plot(repmat(mean_data_pa,1,maxduration),...
    'LineWidth',2,'LineStyle',':',...
   'Color', cmap(15,:));

set(gca,'FontSize',tick_font_size)

% Create xlabel
xlabel('Time (s)',  'FontSize',axis_font_size);
% Create ylabel
ylabel({'Passive Mode';'CPU Load (%)'},  'FontSize',axis_font_size);

saveas(gcf,'cpu_usage','epsc')


disp('Done everything');

