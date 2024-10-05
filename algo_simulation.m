clc;clear; close all; warning('off');
% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Model with application of AI to simulate the production process  
%
% reading input data
%
Storages = readtable('inputData-Storages.csv');
StorageStatus = readtable('inputData-StorageStatus.csv');
Supplier = readtable('inputData-Supplier.csv');
%
% declaring variables
%
pr = ["ProductA", "ProductB", "ProductC", "ProductD", "ProductE", "ProductF"];
%
% Simulating
%
productsOutput = {};
MachineStatus = {};
output = {};
sumStartWorkingTime = false;
value2Sum = 0;
cont = 1;
file_nr = 1;

% start with the main storage scenario
for k = 1:height(StorageStatus)
    Orders = readtable('inputData-Orders.csv');
    aux = Orders;
    d1 =  datetime("now");
    % then we need to get one order and see each product where to start
    for i = 1:4:height(Orders)
        % organizing the order list using the AI solution
        final = i + 3;
        if final <= height(Orders)
            prior = prioritization(StorageStatus(k, :), Orders(i:final, :));
            rowIndices = zeros(1, height(prior));
            for k_2 = 1:1:length(rowIndices)
                [maxValues, indices] = max(prior);
                rowIndices(k_2) = indices(k_2);
                prior(indices(k_2), :) = -100*ones(1, width(prior));
            end
            for j  = 1:length(rowIndices)
                aux(i+rowIndices(j)-1,:) = Orders(i+j-1,:);
            end
        end
    end
    d2 = datetime("now");
    for i = 1:height(aux)
        d3 = datetime("now");
        product_order = zeros(1, 6);
        for j = 1:length(pr)
            if aux{i, pr(j)} > 0
                qtable = decideStage(StorageStatus(k, :), pr(j), aux{i, pr(j)}, aux{i, "Orders"});
                result = qtable{1};
                [maxValues, indices] = max(result(1,:));
                product_order(j) = indices;
                % cases to manufacture:
                % case 1: indices == 0 or 1: not manufacture
                % case 2: indices == 2: manufacture from beginning
                % case 3: indices == 3: go to laser to be stamped
                % case 4: indices == 4: go directly to assembly phase
            end
        end
        d4 = datetime("now");
        [output, ss] = simulationWithAI(aux(i,:), product_order, StorageStatus(k,:), output, file_nr);
        StorageStatus(k,:) = ss 
        d5 = datetime("now");
        file_nr = file_nr + 1;
        % saving datetime difference
        firstAI = between(d1,d2);
        secondAI = between(d3,d4);
        simulationTime = between(d4,d5);
        save("time/Time_"+cont, "simulationTime", "secondAI", "firstAI");
        cont = cont + 1;
    end

    % Then we need to 
end