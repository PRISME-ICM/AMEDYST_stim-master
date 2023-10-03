function [ EP, Parameters ] = PlanningEdited
global S

% trials
trials  = 2;


%% Paradigme

% Jitter
Parameters.MinPauseBetweenTrials       = 0.1; % seconds
Parameters.MaxPauseBetweenTrials       = 0.1; % seconds

% KND: For EEG adding jittered ITI premotor baseline
Parameters.PausePreMotor_Min       = 3; % seconds
Parameters.PausePreMotor_Max       = 4; % seconds

Parameters.TravelMaxDuration           = 0.6; % seconds
Parameters.TravelMinDuration           = 0.167; % seconds
% Parameters.TravelMinDuration           = 0.167; % seconds

% Show reward probability // Show points 
Parameters.RewardNoteDuration          = 1; % seconds

Parameters.PausePreMotor               = 0.1; % seconds

Parameters.PauseBetweenBlocks          = 10  ; % Ici 
% Move cursor
Parameters.TrialMaxDuration            = 4; % seconds
Parameters.TimeSpentOnTargetToValidate = 0.01; % seconds

Parameters.PausePostMotor              = 0.2; % seconds

% Show real reward
Parameters.ShowRewardDuration          = 0; % seconds, Pas besoin

Parameters.TargetAngles                = [20 60 120 160]       ;
%Parameters.Values                      = [0  1  2  3  ]/3 * 100;

% Parameters.RewPun                     = [0 0 1 2 0 0];  % ADAP : Reward  Punishment =2

Parameters.AnglesError                 = [0 10 20 30 360]; 
% Parameters.PointsRP                    = ; -1 -2 -3 -4];  % [Reward ; Punishment]
% Parameters.HitTarget                   = [4,0];    % Reward = 4, Punishment = 4

switch S.Task
    case 'ADAPT_Reward'
        Parameters.Points    = [3 2 1 0];
        Parameters.HitTarget = 4;
        Parameters.Puni      = '+';   
        S.Parameters.TextColor =  [0   255 0  ]  %Green

    case 'ADAPT_Punishment'
        Parameters.Points    = [-1 -2 -3 -4];
        Parameters.HitTarget = 0;
        Parameters.Puni      = '';
        S.Parameters.TextColor = [255 0   0  ];  % Red
        
    otherwise
        error('task ?')
end



switch S.DeviationSign
    case '+'
        Sign = 1;
    case '-'
        Sign = -1;
    otherwise
        error('DeviationSign error')
end


switch S.OperationMode
    
    case 'Acquisition'
        
        Paradigm = {
            'Direct_Pre'  0        trials 0
            'Direct_Pre'  0        trials 0
            'No_vision'   0        trials 0
            'Deviation'   Sign*30  trials 1
            'Deviation'   Sign*30  trials 1
            'Deviation'   Sign*30  trials 1
            'No_vision'   0        trials 0
            'No_vision'   0        trials 0
            'No_vision'   0        trials 0
            };
        
    case 'FastDebug'
        
        Paradigm = {                 
            'Direct_Pre'  0        1 0
            'Direct_Pre'  0        1 0
            'No_vision'   0        1 0
            'Deviation'   Sign*30  4 1
            'Deviation'   Sign*30  4 1
            'Deviation'   Sign*30  4 1
            'No_vision'   0        4 0
            'No_vision'   0        4 0
            'No_vision'   0        4 0
            };
        
    case 'RealisticDebug'
        
        Paradigm = {
            'Direct_Pre'  0        trials 0
            'No_vision'   0        trials 0
            'Deviation'   Sign*30  trials 1
            'Deviation'   Sign*30  trials 1
            'Deviation'   Sign*30  trials 1
            'No_vision'   0        trials 0
            'No_vision'   0        trials 0
            };

        
end

%Paradigm{:,end} = Paradigm{:,end} * 0

% Some values...
NrTrials  = sum(cell2mat(Paradigm(:,3)));
NrTargets = length(Parameters.TargetAngles);
%NrValues  = length(Parameters.Values);


header = { 'event_name', 'onset(s)', 'duration(s)', 'Block#', 'Trial#', 'Deviation(°)', 'Target angle (°)', 'Variable pause duration (s)', 'RewardPunishment'  'Premotor baseline (s)'};
EP     = EventPlanning(header);

% NextOnset = PreviousOnset + PreviousDuration
NextOnset = @(EP) EP.Data{end,2} + EP.Data{end,3};


% --- Start ---------------------------------------------------------------

EP.AddStartTime('StartTime',0);

% --- Stim ----------------------------------------------------------------

trial_counter = 0;

for block = 1 : size(Paradigm,1)
    
    % For each block, counterbalance Targets-Values
    if block > 1 
       EP.AddPlanning([ {'PauseTime',NextOnset(EP),Parameters.PauseBetweenBlocks} , ...
           repmat({[]},1,length(header)-3)]);
    end
    % Some values... per block
    %NrTrialsPerBlock  = Paradigm{block,3};
    
    % Counter-banlanced randomization of Vales per Targets
    
