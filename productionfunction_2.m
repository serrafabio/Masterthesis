% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Here we create a function which reaturn the production
% function given a product
%
function f = productionfunction_2(pr, Storagestatus, qt, order_nr)
    % declaring variables
    stage1 = {"Commissioning", "Powder coating", "Oven 1", "Oven 2"};
    stage2 = {"Laser", "Cleaning & Drying", "Verification"};
    stage3 = {"Milling 1", "Milling 2", "Sawing", "Cleaning & Drying", "Verification"};
    products = {"ProductA";"ProductB";"ProductC";"ProductD";"ProductE";"ProductF"};
    E_sum = 0; Pr_sum = 0; Tr_sum = 0;
    % reading input data required
    TimesProcess = readtable('inputData_Times.csv');
    Storages = readtable('inputData-Storages.csv');
    % resilience Scenario adjustment
    %if 25 <= order_nr <= 30
    %    b = Storages.TypeOfProduct == "Printer";
    %    Storages{b, "MaxStorage"}  = 10;
    %end
    %if 10 <= order_nr <= 15
    %    a = TimesProcess.Product == pr & TimesProcess.Station == "Cleaning & Drying";
    %    TimesProcess{a, "P_T_Face1_min_"} = TimesProcess{a, "P_T_Face1_min_"} * 3;
    %end
    if 43 <= order_nr <= 47
        a = TimesProcess.Product == pr & TimesProcess.Station == "Milling 1";
        TimesProcess{a, "R_T__min_"} = TimesProcess{a, "R_T__min_"} * 3;
    end
    % define the sum value of production time and transport time
    for j = 1:length(products)
        for i = 1:length(stage1)
            a = TimesProcess.Product == products{j} & TimesProcess.Station == stage1{i};
            Pr_sum = Pr_sum + TimesProcess{a, "P_T_Face1_min_"} + TimesProcess{a, "P_T_Face2_min_"};
            Tr_sum = Tr_sum + TimesProcess{a, "R_T__min_"};
        end
        for i = 1:length(stage2)
            a = TimesProcess.Product == products{j} & TimesProcess.Station == stage2{i};
            Pr_sum = Pr_sum + TimesProcess{a, "P_T_Face1_min_"} + TimesProcess{a, "P_T_Face2_min_"};
            Tr_sum = Tr_sum + TimesProcess{a, "R_T__min_"};
        end
        for i = 1:length(stage3)
            a = TimesProcess.Product == products{j} & TimesProcess.Station == stage3{i};
            Pr_sum = Pr_sum + TimesProcess{a, "P_T_Face1_min_"} + TimesProcess{a, "P_T_Face2_min_"};
            Tr_sum = Tr_sum + TimesProcess{a, "R_T__min_"};
        end
    end
    % define the sum value for the storage
    b = Storages.TypeOfProduct == pr+"_complete_";
    E_sum = E_sum + Storages{b, "MaxStorage"};
    b = Storages.TypeOfProduct == pr+"_notLasered_";
    E_sum = E_sum + Storages{b, "MaxStorage"};
    % now calculate the stage status
    % stage = 1: Only the main storage stage
    % stage = 2: Laser and main storage stages
    % stage = 3: All the stages
    Pr_status = 0; Tr_status = 0;
    for i =  1:length(stage1)
        a = TimesProcess.Product == pr & TimesProcess.Station == stage1{i};
        Pr_status = Pr_status + TimesProcess{a, "P_T_Face1_min_"} + TimesProcess{a, "P_T_Face2_min_"};
        Tr_status = Tr_status + TimesProcess{a, "R_T__min_"};
    end
    E_status = Storagestatus{1, pr+"_complete_"} - qt;
    E_status = E_status + Storagestatus{1, pr+"_notLasered_"};
    for i =  1:length(stage2)
        a = TimesProcess.Product == pr & TimesProcess.Station == stage2{i};
        Pr_status = Pr_status + TimesProcess{a, "P_T_Face1_min_"} + TimesProcess{a, "P_T_Face2_min_"};
        Tr_status = Tr_status + TimesProcess{a, "R_T__min_"};
    end
    for i =  1:length(stage3)
        a = TimesProcess.Product == pr & TimesProcess.Station == stage3{i};
        Pr_status = Pr_status + TimesProcess{a, "P_T_Face1_min_"} + TimesProcess{a, "P_T_Face2_min_"};
        Tr_status = Tr_status + TimesProcess{a, "R_T__min_"};
    end
    
    % adjust according the quantity of product to use
    if qt == 0
        factor = 2;
    else
        factor = 1/qt;
    end

    % return
    f = (Pr_status/Pr_sum) + (Tr_status/Tr_sum) + (E_status/E_sum);
end
