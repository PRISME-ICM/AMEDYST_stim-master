function msg = PrepareEventCodes()
% EventCodes

%% SEQ

% Finger tap
msg.finger_1 = 1;
msg.finger_2 = 2;
msg.finger_3 = 3;
msg.finger_4 = 4;
msg.finger_5 = 5;

% Audio instructions
msg.Repos       = 10;
msg.Instruction = 20;
msg.Simple      = 30;
msg.Complexe    = 40;


%% ADAPT

msg.Jitter          = 1; %Jitter
msg.PausePreMotor   = 2; %Fixation cross (previously 3)

msg.GoBack__Start   = 3; %Check if the cursor is at the center (previously 7)
msg.GoBack__TT      = 4; %Cursor in the center (previously 9)

msg.Motor__Start    = 5; %beginning of the trial, target appearance (previously 4)
msg.Motor__RT       = 6; %Movement starts (previously 5)
msg.Motor__TT       = 7; %target reached (previously 15)
msg.Motor__TOut     = 8; %target not reached (previously 12)

msg.ShowNote        = 9; %Shows points (previously 13)
msg.PausePreReward  = 10; %present but not useful?


% msg.ShowProbability = 2;
% msg.GoBack__RT      = 8;
% msg.ShowReward      = 11;
% 
% msg.Motor__TOut     = 12;
% msg.ShowSumNote     = 14;
% msg.Motor__TO       = 16;


%% Finalize

% Pulse duration
msg.duration    = 0.003; % seconds