%     NrValuesPerTarget = NrTrialsPerBlock / NrTargets / NrValues;
%     
%     if NrValuesPerTarget < 1 % in Debug mode, it an happen, because of very few trials
%         NrValuesPerTarget = 1;
%     end
    
%    LinkTargetValue = nan(NrTrialsPerBlock/NrTargets, NrTargets); % pre-allocation
    
%     if NrValuesPerTarget == 1
%         LinkTargetValue = Common.ShuffleN( Parameters.Values, NrValuesPerTarget );
%     else
%         for target = 1 : NrTargets
%             LinkTargetValue(:, target) = Common.ShuffleN( Parameters.Values, NrValuesPerTarget );
%         end
%     end
%     
    % Shuffle the list of angles
    angleList = Shuffle( 1 : NrTargets );
    
    link_counter = 1;
    
    for trial_idx_in_block = 1 : Paradigm{block,3}
        
        trial_counter = trial_counter + 1;
        
        % If angleList is empty, generate a new one
        if isempty(angleList)
            angleList = Shuffle( 1 : NrTargets );
            link_counter = link_counter + 1;
        end
        
        pauseJitter = Parameters.MinPauseBetweenTrials + (Parameters.MaxPauseBetweenTrials-Parameters.MinPauseBetweenTrials)*rand; % in seconds (s), random value beween [a;b] interval
        
        % value = LinkTargetValue( link_counter , angleList(end) ); % Fetch the Value associated with this TargetAngle
             
        % For eeg KND added premotor jitter
        PausePreMotorJitter = Parameters.PausePreMotor_Min + (Parameters.PausePreMotor_Max-Parameters.PausePreMotor_Min)*rand; % in seconds (s), random value beween [a;b] interval

        % trialDuration = pauseJitter + Parameters.RewardNoteDuration + Parameters.RewardNoteDuration + Parameters.PausePreMotor + Parameters.TrialMaxDuration * 2 + Parameters.PausePostMotor + Parameters.ShowRewardDuration;
        trialDuration =   pauseJitter + Parameters.RewardNoteDuration + Parameters.RewardNoteDuration + PausePreMotorJitter      + Parameters.TrialMaxDuration * 2 + Parameters.PausePostMotor + Parameters.ShowRewardDuration;

        EP.AddPlanning({ ...
            Paradigm{block,1} NextOnset(EP) trialDuration block trial_counter Paradigm{block,2}  Parameters.TargetAngles(angleList(end)) ...
            pauseJitter ...
            Paradigm{block,4} ... % value double(rand*100<value)
            PausePreMotorJitter });

        angleList(end) = []; % Remove the last angle used
        
    end
    %({{ 'Rest-Block'} NextOnset(EP) Parameters.PauseBetweenBlocks block 0 0 0 0 0})
end

%EP.AddPlanning({'PauseTime',NextOnset(EP),Parameters.PauseBetweenBlocks,[],[],[],[],[],[]})
% --- Stop ----------------------------------------------------------------

EP.AddStopTime('StopTime',NextOnset(EP));
Parameters.Paradigm = Paradigm;

%% Check counter-balance design

% data = EP.Data;
% 
% for block = 1 : size(Paradigm,1)
%    
%     % Block name
% %     switch block
% %         case 1
% %             name = 'Direct_Pre';
% %         case 2
% %             name = 'Deviation';
% %         case 3
% %             name = 'Direct_Post';
% %         otherwise
% %             error('block ?')
% %     end % switch
%     
%     name = Paradigm{block,1}
% 
%     % Fetch data in the current block
%     block_idx     = strcmp(data(:,1),name);
%     data_in_block = cell2mat(data( block_idx , 2:end ));
%     
% %     for target  = 1 : NrTargets
% %         
% %         taget_idx =  Parameters.TargetAngles(target) == data_in_block(:,EP.Get('Target')-1) ;
% %         
% %         vales_target = data_in_block(taget_idx,EP.Get('Probability')-1);
% %         
% %         valesCountVect = nan(NrValues,1);
% %         
% %         for value = 1 : NrValues
% %             valesCountVect(value) = sum(vales_target == Parameters.Values(value));
% %         end
% %         
% %         if sum(diff(valesCountVect)) > 0
% %             warning('error in counter-balance of Target-ProbaValues (dont worry in FastDebug)')
% %         end
% %         
% %     end
%     
% end


%% Compute gain when rewarded

% NrRewardPerValue = Parameters.Values/100 * NrTrials/length(Parameters.Values);
% UnitGain         = TotalMaxReward / sum(NrRewardPerValue);
% TotalReward      = sum(cell2mat(EP.Data(2:end-1,10))) * UnitGain;
% fprintf('UnitGain for this run     : %g € \n', UnitGain);
% fprintf('Total reward for this run : %g € \n', TotalReward);

%Parameters.UnitGain    = UnitGain;
%Parameters.TotalReward = TotalReward;


%% Display

% To prepare the planning and visualize it, we can execute the function
% without output argument

if nargout < 1
    
    fprintf( '\n' )
    fprintf(' \n Total stim duration : %g seconds \n' , NextOnset(EP) )
    fprintf( '\n' )
    
    EP.Plot
    
end

end % function