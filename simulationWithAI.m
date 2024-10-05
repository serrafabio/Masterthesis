% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Simulation process using AI applied previosly to organize
% the data as input to here.
%
function [output, ss] = simulationWithAI(Orders, stage, StorageStatus, output, file_nr)
    %
    % reading input data
    %
    TimesProcess = readtable('inputData_Times.csv');
    Storages = readtable('inputData-Storages.csv');
    Supplier = readtable('inputData-Supplier.csv');
    %
    % declaring variables
    %
    finalProductStages =  {"Printer", "Montage","Electrical_Function_Verification", "Packaging"};
    afterMainStorage = {"Commissioning", "Powder coating", "Oven 1"};
    fromMontage = {"Montage", "Electrical Function Verification", "Packaging"};
    noMainStorage = {"Milling 1", "Sawing", "Cleaning & Drying", "Verification"};
    missingLaser = {"Laser", "Cleaning & Drying", "Verification"};
    needStorage = {"Laser", "Electrical_Function_Verification", "Printer", "Sawing"};
    labels = {"_complete_", "_notLasered_"};
    startWorkingDay = datetime(2024,07,15,8,0,0);
    closeWorkingDay = datetime(2024,07,15,17,0,0);
    stopWorkingDay = datetime(2024,07,15,8,0,0);
    VariableNames = ["Start_Time", "Stop_time", "Production_Time", "Transport_Time"];
    rowName = ["Milling 1", "Milling 2", "Sawing", "Cleaning & Drying", "Verification", "Laser", "Commissioning", "Powder coating", "Oven 1", "Oven 2", "Printer", "Montage" ,"Electrical_Function_Verification", "Packaging"];
    pr = ["ProductA", "ProductB", "ProductC", "ProductD", "ProductE", "ProductF", "final_prod", "base", "electrical_func"];
    insertPlusDay = 0;
    %
    % Simulation
    %
    productsOutput = {};
    MachineStatus = {};
    sumStartWorkingTime = false;
    value2Sum = 0;
    % variable of Labels
    % check  Product
    productsOutput = {};
    MachineStatus = {};
    usageOfOven = true;
    for j = 1:length(pr(1,1:6))
        % resilience Scenario adjustment
        %if 25 < Orders{1, "Orders"} < 30
        %    b = Storages.TypeOfProduct == "Printer";
        %    Storages{b, "MaxStorage"}  = 10;
        %end
        %if 10 <= Orders{1, "Orders"} <= 15
        %    a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == "Cleaning & Drying";
        %    TimesProcess{a, "P_T_Face1_min_"} = TimesProcess{a, "P_T_Face1_min_"} * 3;
        %end
        if 43 <= Orders{1, "Orders"} <= 47
            a = TimesProcess.Product == pr(1,j) & TimesProcess.Station == "Milling 1";
            TimesProcess{a, "R_T__min_"} = TimesProcess{a, "R_T__min_"} * 3;
        end
        while Orders{1,[pr(1,j)]} > 0
            % create output
            MachineStatusTime = array2table(zeros(14,4), "RowNames", rowName, "VariableNames", VariableNames);
            % add each table to a dict to separate each table per product
            productsOutput{end+1} = pr(1,j);
            if isempty(output)
                % setting values in the row
                MachineStatusTime.Start_Time = zeros(length(rowName),1) + startWorkingDay;
                %MachineStatusTime.Close_Hour = zeros(length(rowName),1) + closeWorkingDay;
                MachineStatusTime.Stop_time = zeros(length(rowName),1) + stopWorkingDay;
                %MachineStatusTime.Machine_Storage = zeros(length(rowName),1) - 1; 
                % set the storage available for each product
                MachineStatusTime("Sawing", "Machine_Storage") = array2table(StorageStatus{1, "Sawing"});
                MachineStatusTime("Laser", "Machine_Storage") = array2table(StorageStatus{1, "Laser"});
                %MachineStatusTime("Printer", "Machine_Storage") = array2table(StorageStatus{1, "Printer"});
                MachineStatusTime("Electrical_Function_Verification", "Machine_Storage") = array2table(StorageStatus{1, "Electrical_Function_Verification"});
                MachineStatusTime("Montage", "Machine_Storage") = array2table(StorageStatus{1, "Montage"});
            else
                % Getting the values from the first processed product
                MachineStatusTime.Start_Time = output{end}.Stop_time;
                %MachineStatusTime.Close_Hour = output{end}.Close_Hour;
                MachineStatusTime.Stop_time = output{end}.Stop_time;
                MachineStatusTime.Machine_Storage = output{end}.Machine_Storage;
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
            if stage(j) == 2
                % run simulating
                for q = 1:length(noMainStorage)
                    % adjust if use milling 1 or 2
                    if q == 1
                        if ismember(pr(1,j), ["ProductD", "ProductE", "ProductF"]) 
                            noMainStorage{q} = "Milling 2";
                        else
                           noMainStorage{q} = "Milling 1"; 
                        end
                        %MachineStatusTime{noMainStorage{q}, "Start_Time"} = MachineStatusTime{noMainStorage{end}, "Stop_time"};
                    end
                    % define start time
                    if q ~= 1
                        MachineStatusTime{noMainStorage{q}, "Start_Time"} = table2array(MachineStatusTime(noMainStorage{q-1}, "Stop_time")) + seconds(60);
                    end
                    % check if need to wait untill delivery
                    stopTime =  table2array(MachineStatusTime(noMainStorage{q}, "Start_Time")) + seconds(table2array(MachineStatusTime(noMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(noMainStorage{q},"Transport_Time")));
                    b =  TimesProcess.Station == noMainStorage{q} & TimesProcess.Product == pr(1,j);
                    if noMainStorage{q} == "Sawing"
                        % parms for datetime
                        tag = day(MachineStatusTime{noMainStorage{q}, "Start_Time"}) + day(3);
                        monat = month(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                        jahr = year(MachineStatusTime{noMainStorage{q}, "Start_Time"});
                        StorageStatus{1, "Sawing"} = StorageStatus{1, "Sawing"} - 1;
                        if StorageStatus{1, "Sawing"} < 2
                            % update the matrix
                            MachineStatusTime{noMainStorage{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                            stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(noMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(noMainStorage{q},"Transport_Time")));
                            % fulfill the storage
                            StorageStatus{1, "Sawing"} = 30;
                        else
                            decision = StorageDecisionFunction(StorageStatus, noMainStorage{q}, Orders{1, "Orders"});
                            [maxValues, indices] = max(decision(1,:));
                            if indices ~= 1
                                % update the matrix
                                MachineStatusTime{noMainStorage{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                                stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(noMainStorage{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(noMainStorage{q},"Transport_Time")));
                                % fulfill the storage
                                StorageStatus{1, "Sawing"} = 30;
                            end
                        end
                    end
                    % set stop time
                    MachineStatusTime{noMainStorage{q}, "Stop_time"} = stopTime;
                end
                % increase product in the storage
                StorageStatus{1, pr(1,j)+labels(1,2)} = StorageStatus{1, pr(1,j)+labels(1,2)} + 1;
            end
            % if product must be just laser
            if stage(j) == 2 || stage(j) == 3
                % run simulating
                for q = 1:length(missingLaser)
                    % define start time
                    if q == 1
                        if MachineStatusTime{missingLaser{q}, "Start_Time"} < MachineStatusTime{noMainStorage{end}, "Stop_time"}
                            MachineStatusTime{missingLaser{q}, "Start_Time"} = MachineStatusTime{noMainStorage{end}, "Stop_time"} + seconds(60);
                        else
                            MachineStatusTime{missingLaser{q}, "Start_Time"} = MachineStatusTime{missingLaser{q}, "Start_Time"} + seconds(60);
                        end
                        %MachineStatusTime{"Laser", "Start_Time"} = MachineStatusTime{missingLaser{end}, "Stop_time"};
                    else
                        MachineStatusTime{missingLaser{q}, "Start_Time"} = table2array(MachineStatusTime(missingLaser{q-1}, "Stop_time")) + seconds(60);
                    end
                    % check if need to wait untill delivery
                    stopTime =  table2array(MachineStatusTime(missingLaser{q}, "Start_Time")) + seconds(table2array(MachineStatusTime(missingLaser{q},"Production_Time"))) + seconds(table2array(MachineStatusTime(missingLaser{q},"Transport_Time")));
                    b =  TimesProcess.Station == missingLaser{q} & TimesProcess.Product == pr(1,j);
                    if missingLaser{q} == "Laser"
                        % parms for datetime
                        tag = day(MachineStatusTime{missingLaser{q}, "Start_Time"})+ day(1);
                        monat = month(MachineStatusTime{missingLaser{q}, "Start_Time"});
                        jahr = year(MachineStatusTime{missingLaser{q}, "Start_Time"});
                        StorageStatus{1,"Laser"} = StorageStatus{1,"Laser"} - 1;
                        if StorageStatus{1,"Laser"} < 2
                            % parms for the matrix
                            a = Supplier.Supplier == missingLaser{q};
                            indice = find(MachineStatusTime.Row == missingLaser{q})
                            % updating the matrix
                            MachineStatusTime{missingLaser{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                            stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(missingLaser{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(missingLaser{q},"Transport_Time")));
                            % fulfill the storage
                            StorageStatus{1,"Laser"} = 30;
                        else
                            decision = StorageDecisionFunction(StorageStatus, missingLaser{q}, Orders{1, "Orders"});
                            [maxValues, indices] = max(decision(1,:));
                            if indices ~= 1
                                % parms for the matrix
                                a = Supplier.Supplier == missingLaser{q};
                                indice = find(MachineStatusTime.Row == missingLaser{q});
                                % updating the matrix
                                MachineStatusTime{missingLaser{q}, "Start_Time"} = datetime(jahr,monat,tag,8,0,0);
                                stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(table2array(MachineStatusTime(missingLaser{q},"Production_Time")))+ seconds(table2array(MachineStatusTime(missingLaser{q},"Transport_Time")));
                                % fulfill the storage
                                StorageStatus{1,"Laser"} = 30;
                            end
                        end
                    end
                    % set stop time
                    MachineStatusTime{missingLaser{q}, "Stop_time"} = stopTime;
                end
                % increase product in the storage
                StorageStatus{1, pr(1,j)+labels(1,1)} = StorageStatus{1, pr(1,j)+labels(1,1)} + 1;
                StorageStatus{1, pr(1,j)+labels(1,2)} = StorageStatus{1, pr(1,j)+labels(1,2)} - 1;
            end
            fullfilStorage = 0;
            % if product available is in Main Storage
            if stage(j) == 2 || stage(j) == 3 || stage(j) == 4
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
                    % set stop time
                    stopTime =  table2array(MachineStatusTime(afterMainStorage{q}, "Start_Time")) + seconds(table2array(MachineStatusTime(afterMainStorage{q},"Production_Time"))) + seconds(table2array(MachineStatusTime(afterMainStorage{q},"Transport_Time")));
                    MachineStatusTime{afterMainStorage{q}, "Stop_time"} = stopTime;
                end
                % increase product in the storage
                StorageStatus{1, pr(1,j)+labels(1,1)} = StorageStatus{1, pr(1,j)+labels(1,1)} - 1;
            end
            % make sure to not repeat over the same order
            Orders{1,[pr(1,j)]} = Orders{1,[pr(1,j)]} - 1;
            MachineStatus{end+1} = MachineStatusTime;
            output = MachineStatus;
        end
    end
    % actualize  the last  machines
    % here we will consider the final product, as the time which is
    % equal for all products, therefore it is the final_product
    % define start time
    for q = 1:length(finalProductStages)
        if MachineStatus{1}.Machine_Storage("Montage") >= 1 && finalProductStages{q} == "Printer"
            % just pass
        else
            if q ~= 1
                if MachineStatus{1}.Machine_Storage("Montage") >= 1 && finalProductStages{q} == "Montage"
                    MachineStatus{1}.Start_Time(finalProductStages{q}) = MachineStatus{end}.Stop_time("Oven 2") + seconds(60);
                else
                    MachineStatus{1}.Start_Time(finalProductStages{q}) = MachineStatus{1}.Stop_time(finalProductStages{q-1}) + seconds(60);
                end
            else
                MachineStatus{1}.Start_Time(finalProductStages{q}) = MachineStatus{end}.Stop_time("Oven 2") + seconds(60);
            end
            % check if need to wait untill 
            stopTime =  MachineStatus{1}.Start_Time(finalProductStages{q}) + seconds(MachineStatus{1}.Production_Time(finalProductStages{q}))+ seconds(MachineStatus{1}.Transport_Time(finalProductStages{q}));
            b =  TimesProcess.Station == finalProductStages{q};
            if finalProductStages{q} == "Printer" || finalProductStages{q} == "Electrical_Function_Verification"
                % parms for datetime
                tag = day(MachineStatus{1}.Start_Time(finalProductStages{q})) + day(2);
                monat = month(MachineStatus{1}.Start_Time(finalProductStages{q}));
                jahr = year(MachineStatus{1}.Start_Time(finalProductStages{q}));
                StorageStatus{1, finalProductStages{q}} = StorageStatus{1, finalProductStages{q}} - 1;
                if StorageStatus{1, finalProductStages{q}} < 2
                    % ajust matrix
                    MachineStatus{1}.Start_Time(finalProductStages{q}) = datetime(jahr,monat,tag,8,0,0);
                    stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(MachineStatus{1}.Production_Time(finalProductStages{q})) + seconds(MachineStatus{1}.Transport_Time(finalProductStages{q}));
                    % fulfill the storage
                    StorageStatus{1, finalProductStages{q}}  = 30;
                else
                    decision = StorageDecisionFunction(StorageStatus, finalProductStages{q}, Orders{1, "Orders"});
                    [maxValues, indices] = max(decision(1,:));
                    if indices ~= 1
                        % ajust matrix
                        MachineStatus{1}.Start_Time(finalProductStages{q}) = datetime(jahr,monat,tag,8,0,0);
                        stopTime =  datetime(jahr,monat,tag,8,0,0) + seconds(MachineStatus{1}.Production_Time(finalProductStages{q})) + seconds(MachineStatus{1}.Transport_Time(finalProductStages{q}));
                        % fulfill the storage
                        StorageStatus{1, finalProductStages{q}}  = 30;
                    end
                end
            end
            % set stop time
            MachineStatus{1}.Stop_time(finalProductStages{q}) = stopTime;
        end
    end
    for w = 2:length(MachineStatus)
        % copiar o 1 para o resto
        for q = 1:length(finalProductStages)
            MachineStatus{w}.Start_Time(finalProductStages{q}) = MachineStatus{1}.Start_Time(finalProductStages{q});
            MachineStatus{w}.Stop_time(finalProductStages{q}) = MachineStatus{1}.Stop_time(finalProductStages{q});
        end
    end
    for w = 1:length(MachineStatus)
        disp(productsOutput{w})
        disp(MachineStatus{w})
    end
    % save the output
    storage_status_nr = StorageStatus{1, "Cases"};
    Order_nr = Orders{1,"Orders"};
    save("results/AI_"+file_nr, "MachineStatus", "storage_status_nr", "Order_nr", "StorageStatus")
    output = MachineStatus;
    ss = StorageStatus;
end