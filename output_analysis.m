clc;clear; close all;
% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Reading the output from the simulations and generate plots
% to analyze the perfomance of the algos
%
% reading the files and storing in a variable
%
path = "C:\Users\serra\OneDrive\Documentos\TU Darmstadt\Masterthesis\4.stage - Resultados\scenario 2";
ai_path = "\results\AI_";
trad_path = "\traditional\TM_";
format = ".mat";
rowName = ["Milling 1", "Milling 2", "Sawing", "Cleaning & Drying", "Verification", "Laser", "Commissioning", "Powder coating", "Oven 1", "Oven 2", "Printer", "Montage" ,"Electrical_Function_Verification", "Packaging"];
dispName = {"Milling 1", "Milling 2", "Sawing", "Cleaning & Drying", "Verification", "Laser", "Commissioning", "Powder coating", "Oven 1", "Oven 2", "Printer", "Montage" ,"Electrical Function Verification", "Packaging"};
makeSpanName = ["Milling 1", "Sawing", "Laser", "Cleaning & Drying", "Verification" , "Commissioning", "Powder coating", "Oven 1", "Montage" ,"Electrical_Function_Verification", "Packaging"];
makeSpandispName = ["Milling 1", "Sawing", "Laser", "Cleaning & Drying", "Verification" , "Commissioning", "Powder coating", "Oven 1", "Montage" ,"Electrical Function Verification", "Packaging"];
products_with_label = ["ProductA_complete_", "ProductB_complete_", "ProductC_complete_", "ProductD_complete_", "ProductE_complete_", "ProductF_complete_", "ProductA_notLasered_", "ProductB_notLasered_", "ProductC_notLasered_","ProductD_notLasered_" ,"ProductE_notLasered_", "ProductF_notLasered_"];

% for the mse and mae
proc_stoptime = 0;
mse_stoptime = zeros(1,length(rowName));
mse_starttime = zeros(1, length(rowName));
mae_stoptime = zeros(1,length(rowName));
mae_starttime = zeros(1, length(rowName));

% for the makespan
makespan_trad = zeros(1,length(makeSpanName));
makespan_ai = zeros(1,length(makeSpanName));


ai = {};
trad = {};
storage = zeros(length(products_with_label),500);

for i = 1:1:500
    ai{end+1} = load(path+ai_path+i+format);
    trad{end+1} = load(path+trad_path+i+format);
end

aux = 1;

% find the corresponding values of comparance
for i = 1:length(trad)
    k = 1;
    for j = 1:length(ai)
        if trad{i}.Order_nr == ai{j}.Order_nr && trad{i}.storage_status_nr == ai{j}.storage_status_nr
            k = j;
            break;
        end
    end
    %
    % analysing the errors: mse and mae
    %
    for j  = 1:length(rowName)
        if j <= 10
            for l = 1:length(trad{i}.MachineStatus)
                pr_trad = trad{i}.MachineStatus{l};
                pr_ai = ai{k}.MachineStatus{l};
                mse_stoptime(j) = mse_stoptime(j) + hours(pr_trad{rowName{j}, "Stop_time"} - pr_ai{rowName{j}, "Stop_time"})^2;
                mae_stoptime(j) = mae_stoptime(j) + hours(pr_trad{rowName{j}, "Stop_time"} - pr_ai{rowName{j}, "Stop_time"});
                mse_starttime (j) = mse_starttime (j) + hours(pr_trad{rowName{j}, "Start_Time"} - pr_ai{rowName{j}, "Start_Time"})^2;
                mae_starttime (j) = mae_starttime (j) + hours(pr_trad{rowName{j}, "Start_Time"} - pr_ai{rowName{j}, "Start_Time"});
                proc_stoptime = proc_stoptime + 1;
            end
        else
            pr_trad = trad{i}.MachineStatus{1};
            pr_ai = ai{k}.MachineStatus{1};
            mse_stoptime(j) = mse_stoptime(j) + hours(pr_trad{rowName{j}, "Stop_time"} - pr_ai{rowName{j}, "Stop_time"})^2;
            mae_stoptime(j) = mae_stoptime(j) + hours(pr_trad{rowName{j}, "Stop_time"} - pr_ai{rowName{j}, "Stop_time"});
            mse_starttime(j) = mse_starttime(j) + hours(pr_trad{rowName{j}, "Start_Time"} - pr_ai{rowName{j}, "Start_Time"})^2;
            mae_starttime(j) = mae_starttime(j) + hours(pr_trad{rowName{j}, "Start_Time"} - pr_ai{rowName{j}, "Start_Time"});
            proc_stoptime = proc_stoptime + 1;
        end
        
    end

    %
    % analysing the makespan and generating plot
    %

    for j = 2:length(makeSpanName)
        pr_trad = trad{i}.MachineStatus{1};
        pr_ai = ai{k}.MachineStatus{1};
        makespan_ai(j) = makespan_ai(j) + hours(pr_ai{makeSpanName{j}, "Stop_time"} - pr_ai{makeSpanName{j-1}, "Start_Time"});
        makespan_trad(j) = makespan_trad(j) + hours(pr_trad{makeSpanName {j}, "Stop_time"} - pr_trad{makeSpanName{j-1}, "Start_Time"});
    end
    %
    % analysing the storage
    %
    for c = 1:length(products_with_label)
        st =  ai{k}.StorageStatus;
        previous = ai{aux}.StorageStatus;
        storage(c,i) = st{1, products_with_label(c)};
        if c >= 7 && i >= 2
            if st{1, "Cases"} == previous{1, "Cases"}
                if storage(c,i-1) < 30
                    storage(c,i) = storage(c,i-1) + 1;
                else
                    storage(c,i) = storage(c,i-1);
                end
            end
        end
    end
    aux = k;
