% Title: Development of a resilient Reinforcement Learning-based decision 
% algorithm for order scheduling
%
% Author: Fabio Serra Pereira
%
% Description: Here we create the function to simulate the first part of
% the AI. We gave the order quantity of each product to manufacture and
% receive as output which section it must be start.
%
function result = StorageDecisionFunction(StorageStatus, station, order_nr)
    E_sum = 30;    
    % resilience Scenario adjustment    
    %if 25 <= order_nr <= 30
    %    E_sum = 10;
    %end
    % create the markov chain process
    MDP = createMDP(3, ["not_delivery"; "delivery"]);
    % state 1
    MDP.T(1,2,1) = 1;
    MDP.R(1,2,1) = E_sum;
    MDP.T(1,3,2) = 1;
    MDP.R(1,3,2) = E_sum - StorageStatus{1, station};
    % state 2
    MDP.T(2,2,1) = 1;
    MDP.R(2,2,1) = 0;
    MDP.T(2,2,2) = 1;
    MDP.R(2,2,2) = 0;
    % state 3
    MDP.T(3,3,1) = 1;
    MDP.R(3,3,1) = 0;
    MDP.T(3,3,2) = 1;
    MDP.R(3,3,2) = 0;
    
    % terminal states
    MDP.TerminalStates = ["s2";"s3"];
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
    result = QTable{1}(1,:);
end