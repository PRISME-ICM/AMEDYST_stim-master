function [ EP ] = Planning
global S

if nargout < 1 % only to plot the paradigme when we execute the function outside of the main script
    S.Environement    = 'MRI';
    S.OperationMode   = 'Acquisition';
    S.ComplexSequence = '';
end


%% Paradigme

SIMPLE = '5432';

switch S.OperationMode
    case 'Acquisition'
        SequenceDuration    = 20;  % seconds
        RestDuration        = 15;  % seconds
        NrBlocksSimple      = 5;
        NrBlocksComplex     = 5;
        InstructionDuration = 2;   % seconds
        TapFrequency        = 1.5; % Hz
    case 'FastDebug'
        SequenceDuration    = 6;  % seconds
        RestDuration        = 2;  % seconds
        NrBlocksSimple      = 1;
        NrBlocksComplex     = 1;
        InstructionDuration = 1;  % seconds
        TapFrequency        = 1.5; % Hz
    case 'RealisticDebug'
        SequenceDuration    = 20; % seconds
        RestDuration        = 5;  % secondes
        NrBlocksSimple      = 1;
        NrBlocksComplex     = 1;
        InstructionDuration = 1;  % seconds
        TapFrequency        = 1.5; % Hz
end

randomizeOrder = 1; % 0 or 1


% Check if SequenceDuration and TapFrequency are coherent
N_cycles_per_block = SequenceDuration*TapFrequency;
if N_cycles_per_block ~= round(N_cycles_per_block)
    warning([...
        'N_cycles_per_block = SequenceDuration*TapFrequency = %f is not an integer. \n' ...
        'There will be visual glitch/jump at the end of each sequence block'...
        ]...
        ,N_cycles_per_block)
end


%% Backend setup

switch randomizeOrder
    case 1
        BlockOrder = Common.Randomize01(NrBlocksSimple,NrBlocksComplex);
    case 0
        error('no randmization not coded yet !')
end

% initilaise the container
Paradigm = { 'Instruction' InstructionDuration [] []; 'Repos' RestDuration SIMPLE TapFrequency};

for n = 1:length(BlockOrder)
    
    if BlockOrder(n) % 1
        Paradigm  = [ Paradigm ; {'Instruction' InstructionDuration [] []}; {'Complexe' SequenceDuration S.ComplexSequence TapFrequency} ]; %#ok<*AGROW>
    else % 0
        Paradigm  = [ Paradigm ; {'Instruction' InstructionDuration [] []}; {'Simple'   SequenceDuration SIMPLE            TapFrequency} ];
    end
    
    Paradigm  = [ Paradigm ; { 'Instruction' InstructionDuration [] []} ; {'Repos' RestDuration SIMPLE TapFrequency} ];
    
end


%% Define a planning <--- paradigme


% Create and prepare
header = { 'event_name' , 'onset(s)' , 'duration(s)' 'SequenceFingers(vect)' 'TapFrequency(Hz)'};
EP     = EventPlanning(header);

% NextOnset = PreviousOnset + PreviousDuration
NextOnset = @(EP) EP.Data{end,2} + EP.Data{end,3};


% --- Start ---------------------------------------------------------------

EP.AddPlanning({ 'StartTime' 0  0 [] []});

% --- Stim ----------------------------------------------------------------

for p = 1 : size(Paradigm,1)
    
    EP.AddPlanning({ Paradigm{p,1} NextOnset(EP) Paradigm{p,2} Paradigm{p,3} Paradigm{p,4}});
    
end

% --- Stop ----------------------------------------------------------------

EP.AddPlanning({ 'StopTime' NextOnset(EP) 0 [] []});


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
