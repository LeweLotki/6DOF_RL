close all
clearvars
clc

initManipulatorParameters

desire_position = [0, -12.4675, 16.2833, 11.7267]; % Z->X Y->Z X->Y
mdl = 'main';
open_system(mdl);

numObs = 8;
obsInfo = rlNumericSpec([numObs 1]);
obsInfo.Name = 'observations';

numAct = 4;
actInfo = rlNumericSpec([numAct 1],'LowerLimit',-1,'UpperLimit', 1);
actInfo.Name = 'torque';

blk = [mdl, '/RL Agent'];
env = rlSimulinkEnv(mdl,blk,obsInfo,actInfo);

env.ResetFcn = @ResetFcn;

createNetwork

agentOptions = rlDDPGAgentOptions;
agentOptions.SampleTime = Ts;
agentOptions.DiscountFactor = 0.99;
agentOptions.MiniBatchSize = 250;
agentOptions.ExperienceBufferLength = 1e6;
agentOptions.TargetSmoothFactor = 1e-3;
agentOptions.NoiseOptions.MeanAttractionConstant = 0.15;
agentOptions.NoiseOptions.StandardDeviation = 0.1;

agent = rlDDPGAgent(actor,critic,agentOptions);

maxEpisodes = 10000;
maxSteps = floor(Tf/Ts);  
trainOpts = rlTrainingOptions(...
    'MaxEpisodes',maxEpisodes,...
    'MaxStepsPerEpisode',maxSteps,...
    'ScoreAveragingWindowLength',25,...
    'Verbose',true,...
    'Plots','training-progress',...
    'StopTrainingCriteria','AverageReward',...
    'StopTrainingValue',2.5e2,...                   
    'SaveAgentCriteria','EpisodeReward',... 
    'SaveAgentValue',2.6e2);     

trainOpts.UseParallel = true;                    
trainOpts.ParallelizationOptions.Mode = 'async';
trainOpts.ParallelizationOptions.StepsUntilDataIsSent = 32;
trainOpts.ParallelizationOptions.DataToSendFromWorkers = 'Experiences';

doTraining = true;
if doTraining    
    % Train the agent.
    trainingStats = train(agent,env,trainOpts);
else
    % Load a pretrained agent for the example.
    load('savedAgents\Agent553.mat','saved_agent');
end

rng(0)

simOptions = rlSimulationOptions('MaxSteps',maxSteps);
experience = sim(env,agent,simOptions);