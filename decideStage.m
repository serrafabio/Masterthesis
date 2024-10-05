% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Here we create the function to simulate the first part of
% the AI. We gave the order quantity of each product to manufacture and
% receive as output which section it must be start.
%
function qtable = decideStage(StorageStatus, product, qt, order_nr)
    % create the markov chain process
    MDP = createMDP(4, ["empty";"manufacture"; "stample"; "available"]);
    % create rewards
    % state 1
    MDP.T(1,1,1) = 1;
    MDP.R(1,1,1) = -1;
    MDP.T(1,2,2) = 1;
    MDP.R(1,2,2) = productionfunction(product,StorageStatus,3,qt, order_nr);
    MDP.T(1,3,3) = 1;
    MDP.R(1,3,3) = productionfunction(product,StorageStatus,2,qt, order_nr);
    MDP.T(1,4,4) = 1;
    MDP.R(1,4,4) = productionfunction(product,StorageStatus,1,qt, order_nr);
    % state 2
    MDP.T(2,1,1) = 1;
    MDP.R(2,1,1) = 0;
    MDP.T(2,2,2) = 1;
    MDP.R(2,2,2) = 0;
    MDP.T(2,3,3) = 1;
    MDP.R(2,3,3) = 0;
    MDP.T(2,4,4) = 1;
    MDP.R(2,4,4) = 0;
    % state 3
    MDP.T(3,2,1) = 1;
    MDP.R(3,2,1) = (productionfunction(product,StorageStatus,3,qt, order_nr) - productionfunction(product,StorageStatus,2,qt, order_nr));
    MDP.T(3,1,2) = 1;
    MDP.R(3,1,2) = 0;
    MDP.T(3,3,3) = 1;
    MDP.R(3,3,3) = 0;
    MDP.T(3,4,4) = 1;
    MDP.R(3,4,4) = 0;
    % state 4
    MDP.T(3,2,1) = 1;
    MDP.R(3,2,1) = (productionfunction(product,StorageStatus,2,qt, order_nr) - productionfunction(product,StorageStatus(1,:),1,qt, order_nr));
    MDP.T(3,1,2) = 1;
    MDP.R(3,1,2) = 0;
    MDP.T(3,3,3) = 1;
    MDP.R(3,3,3) = 0;
    MDP.T(3,4,4) = 1;
    MDP.R(3,4,4) = 0;
    
    % terminal states
    MDP.TerminalStates = ["s2"; "s3"; "s4"];
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
    trainOpts.MaxEpisodes = 1000;
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
    qtable = getLearnableParameters(getCritic(qAgent));
end