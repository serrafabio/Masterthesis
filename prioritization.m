% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Here we create the function to simulate the first part of
% the AI. We gave the order quantity of each product to manufacture and
% receive as output which section it must be start.
%
function result = prioritization(StorageStatus, Orders)
result = zeros(height(Orders));
% generate the production function
    function p = prodfunc(StorageStatus, Orders, order_nr)
        p = 0;
        if Orders{order_nr,"ProductA"} > 0
            p = p + (productionfunction_2("ProductA",StorageStatus(1,:),Orders{order_nr,"ProductA"}, Orders{order_nr, "Orders"}));
        end
        if Orders{order_nr,"ProductB"} > 0
            p = p + (productionfunction_2("ProductB",StorageStatus(1,:),Orders{order_nr,"ProductB"}, Orders{order_nr, "Orders"}));
        end
        if Orders{order_nr,"ProductC"} > 0
            p = p + (productionfunction_2("ProductC",StorageStatus(1,:),Orders{order_nr,"ProductC"}, Orders{order_nr, "Orders"}));
        end
        if Orders{order_nr,"ProductD"} > 0
            p = p + (productionfunction_2("ProductD",StorageStatus(1,:),Orders{order_nr,"ProductD"}, Orders{order_nr, "Orders"}));
        end
        if Orders{order_nr,"ProductE"} > 0
            p = p + (productionfunction_2("ProductE",StorageStatus(1,:),Orders{order_nr,"ProductE"}, Orders{order_nr, "Orders"}));
        end
        if Orders{order_nr,"ProductF"} > 0
            p = p + (productionfunction_2("ProductF",StorageStatus(1,:),Orders{order_nr,"ProductF"}, Orders{order_nr, "Orders"}));
        end
    end

    for n = 1:1:height(Orders)
        % create the markov chain process
        MDP = createMDP(5, ["first"; "second";"third";"fourth"]);
        % create rewards
        % state 1
        MDP.T(1,2,1) = 1
        MDP.R(1,2,1) = 1/(prodfunc(StorageStatus, Orders, n));
        MDP.T(1,3,2) = 1;
        MDP.R(1,3,2) = 1/(prodfunc(StorageStatus, Orders, n));
        MDP.T(1,4,3) = 1;
        MDP.R(1,4,3) = 1/(prodfunc(StorageStatus, Orders, n));
        MDP.T(1,5,4) = 1;
        MDP.R(1,5,4) = 1/(prodfunc(StorageStatus, Orders, n));
        % state 2
        MDP.T(2,2,1) = 1;
        MDP.R(2,2,1) = 0;
        MDP.T(2,2,2) = 1;
        MDP.R(2,2,2) = 0;
        MDP.T(2,2,3) = 1;
        MDP.R(2,2,3) = 0;
        MDP.T(2,2,4) = 1;
        MDP.R(2,2,4) = 0;
        % state 3
        MDP.T(3,3,1) = 1;
        MDP.R(3,3,1) = 0;
        MDP.T(3,3,2) = 1;
        MDP.R(3,3,2) = 0;
        MDP.T(3,3,3) = 1;
        MDP.R(3,3,3) = 0;
        MDP.T(3,3,4) = 1;
        MDP.R(3,3,4) = 0;
        % state 4
        MDP.T(4,4,1) = 1;
        MDP.R(4,4,1) = 0;
        MDP.T(4,4,2) = 1;
        MDP.R(4,4,2) = 0;
        MDP.T(4,4,3) = 1;
        MDP.R(4,4,3) = 0;
        MDP.T(4,4,4) = 1;
        MDP.R(4,4,4) = 0;
        
        % terminal states
        MDP.TerminalStates = ["s2";"s3";"s4";"s5"];
        % create environment
        env = rlMDPEnv(MDP);
        % specify a reset function that returns the initial agent state
        env.ResetFcn = @() 1;
        % fix the random generator seed for repoducibility
        rng(0)
        % create Q-Learning Agent
        obsInfo = getObservationInfo(env);
        actInfo = getActionInfo(env);
        qTable = rlTable(obsInfo, actInfo);
        qFunction = rlQValueFunction(qTable, obsInfo, actInfo);
        qOptions = rlOptimizerOptions(LearnRate=1);
        % create Q-Learning agent using this table representation
        agentOpts = rlQAgentOptions;
        agentOpts.DiscountFactor = 1;
        agentOpts.EpsilonGreedyExploration.Epsilon = 0.9;
        agentOpts.EpsilonGreedyExploration.EpsilonDecay = 0.01;
        agentOpts.CriticOptimizerOptions = qOptions;
        qAgent = rlQAgent(qFunction,agentOpts); %#ok<NASGU> 
        % Train Q-Learning Agent
        trainOpts = rlTrainingOptions;
        trainOpts.MaxStepsPerEpisode = 10;
        trainOpts.MaxEpisodes = 500;
        trainOpts.StopTrainingCriteria = "AverageReward";
        trainOpts.StopTrainingValue = 13;
        trainOpts.ScoreAveragingWindowLength = 30;
        trainOpts.Plots = "none";
        doTraining = true;
        if doTraining
            % Train the agent.
            trainingStats = train(qAgent,env,trainOpts); %#ok<UNRCH>
        else
            % Load pretrained agent for the example.
            load("genericMDPQAgent.mat","qAgent"); 
        end
        Data = sim(qAgent,env);
        cumulativeReward = sum(Data.Reward);
        QTable = getLearnableParameters(getCritic(qAgent));
        result(n,:) = QTable{1}(1,:);
    end
end