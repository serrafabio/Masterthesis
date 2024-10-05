clc;clear; close all;
% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Traditional Method: Here it will simulate the Petri Nets
% Model. The idea is to simulate process per process, no inteligence will
% be processed.
%
% reading input data
%
TimesProcess = readtable('inputData_Times.csv');
TimesProcessAux = readtable('inputData_Times.csv');
Storages = readtable('inputData-Storages.csv');
StoragesAux = readtable('inputData-Storages.csv');
StorageStatus = readtable('inputData-StorageStatus.csv');
Supplier = readtable('inputData-Supplier.csv');
%
% declaring variables
%
finalProductStages =  {"Printer", "Montage","Electrical_Function_Verification", "Packaging"};
afterMainStorage = {"Commissioning", "Powder coating", "Oven 1"};
fromMontage = {"Montage", "Electrical Function Verification", "Packaging"};
noMainStorage = {"Milling 1", "Sawing", "Cleaning & Drying", "Verification"};
missingLaser = {"Laser", "Cleaning & Drying", "Verification"};
labels = {"_complete_", "_notLasered_"};
startWorkingDay = datetime(2024,07,15,8,0,0);
%closeWorkingDay = datetime(2024,07,15,17,0,0);
stopWorkingDay = datetime(2024,07,15,8,0,0);
VariableNames = ["Start_Time", "Stop_time", "Machine_Storage", "Production_Time", "Transport_Time"];
rowName = ["Milling 1", "Milling 2", "Sawing", "Cleaning & Drying", "Verification", "Laser", "Commissioning", "Powder coating", "Oven 1", "Oven 2", "Printer", "Montage" ,"Electrical_Function_Verification", "Packaging"];
pr = ["ProductA", "ProductB", "ProductC", "ProductD", "ProductE", "ProductF", "final_prod", "base", "electrical_func"];
insertPlusDay = 0;
cont = 1;
file_nr = 1;
%
% Simulating
%
productsOutput = {};
MachineStatus = {};
aux_MachineStatus = MachineStatus;
sumStartWorkingTime = false;
value2Sum = 0;
% start with the main storage scenario
d1 =  datetime("now");
for k = 1:height(StorageStatus)
    Orders = readtable('inputData-Orders.csv');
    for i = 1:height(Orders)
        d2 = datetime("now");
        % check  Product
        productsOutput = {};
        MachineStatus = {};
        usageOfOven = true;
        for j = 1:length(pr(1,1:6))
            % variable of Labels
            %if 25 <= Orders{i, "Orders"} <= 30
            %    b = Storages.TypeOfProduct == "Printer";
            %    Storages{b, "MaxStorage"}  = 10;
            %else
            %    b = Storages.TypeOfProduct == "Printer";
            %    Storages{b, "MaxStorage"} = StoragesAux{b, "MaxStorage"};
            %end
            if 10 <= Orders{i, "Orders"} <= 15
                a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == "Cleaning & Drying";
                TimesProcess{a, "P_T_Face1_min_"} = TimesProcessAux{a, "P_T_Face1_min_"} * 3;
            else
                a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == "Cleaning & Drying";
                TimesProcess{a, "P_T_Face1_min_"} = TimesProcessAux{a, "P_T_Face1_min_"};
            end
            %if 43 <= Orders{1, "Orders"} <= 47
            %    a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == "Milling 1";
            %    TimesProcess{a, "R_T__min_"} = TimesProcessAux{a, "R_T__min_"} * 3;
            %else
            %    a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == "Milling 1";
            %    TimesProcess{a, "R_T__min_"} = TimesProcessAux{a, "R_T__min_"};
            %end
            %
            while Orders{i,[pr(1,j)]} > 0
                % create output
                MachineStatusTime = array2table(zeros(14,5), "RowNames", rowName, "VariableNames", VariableNames);
                % add each table to a dict to separate each table per product
                productsOutput{end+1} = pr(1,j);
                if isempty(aux_MachineStatus)
                    % setting values in the row
                    MachineStatusTime.Start_Time = zeros(length(rowName),1) + startWorkingDay;
                    %MachineStatusTime.Close_Hour = zeros(length(rowName),1) + closeWorkingDay;
                    MachineStatusTime.Stop_time = zeros(length(rowName),1) + stopWorkingDay;
                    MachineStatusTime.Machine_Storage = zeros(length(rowName),1) - 1; 
                    % set the storage available for each product
                    MachineStatusTime("Sawing", "Machine_Storage") = array2table(StorageStatus{k, "Sawing"});
                    MachineStatusTime("Laser", "Machine_Storage") = array2table(StorageStatus{k, "Laser"});
                    MachineStatusTime("Printer", "Machine_Storage") = array2table(StorageStatus{k, "Printer"});
                    MachineStatusTime("Electrical_Function_Verification", "Machine_Storage") = array2table(StorageStatus{k, "Electrical_Function_Verification"});
                    MachineStatusTime("Montage", "Machine_Storage") = array2table(StorageStatus{k, "Montage"});
                else
                    % Getting the values from the first processed product
                    MachineStatusTime.Start_Time = aux_MachineStatus{end}.Stop_time;
                    %MachineStatusTime.Close_Hour = aux_MachineStatus{end}.Close_Hour;
                    MachineStatusTime.Stop_time = aux_MachineStatus{end}.Stop_time;
                    MachineStatusTime.Machine_Storage = aux_MachineStatus{end}.Machine_Storage;
                end
                %disp(MachineStatusTime)
                % add transport and production time to matrix
                for p = 1:length(rowName)
                    % get the production time and transportation time
                    if p <= 10
                        a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == rowName(p);
                    else
                        a = TimesProcess.Station == rowName(p); 
                    end
                    % actualize values 
                    MachineStatusTime(rowName(p), "Production_Time") = array2table(table2array(TimesProcess(a, "P_T_Face1_min_")) + table2array(TimesProcess(a, "P_T_Face2_min_")));
                    MachineStatusTime(rowName(p), "Transport_Time") = TimesProcess(a, "R_T__min_");
                end
                % if product must be complete
                if StorageStatus{k, pr(1,j)+labels(1,1)} < 1 && StorageStatus{k, pr(1,j)+labels(1,2)} < 1
                    % run simulating
                    for q = 1:length(noMainStorage)
                        % adjust if use milling 1 or 2
                        if q == 1
                            if ismember(pr(1,j), ["ProductD", "ProductE", "ProductF"]) 
                                noMainStorage{q} = "Milling 2";
                            else
                               noMainStorage{q} = "Milling 1"; 
                            end
                            MachineStatusTime{noMainStorage{q}, "Start_Time"} = MachineStatusTime{"Sawing", "Stop_time"};
                        end
                        % define start time
                        if q ~= 1
                            if MachineStatusTime{noMainStorage{q}, "Start_Time"} - MachineStatusTime{noMainStorage{q-1}, "Stop_time"} > hours(10)
                                MachineStatusTime{noMainStorage{q}, "Start_Time"} = table2array(MachineStatusTime(noMainStorage{q}, "Stop_time")) + seconds(60);
                            else
                                MachineStatusTime{noMainStorage{q}, "Start_Time"} = table2array(MachineStatusTime(noMainStorage{q-1}, "Stop_time")) + seconds(60);
                            end
                        end
                        % check if need to wait untill delivery
                        stopTime =  table2array(MachineStatusTime(noMainStorage{q}, "Start_Time")) + seconds(table2array(MachineStatusTime(noMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(noMainStorage{q},"Transport_Time")));
                        b =  TimesProcess.Station == noMainStorage{q} & TimesProcess.Product == pr(1,j);
                        if MachineStatusTime{noMainStorage{q}, "Machine_Storage"} < TimesProcess{b,"ConsumRawMaterial"} && MachineStatusTime{noMainStorage{q}, "Machine_Storage"} >= 0
                            % parms for datetime
                            tag = day(MachineStatusTime{noMainStorage{q}, "Start_Time"}) + day(3);
                            monat = month(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                            jahr = year(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                            % parms for the matrix
                            a = Supplier.Supplier == noMainStorage{q};
                            indice = find(MachineStatusTime.Row == noMainStorage{q});
                            % update the matrix
                            MachineStatusTime{noMainStorage{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                            stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(noMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(noMainStorage{q},"Transport_Time")));
                            % MachineStatusTime{indice:end, "Close_Hour"} = datetime(jahr,monat,tag,17,0,0) + days(table2array(Supplier(a, "TimeToDelivery_days_")));
                            % fulfill the storage
                            b = Storages.TypeOfProduct == noMainStorage{q};
                            MachineStatusTime{noMainStorage{q}, "Machine_Storage"} = Storages{b,"MaxStorage"};
                        end
                        % set stop time
                        MachineStatusTime{noMainStorage{q}, "Stop_time"} = stopTime;
                        b =  TimesProcess.Station == noMainStorage{q} & TimesProcess.Product == pr(1,j);
                        MachineStatusTime{noMainStorage{q}, "Machine_Storage"} = MachineStatusTime{noMainStorage{q}, "Machine_Storage"} - TimesProcess{b,"ConsumRawMaterial"};
                        % make sure to work in available time
                        %if MachineStatusTime{noMainStorage{q}, "Start_Time"} > MachineStatusTime{noMainStorage{q}, "Close_Hour"}
                        %    tag = day(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                        %    monat = month(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                        %    jahr = year(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                        %    startWorkingDay = startWorkingDay + days(1);
                        %    MachineStatusTime{noMainStorage{q}, "  _Hour"} = MachineStatusTime{noMainStorage{q}, "Close_Hour"} + days(1);
                        %    MachineStatusTime{noMainStorage{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0) + days(1);
                        %    MachineStatusTime{noMainStorage{q}, "Stop_time"} = datetime(jahr,monat,tag,8,0,0) + days(1) + seconds(table2array(MachineStatusTime(noMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(noMainStorage{q},"Transport_Time")));
                        %end
                    end
                    % increase product in the storage
                    StorageStatus{k, pr(1,j)+labels(1,2)} = StorageStatus{k, pr(1,j)+labels(1,2)} + 1;
                end
                % if product must be just laser
                if StorageStatus{k, pr(1,j)+labels(1,1)} < 1 && StorageStatus{k, pr(1,j)+labels(1,2)} >= 1
                    % run simulating
                    for q = 1:length(missingLaser)
                        % define start time
                        if q == 1
                            if MachineStatusTime{missingLaser{q}, "Start_Time"} < MachineStatusTime{noMainStorage{end}, "Stop_time"}
                                MachineStatusTime{missingLaser{q}, "Start_Time"} = MachineStatusTime{noMainStorage{end}, "Stop_time"} + seconds(60);
                            else
                                MachineStatusTime{missingLaser{q}, "Start_Time"} = MachineStatusTime{missingLaser{q}, "Start_Time"} + seconds(60);
                            end
                        else
                            MachineStatusTime{missingLaser{q}, "Start_Time"} = table2array(MachineStatusTime(missingLaser{q-1}, "Stop_time")) + seconds(60);
                        end
                        % check if need to wait untill delivery
                        stopTime =  table2array(MachineStatusTime(missingLaser{q}, "Start_Time")) + seconds(table2array(MachineStatusTime(missingLaser{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(missingLaser{q},"Transport_Time")));
                        b =  TimesProcess.Station == missingLaser{q} & TimesProcess.Product == pr(1,j);
                        if MachineStatusTime{missingLaser{q}, "Machine_Storage"} < TimesProcess{b,"ConsumRawMaterial"} && MachineStatusTime{missingLaser{q}, "Machine_Storage"} >= 0
                            % parms for datetime
                            tag = day(MachineStatusTime{missingLaser{q}, "Start_Time"}) + day(1);
                            monat = month(MachineStatusTime{missingLaser{q}, "Start_Time"});
                            jahr = year(MachineStatusTime{missingLaser{q}, "Start_Time"});
                            % parms for the matrix
                            a = Supplier.Supplier == missingLaser{q};
                            indice = find(MachineStatusTime.Row == missingLaser{q});
                            % updating the matrix
                            MachineStatusTime{missingLaser{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                            stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(missingLaser{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(missingLaser{q},"Transport_Time")));
                            % MachineStatusTime{indice:end, "Close_Hour"} = datetime(jahr,monat,tag,17,0,0) + days(table2array(Supplier(a, "TimeToDelivery_days_")));
                            % fulfill the storage
                            b = Storages.TypeOfProduct == missingLaser{q};
                            MachineStatusTime{missingLaser{q}, "Machine_Storage"} = Storages{b,"MaxStorage"};
                        end
                        % set stop time
                        MachineStatusTime{missingLaser{q}, "Stop_time"} = stopTime;
                        b =  TimesProcess.Station == missingLaser{q} & TimesProcess.Product == pr(1,j);
                        MachineStatusTime{missingLaser{q}, "Machine_Storage"} = MachineStatusTime{missingLaser{q}, "Machine_Storage"} - TimesProcess{b,"ConsumRawMaterial"};
                        % make sure to work in available time
                        %if MachineStatusTime{missingLaser{q}, "Start_Time"} > MachineStatusTime{missingLaser{q}, "Close_Hour"}
                        %    tag = day(MachineStatusTime{missingLaser{q}, "Start_Time"});
                        %    monat = month(MachineStatusTime{missingLaser{q}, "Start_Time"});
                        %    jahr = year(MachineStatusTime{missingLaser{q}, "Start_Time"});
                        %    startWorkingDay = startWorkingDay + days(1);
                        %    MachineStatusTime{missingLaser{q}, "Close_Hour"} = MachineStatusTime{missingLaser{q}, "Close_Hour"} + days(1);
                        %    MachineStatusTime{missingLaser{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0) + days(1);
                        %    MachineStatusTime{missingLaser{q}, "Stop_time"} = datetime(jahr,monat,tag,8,0,0) + days(1) + seconds(table2array(MachineStatusTime(missingLaser{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(missingLaser{q},"Transport_Time")));
                        %end
                    end
                    % increase product in the storage
                    StorageStatus{k, pr(1,j)+labels(1,1)} = StorageStatus{k, pr(1,j)+labels(1,1)} + 1;
                    StorageStatus{k, pr(1,j)+labels(1,2)} = StorageStatus{k, pr(1,j)+labels(1,2)} - 1;
                end

                % if product available is in Main Storage
                if StorageStatus{k, pr(1,j)+labels(1,1)} >= 1
                    % run simulating
                    for q = 1:length(afterMainStorage)
                        % paralelize the oven process
                        if usageOfOven == true && (afterMainStorage{q} == "Oven 2" || afterMainStorage{q} == "Oven 1")
                            afterMainStorage{q} = "Oven 1";
                            usageOfOven = false;
                        elseif usageOfOven == false && (afterMainStorage{q} == "Oven 2" || afterMainStorage{q} == "Oven 1")
                            afterMainStorage{q} = "Oven 2";
                            usageOfOven = true;
                        end
                        % define start time
                        if q == 1
                            if MachineStatusTime{afterMainStorage{q}, "Start_Time"} < MachineStatusTime{missingLaser{end}, "Stop_time"}
                                MachineStatusTime{afterMainStorage{q}, "Start_Time"} = MachineStatusTime{missingLaser{end}, "Stop_time"} + seconds(60);
                            else
                                MachineStatusTime{afterMainStorage{q}, "Start_Time"} = MachineStatusTime{afterMainStorage{q}, "Start_Time"} + seconds(60);
                            end
                        else
                            MachineStatusTime{afterMainStorage{q}, "Start_Time"} = table2array(MachineStatusTime(afterMainStorage{q-1}, "Stop_time")) + seconds(60);
                        end
                        % check if need to wait untill delivery
                        stopTime =  table2array(MachineStatusTime(afterMainStorage{q}, "Start_Time")) + seconds(table2array(MachineStatusTime(afterMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(afterMainStorage{q},"Transport_Time")));
                        b =  TimesProcess.Station == afterMainStorage{q} & TimesProcess.Product == pr(1,j);
                        if MachineStatusTime{afterMainStorage{q}, "Machine_Storage"} < TimesProcess{b,"ConsumRawMaterial"} && MachineStatusTime{afterMainStorage{q}, "Machine_Storage"} >= 0
                            % parms for datetime
                            tag = day(MachineStatusTime{afterMainStorage{q}, "Start_Time"});
                            monat = month(MachineStatusTime{afterMainStorage{q}, "Start_Time"});
                            jahr = year(MachineStatusTime{afterMainStorage{q}, "Start_Time"});
                            % parms for the matrix
                            a = Supplier.Supplier == afterMainStorage{q};
                            indice = find(MachineStatusTime.Row == afterMainStorage{q});
                            % updating the matrix
                            MachineStatusTime{afterMainStorage{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                            stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(afterMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(afterMainStorage{q},"Transport_Time")));
                            % MachineStatusTime{indice:end, "Close_Hour"} = datetime(jahr,monat,tag,17,0,0) + days(table2array(Supplier(a, "TimeToDelivery_days_")));
                            % fulfill the storage
                            b = Storages.TypeOfProduct == afterMainStorage{q};
                            MachineStatusTime{afterMainStorage{q}, "Machine_Storage"} = Storages{b,"MaxStorage"};
                        end
                        % set stop time
                        MachineStatusTime{afterMainStorage{q}, "Stop_time"} = stopTime;
                        b =  TimesProcess.Station == afterMainStorage{q} & TimesProcess.Product == pr(1,j);
                        MachineStatusTime{afterMainStorage{q}, "Machine_Storage"} = MachineStatusTime{afterMainStorage{q}, "Machine_Storage"} - TimesProcess{b,"ConsumRawMaterial"};
                        % make sure to work in available time
                        %if MachineStatusTime{afterMainStorage{q}, "Start_Time"} > MachineStatusTime{afterMainStorage{q}, "Close_Hour"}
                        %    tag = day(MachineStatusTime{afterMainStorage{q}, "Start_Time"});
                        %    monat = month(MachineStatusTime{afterMainStorage{q}, "Start_Time"});
                        %    jahr = year(MachineStatusTime{afterMainStorage{q}, "Start_Time"});
                        %    startWorkingDay = startWorkingDay + days(1);
                        %    MachineStatusTime{afterMainStorage{q}, "Close_Hour"} = MachineStatusTime{afterMainStorage{q}, "Close_Hour"} + days(1);
                        %    MachineStatusTime{afterMainStorage{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0) + days(1);
                        %    MachineStatusTime{afterMainStorage{q}, "Stop_time"} = datetime(jahr,monat,tag,8,0,0)  + days(1) + seconds(table2array(MachineStatusTime(afterMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(afterMainStorage{q},"Transport_Time")));
                        %end
                    end
                    % increase product in the storage
                    StorageStatus{k, pr(1,j)+labels(1,1)} = StorageStatus{k, pr(1,j)+labels(1,1)} - 1;
                end
                % make sure to not repeat over the same order
                Orders{i,[pr(1,j)]} = Orders{i,[pr(1,j)]} - 1;
                MachineStatus{end+1} = MachineStatusTime;
                %disp(MachineStatusTime)
                aux_MachineStatus = MachineStatus;
            end
        end
        % actualize  the last  machines
        % here we will consider the final product, as the time which is
        % equal for all products, therefore it is the final_product
        % define start time
        for q = 1:length(finalProductStages)
            for w = 1:length(MachineStatus)
                if MachineStatus{w}.Machine_Storage("Montage") >= 1 && finalProductStages{q} == "Printer"
                    % just pass
                else
                    if q ~= 1
                        if MachineStatus{w}.Machine_Storage("Montage") >= 1 && finalProductStages{q} == "Montage"
                            MachineStatus{w}.Start_Time(finalProductStages{q}) = MachineStatus{end}.Stop_time("Oven 2") + seconds(60);
                        else
                            MachineStatus{w}.Start_Time(finalProductStages{q}) = MachineStatus{w}.Stop_time(finalProductStages{q-1}) + seconds(60);
                        end
                    else
                        MachineStatus{w}.Start_Time(finalProductStages{q}) = MachineStatus{end}.Stop_time("Oven 2") + seconds(60);
                    end
                    % check if need to wait untill delivery
                    stopTime =  MachineStatus{w}.Start_Time(finalProductStages{q}) + seconds(MachineStatus{w}.Production_Time(finalProductStages{q}))+ seconds(MachineStatus{w}.Transport_Time(finalProductStages{q}));
                    b =  TimesProcess.Station == finalProductStages{q};
                    if MachineStatus{w}.Machine_Storage(finalProductStages{q}) < TimesProcess{b,"ConsumRawMaterial"} && MachineStatus{w}.Machine_Storage(finalProductStages{q}) >= 0
                        % parms for datetime
                        tag = day(MachineStatus{w}.Start_Time(finalProductStages{q})) + day(2);
                        monat = month(MachineStatus{w}.Start_Time(finalProductStages{q}));
                        jahr = year(MachineStatus{w}.Start_Time(finalProductStages{q}));
                        % parms for matrix
                        a = Supplier.Supplier == finalProductStages{q};
                        indice = find(MachineStatusTime.Row == finalProductStages{q});
                        % ajust matrix
                        MachineStatus{w}.Start_Time(finalProductStages{q}) = datetime(jahr,monat,tag,8,0,0);
                        % MachineStatus{w}.Close_Hour(indice:end) = datetime(jahr,monat,tag,17,0,0) + days(table2array(Supplier(a, "TimeToDelivery_days_")));
                        stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(MachineStatus{w}.Production_Time(finalProductStages{q})) + seconds(MachineStatus{w}.Transport_Time(finalProductStages{q}));
                        % fulfill the storage
                        b = Storages.TypeOfProduct == finalProductStages{q};
                        MachineStatus{w}.Machine_Storage(finalProductStages{q}) = Storages{b,"MaxStorage"};
                    end
                    % set stop time
                    MachineStatus{w}.Stop_time(finalProductStages{q}) = stopTime;
                    b =  TimesProcess.Station == finalProductStages{q};
                    MachineStatus{w}.Machine_Storage(finalProductStages{q}) = MachineStatus{w}.Machine_Storage(finalProductStages{q}) - TimesProcess{b,"ConsumRawMaterial"};
                    if finalProductStages{q} == "Printer"
                        MachineStatus{w}.Machine_Storage("Montage") = MachineStatus{w}.Machine_Storage("Montage") + 1;
                    end
                    if finalProductStages{q} == "Montage"
                        MachineStatus{w}.Machine_Storage("Montage") = MachineStatus{w}.Machine_Storage("Montage") - 1;
                    end
                    % make sure to work in available time
                    %if MachineStatus{w}.Start_Time(finalProductStages{q}) > MachineStatus{w}.Close_Hour(finalProductStages{q})
                    %    tag = day(MachineStatus{w}.Start_Time(finalProductStages{q}));
                    %    monat = month(MachineStatus{w}.Start_Time(finalProductStages{q}));
                    %    jahr = year(MachineStatus{w}.Start_Time(finalProductStages{q}));
                    %    indice = find(MachineStatusTime.Row == finalProductStages{q});
                    %    MachineStatus{w}.Close_Hour(finalProductStages{q}) = datetime(jahr,monat,tag,17,0,0) + days(1);
                    %    MachineStatus{w}.Start_Time(finalProductStages{q}) = datetime(jahr,monat,tag,8,0,0) + days(1);
                    %    MachineStatus{w}.Stop_time(finalProductStages{q}) = datetime(jahr,monat,tag,8,0,0) + days(1) + seconds(MachineStatus{w}.Production_Time(finalProductStages{q})) + seconds(MachineStatus{w}.Transport_Time(finalProductStages{q}));
                    %    if q == length(finalProductStages) && w == length(MachineStatus)
                    %        %startWorkingDay = startWorkingDay + days(1);
                    %    end
                    %end
                end
            end
        end
        for w = 1:length(MachineStatus)
            disp(productsOutput{w})
            disp(MachineStatus{w})
        end
        storage_status_nr = StorageStatus{k, "Cases"};
        Order_nr = Orders{i,"Orders"};
        save("traditional/TM_"+file_nr, "MachineStatus", "storage_status_nr", "Order_nr");
        file_nr = file_nr + 1;
        aux_MachineStatus = MachineStatus;
        d3 = datetime("now");
        totalTime = between(d1,d3);
        timePerOrder = between(d2,d3);
        save("time_trad/Time_"+cont, "totalTime","timePerOrder" );
        cont = cont + 1;
    end
end