end

for i = 1:length(mse_stoptime)
    mse_stoptime(i) = mse_stoptime(i) / 500;
    mae_stoptime(i) = mae_stoptime(i) / 500;
    mse_starttime(i) = mse_starttime(i) / 500;
    mae_starttime(i) = mae_starttime(i) / 500;
end

for i = 1:length(makespan_ai)
    makespan_ai(i) = makespan_ai(i)/500;
    makespan_trad(i) = makespan_trad(i)/500;
end

% plot the makespan for RL Method
hfig_1 = figure;
plot(makespan_ai)
title('Makespan of RL Method: Difference of time between stations for Scenario 1')
xlabel("Production Stations")
ylabel('Difference in hours')
xticklabels(makeSpandispName);
hFig_1.WindowState = 'maximized';

%plot the makespan for the Traditional Method
hfig_2 = figure;
plot(makespan_trad)
title('Makespan of Traditional Method: Difference of time between stations for Scenario 1')
xlabel("Production Stations")
ylabel('Difference in hours')
xticklabels(makeSpandispName);
hFig_2.WindowState = 'maximized';

% plot the MSE and MAE: Stop Time
hfig = figure;
t1 = tiledlayout(2,1);

ax1 = nexttile;
plot(mae_stoptime)
ylabel(ax1, 'MAE (hours)')
x_label_locations = [1:1:14];
ax = gca; % Get current axes being plotted to
ax.XTick = x_label_locations;
Ax.XTickLabel = dispName;
set(ax, 'XTickLabel', dispName);  % Definir os labels do eixo x

ax2 = nexttile;
plot(mse_stoptime)
ylabel(ax2, 'MSE (hours)')

title(t1, 'MAE & MSE: Error Analysis for the Stop time of Scenario 0')
xlabel(t1, "Production Stations")
ax5 = gca; % Get current axes being plotted to
ax5.XTick = x_label_locations;
ax5.XTickLabel = dispName;
set(ax5, 'XTickLabel', dispName);  % Definir os labels do eixo x
%xticklabels(ax2, dispName);
%xticklabels(ax1, dispName);
hFig.WindowState = 'maximized';

% plot the MSE and MAE: Start Time
hfig_5 = figure;
t2 = tiledlayout(2,1);

ax3 = nexttile;
plot(mae_starttime)
ylabel(ax3, 'MAE (hours)')
ax6 = gca; % Get current axes being plotted to
ax6.XTick = x_label_locations;
ax6.XTickLabel = dispName;
set(ax6, 'XTickLabel', dispName);  % Definir os labels do eixo x

ax4 = nexttile;
plot(mse_starttime)
ylabel(ax4, 'MSE (hours)')
ax7 = gca; % Get current axes being plotted to
ax7.XTick = x_label_locations;
ax7.XTickLabel = dispName;
set(ax7, 'XTickLabel', dispName);  % Definir os labels do eixo x

title(t2, 'MAE & MSE: Error Analysis for the Start time of Scenario 1')
xlabel(t2, "Production Stations")
xticklabels(ax3, dispName);
xticklabels(ax4, dispName);
hFig_5.WindowState = 'maximized';

% plot the Storage Analysis

hfig_4 = figure;
plot(storage(7,:), 'DisplayName', 'Product A')
hold on
plot(storage(8,:), 'DisplayName', 'Product B')
plot(storage(9,:), 'DisplayName', 'Product C')
plot(storage(10,:), 'DisplayName', 'Product D')
plot(storage(11,:), 'DisplayName', 'Product E')
plot(storage(12,:), 'DisplayName', 'Product F')
hold off

title('The Main Storage Evolution for products previous laser stamp: Scenario 1')
xlabel("Orders evolution")
ylabel('Products available in storage')
hFig_4.WindowState = 'maximized';

%
% analysing the computational effort
%
aiT1 = zeros(1,500);
aiT2 = zeros(1,500);
aiT3 = zeros(1,500);
tradT = zeros(1,500);
x = 0;
for i = 1:500
    time_ai = load(path+"\time\Time_"+i+format);
    aiT1(i) = x + minutes(time(time_ai.firstAI));
    if i == 1
        aiT2(i) = minutes(time(time_ai.secondAI));
        aiT3(i) = minutes(time(time_ai.simulationTime));
    else
        aiT2(i) = aiT2(i-1) + minutes(time(time_ai.secondAI));
        aiT3(i) = aiT3(i-1) + minutes(time(time_ai.simulationTime));
        if i == 50 || i == 100 || i == 150 || i == 200 || i == 250 || i == 300 || i == 350 || i == 400 || i == 450
            x = x + minutes(time(time_ai.firstAI));
        end

    end
    time_trad = load(path+"\time_trad\Time_"+i+format);
    tradT(i) = minutes(time(time_trad.totalTime));
end

% plot the Storage Analysis

hfig_5 = figure;
plot(aiT1, 'DisplayName', 'Prioritization Algorithm')
hold on
plot(aiT2, 'DisplayName', 'Petri Net Model Selection Algorithm')
plot(aiT3, 'DisplayName', 'Simulation + Fulfill Storage Algorithm')
plot(tradT, 'DisplayName', 'Traditional Method')
hold off

title('Computation Effort: How much time took to run the Algorithms (in minutes) ')
ylabel("Time Evolution (min)")
xlabel('Orders Evolution')
hFig_4.WindowState = 'maximized';

% display the total time
disp("The TM took " + tradT(end) + " min to run")
totalTime = aiT1(500) + aiT2(500) + aiT3(500);
disp("The RLM took " + totalTime + " min to run")
