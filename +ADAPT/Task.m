function [ TaskData ] = Task
global S prevX prevY newX newY

try
    %% Tunning of the task
    % 
    % [ EP, Parameters ] = ADAPT.PlanningEdited;
    [ EP, Parameters ] = ADAPT.Planning;


    % End of preparations
    EP.BuildGraph;
    TaskData.EP = EP;

    %% Prepare event record and keybinf logger
    [ ER, RR, KL, SR, OutRecorder, InRecorder ] = Common.PrepareRecorders( EP );

    %% Prepare objects
    Cross                  = ADAPT.Prepare.Cross      ;
    BigCircle              = ADAPT.Prepare.BigCircle  ;
    [ Target, PrevTarget ] = ADAPT.Prepare.Target     ;
    Cursor                 = ADAPT.Prepare.Cursor     ;
    Probability            = ADAPT.Prepare.Probability;
    MarkingPoint           = Cursor.CopyObject;

    %% Eyelink
    Common.StartRecordingEyelink

    %% Go
    % Initialize some variables
    EXIT = 0;
    TargetBigCirclePosition = (BigCircle.diameter-BigCircle.thickness)/2;
    Red    = [255 0   0  ];
    Green  = [0   255 0  ];
    Yellow = [255 255 0 ];
    MarkingPoint.diskCurrentColor = Yellow;

    % Loop over the EventPlanning
    for evt = 1 : size( EP.Data , 1 )

        if S.Verbosity
            Common.CommandWindowDisplay( EP, evt );
        end

        switch EP.Data{evt,1}

            case 'StartTime' % --------------------------------------------

                % Fetch initialization data
                switch S.InputMethod
                    case 'Joystick'
                        [newX, newY] = ADAPT.QueryJoystickData( Cursor.screenX, Cursor.screenY );
                    case 'Mouse'
                        SetMouse(Cursor.Xptb,Cursor.Yptb,Cursor.wPtr);
                        [newX, newY] = ADAPT.QueryMouseData( Cursor.wPtr, Cursor.Xorigin, Cursor.Yorigin, Cursor.screenY );
                end

                % Here at initialization, we don't apply deviation, just fetche raw data
                Cursor.Move(newX,newY);

                prevX = newX;
                prevY = newY;

                % Fixation Cross Draw
                Cross.Draw
                Screen('DrawingFinished',S.PTB.wPtr);
                Screen('Flip',S.PTB.wPtr);

                StartTime = Common.StartTimeEvent;

            case 'StopTime' % ---------------------------------------------

                StopTime = GetSecs;

                % Record StopTime
                ER.AddStopTime( 'StopTime' , StopTime - StartTime );
                RR.AddStopTime( 'StopTime' , StopTime - StartTime );

                ShowCursor;
                Priority( 0 );

            case 'PauseTime' % break in the sequence 
                if S.Verbosity
                    disp('Pause time')
                    DrawFormattedText(S.PTB.wPtr,'Starting pause...', 'center','center');
                    Screen('DrawingFinished',S.PTB.wPtr);
                    Screen('Flip',S.PTB.wPtr);
                    WaitSecs(.2);
                end
                stepPauseTimes = 1 ;
                counter_step_pause_notes  = 0;
                if  EP.Get('Rew',evt - 1) && S.Feedback
                    ind = find(OutRecorder.Data(:,1) == EP.Get('Bloc',evt-1));
                    sumNotes = sum(OutRecorder.Get('Points', ind));
                    proba_str = sprintf( '\n%s%d total points\n' ,Parameters.Puni, sumNotes);%ER.Get('Rew',evt)) ); % looks like "33 %"
                elseif ~S.Feedback && EP.Get('Rew',evt - 1)
                    Probability.color =     S.Parameters.Text.Color;   % S.Parameters.TextColor = [128 128 128]
                    proba_str = sprintf( 'End of this block' );
                else
                    proba_str = sprintf( '' );
                end

                while stepPauseTimes

                    counter_step_pause_notes = counter_step_pause_notes + 1;

                    BigCircle.Draw
                   
                    if lastFlipOnset <= step6onset + (Parameters.PauseBetweenBlocks/2 )
                        Probability.Draw( proba_str );
                    end

                     if S.Verbosity                        
                        DrawFormattedText(S.PTB.wPtr,'Pausing...','center');                        
                    end
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt-1))

                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])

                    % Record trial onset & step onset
                    if counter_step_show_reward_notes == 1
                        % From previous trial:
                        %RR.AddEvent({['ShowSumNote__' EP.Data{evt-1,1}] lastFlipOnset-StartTime [] EP.Data{evt-1,4} EP.Data{evt-1,5} EP.Data{evt-1,6} EP.Data{evt-1,7} EP.Data{evt-1,8} EP.Data{evt-1,9}})
                        RR.AddEvent([{['ShowSumNote__' EP.Data{evt-1,1}] lastFlipOnset-StartTime []} EP.Data(evt-1,4:end) ]);
                        step6onset = lastFlipOnset;
                        Common.SendParPortMessage( 'ShowSumNote' )
                    end

                    if lastFlipOnset >= step6onset + Parameters.PauseBetweenBlocks
                        stepPauseTimes = 0;
                    end

                    % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT
                        break
                    end
                end % while stepPauseTimes

            case {'Direct_Pre', 'Deviation', 'No_vision'} % --------------------------------

                % Echo in the command window
                if S.Verbosity
                    % fprintf('#%3d deviation=%3° target=%3d° value=%3d%% Noreward=%d \n',round(cell2mat(EP.Data(evt,[5 6 7 9]))));
                    fprintf('#%3d deviation=%3° target=%3d° value=%3d%% Noreward=%d \n',EP.Data{evt,5},EP.Data{evt,6},EP.Data{evt,7},EP.Data{evt,9});
                end

                %% ~~~ Jitter between trials ~~~

                stepJitterRunning  = 1;
                counter_step_jitter = 0;
                
                ThisTrialPausePremotor = EP.Get('Premotor',evt);

                while stepJitterRunning

                    counter_step_jitter = counter_step_jitter + 1;

                    BigCircle.Draw;
                    Cross.Draw;
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt));

                    if S.Verbosity
                        DrawFormattedText(S.PTB.wPtr,'Pause...','center');
                    end

                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta]);

                    %   % Record trial onset & step onset
                    if counter_step_jitter == 1
                        % Original version:
                        % ER.AddEvent({EP.Data{evt,1}            lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        
                        % KND
                        % Should Add signedAUC and PeakVelocity per trial
                        % info here?
                        ER.AddEvent([{            EP.Data{evt,1}  lastFlipOnset-StartTime []} EP.Data(evt,4:end)]);
                        RR.AddEvent([{['Jitter__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end)]);
                        step0onset = lastFlipOnset;
                        Common.SendParPortMessage( 'Jitter' )
                    end

                    if lastFlipOnset >= step0onset + EP.Data{evt,8}
                        stepJitterRunning = 0;
                    end

                    % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT                      
                        break
                    end

                end % while

                if EXIT
                    break
                end


                %% ~~~ Pause before start of motor sequence ~~~

                stepPauseBeforeMotor  = 1;
                counter_step_pause_preMotor = 0;

                while stepPauseBeforeMotor

                    counter_step_pause_preMotor = counter_step_pause_preMotor + 1;

                    BigCircle.Draw
                    Cross.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))

                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])

                    % Record trial onset & step onset
                    if counter_step_pause_preMotor == 1                        
                        RR.AddEvent([{['Jitter__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end)]);                        
                        step5onset = lastFlipOnset;
                        Common.SendParPortMessage( 'PausePreMotor' )
                    end
                     
                    if lastFlipOnset >= step5onset + ThisTrialPausePremotor
                        stepPauseBeforeMotor = 0;
                    end

                   % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT
                        break
                    end

                end % while

                %% ~~~ Draw target @ center ~~~

                BigCircle.Draw
                Cross.Draw

                Target.frameCurrentColor = Target.frameBaseColor;
                Target.Move(0,0)
                Target.Draw

                PrevTarget.frameCurrentColor = Red;
                PrevTarget.Move( TargetBigCirclePosition, EP.Get('Target',evt)  )

                ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                Cursor.Draw

                Screen('DrawingFinished',S.PTB.wPtr);
                flipOnset_step_3 = Screen('Flip',S.PTB.wPtr);
                SR.AddSample([flipOnset_step_3-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                % RR.AddEvent({['GoBack__Start__'  EP.Data{evt,1}] flipOnset_step_3-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                RR.AddEvent([{['GoBack__Start__' EP.Data{evt,1}] flipOnset_step_3-StartTime []} EP.Data(evt,4:end) ]);

                Common.SendParPortMessage( 'GoBack__Start' )

                startCursorInTarget = [];
                stepGoBackRunning   = 1;
                draw_PrevTraget      = 1;
                has_already_traveled = 0;
                frame_start = SR.SampleCount;
                counter_step_go_back = 0;

                while stepGoBackRunning
                    counter_step_go_back = counter_step_go_back + 1;
                    BigCircle.Draw
                    Cross.Draw
                    Target.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
                    Cursor.Draw
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])

                    % Record step onset
                    if counter_step_go_back == 1
                        %RR.AddEvent({['Move@Center__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        RR.AddEvent([{['Move@Center__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                    end

                    % Is cursor center in the previous target (@ ring) ?
                    if     ADAPT.IsOutside(Cursor,PrevTarget) &&  draw_PrevTraget % yes
                    elseif ADAPT.IsOutside(Cursor,PrevTarget) && ~draw_PrevTraget % back inside
                    elseif draw_PrevTraget % just outside
                        PrevTarget.frameCurrentColor = PrevTarget.frameBaseColor;
                        draw_PrevTraget = 0;
                        ReactionTimeIN = lastFlipOnset - flipOnset_step_3;
                        %RR.AddEvent({['GoBack__RT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                        RR.AddEvent([{['GoBack__RT__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);

                    else
                    end

                    % Is cursor center in target ?
                    if ADAPT.IsInside(Cursor,Target) % yes
                        Target.frameCurrentColor = Green;
                        if isempty(startCursorInTarget) % Cursor has just reached the target
                            startCursorInTarget = lastFlipOnset;

                            if ~has_already_traveled
                                TravelTimeIN = lastFlipOnset - flipOnset_step_3 - ReactionTimeIN;
                                has_already_traveled = 1;
                            end

                        elseif lastFlipOnset >= startCursorInTarget + Parameters.TimeSpentOnTargetToValidate % Cursor remained in the target long enough
                            stepGoBackRunning = 0;
                            %RR.AddEvent({['GoBack__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                            RR.AddEvent([{['GoBack__RT__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                            Common.SendParPortMessage( 'GoBack__TT' )
                        end

                    else % no, then reset
                        startCursorInTarget = []; % reset
                        Target.frameCurrentColor = Target.frameBaseColor;
                    end

                    % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT
                        break
                    end

                end % while : Setp 4

                Target.frameCurrentColor = Target.frameBaseColor;
                frame_stop = SR.SampleCount;

                if EXIT
                    break
                else
                    InRecorder.AddSample([EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,8} EP.Data{evt,6} EP.Data{evt,9} EP.Data{evt,7} frame_start frame_stop round(ReactionTimeIN*1000) round(TravelTimeIN*1000)])
                end


                %% ~~~ Draw target @ big ring ~~~

                BigCircle.Draw
                Cross.Draw

                Target.frameCurrentColor = Target.frameBaseColor;
                Target.Move( TargetBigCirclePosition, EP.Get('Target',evt) )
                %                 Target.value = EP.Get('Probability',evt);
                %                 Target.valueCurrentColor = GetColor(Target.value);
                Target.Draw

                PrevTarget.frameCurrentColor =  BigCircle.frameBaseColor;
                PrevTarget.Move( 0, 0 )
                PrevTarget.Draw

                ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))

                Screen('DrawingFinished',S.PTB.wPtr);
                flipOnset_step_Action = Screen('Flip',S.PTB.wPtr);

                SR.AddSample([flipOnset_step_Action-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])
                %RR.AddEvent({['Motor__Start' EP.Data{evt,1}] flipOnset_step_Action-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                RR.AddEvent([{['Motor__Start' EP.Data{evt,1}] flipOnset_step_Action-StartTime []} EP.Data(evt,4:end) ]);

                Common.SendParPortMessage( 'Motor__Start' )


                %% ~~~ User moves cursor to target @ big ring  ~~~
                stepActionRunning   = 1;
                draw_PrevTraget      = 1;
                has_already_traveled = 0;
                passed    = 0;
                frame_start = SR.SampleCount;
                counter_step_Action = 0;
                ReactionTimeOUT = NaN;
                TravelTimeOUT   = NaN;
                too_late = 0;

                while stepActionRunning

                    counter_step_Action = counter_step_Action + 1;

                    BigCircle.Draw   % ici
                    Cross.Draw
                    Target.Draw
                    if draw_PrevTraget
                        PrevTarget.Draw

                    end

                    PrevCursor = Cursor.CopyObject;     %%%% � modifier
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))

                    if Cursor.R <= TargetBigCirclePosition - 2;
                        if draw_PrevTraget || ~strcmp(EP.Data{evt,1}, 'No_vision')
                            Cursor.Draw
                        end
                    end
                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])

                    % Record step onset
                    if counter_step_Action == 1
                        %RR.AddEvent({['Move@Ring__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                        RR.AddEvent([{['Move@Ring__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                    end

                    if     ADAPT.IsOutside(Cursor,PrevTarget) &&  draw_PrevTraget % yes
                    elseif ADAPT.IsOutside(Cursor,PrevTarget) && ~draw_PrevTraget % back inside
                    elseif draw_PrevTraget % just outside
                        PrevTarget.frameCurrentColor = PrevTarget.frameBaseColor;
                        draw_PrevTraget = 0;
                        ReactionTimeOUT = lastFlipOnset - flipOnset_step_Action;
                        %RR.AddEvent({['Motor__RT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9} })
                        RR.AddEvent([{['Move@Ring__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                        Common.SendParPortMessage( 'Motor__RT' )
                    else
                    end

                    % Has time elapsed? 
                    if (lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT) >= Parameters.TravelMaxDuration && ~has_already_traveled
                        Target.frameCurrentColor    = Red;
                        TravelTimeOUT = lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT;
                        too_late  = 1;
                        RR.AddEvent([{['Motor__TTOVER__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                        Common.SendParPortMessage( 'Motor__TO' )
                        stepActionRunning = 0;
                        eAngle = 0;
                        note   = 0;
                    end

                    % Is cursor center in target ?
                    if ADAPT.IsInside(Cursor,Target) && ~too_late 
                        Target.frameCurrentColor = Green;
                        [x,y] = ADAPT.estimate_intersection(PrevCursor, Cursor, BigCircle);
                        passed = 1;
                        MarkingPoint.Move(x,y);
                        if ~has_already_traveled
                            TravelTimeOUT = lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT;
                            has_already_traveled = 1;
                        end

                        if EP.Get('Rew',evt)
                            note = Parameters.HitTarget(EP.Get('Rew',evt));
                        else
                            note = 0;
                        end
                        stepActionRunning = 0;
                        eAngle = 0;
                        %RR.AddEvent({['Motor__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        RR.AddEvent([{['Motor__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                        Common.SendParPortMessage( 'Motor__TT' )

                    elseif ((Cursor.R >= TargetBigCirclePosition - 1) && ...
                            PrevCursor.R < TargetBigCirclePosition ) || passed   % ADAPT.IsInCircle( PrevCursor, BigCircle )  % (abs(Cursor.R - BigCircle.diameter/2) < 8
                        % is cursor out BigCircle
                        TravelTimeOUT = lastFlipOnset - flipOnset_step_Action - ReactionTimeOUT;

                        %  BigCircle.frameCurrentColor = Red;
                        [x,y] = ADAPT.estimate_intersection(PrevCursor, Cursor, BigCircle);
                        passed = 1;
                        MarkingPoint.Move(x,y);

                        if ADAPT.IsInside(MarkingPoint,Target)
                            Target.frameCurrentColor = Green;
                            passed = 0;
                            if EP.Get('Rew',evt)
                                note = Parameters.HitTarget(EP.Get('Rew',evt));
                            else
                                note = 0;
                            end
                            eAngle = 0;
                            %RR.AddEvent({['Motor__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                            RR.AddEvent([{['Motor__TT__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                            Common.SendParPortMessage( 'Motor__TT' )
                            stepActionRunning = 0;
                        else
                            Target.frameCurrentColor = Red;
                            eAngle = ADAPT.errorAngle(Target.THETA ,  MarkingPoint.Theta );
                            note   = ADAPT.getNote(eAngle, Parameters.AnglesError,Parameters.Points);
                            %RR.AddEvent({['Motor__TOut__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}});
                            RR.AddEvent([{['Motor__TOut__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                            Common.SendParPortMessage( 'Motor__TOut' )
                            stepActionRunning = 0;
                        end

                    end

                   % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT
                        break
                    end

                end % while : Setp 2

                frame_stop = SR.SampleCount;
                stepShowRewardNotes  = 1;
                counter_step_show_reward_notes = 0;
                failedTrial = 0;

                if TravelTimeOUT < Parameters.TravelMinDuration
                    Probability.color =     S.Parameters.Text.Color;
                    proba_str = sprintf('\nToo fast\n');
                    if S.Verbosity
                        fprintf('TravelTimeOUT: %g<%g',TravelTimeOUT,Parameters.TravelMinDuration);
                    end
                    Target.frameCurrentColor = Red;

                    passed = 0;
                    % eAngle = 0;
                    note   = 0;
                    failedTrial = 1;
                elseif too_late
                    Probability.color =     S.Parameters.Text.Color;   % S.Parameters.TextColor = [128 128 128]
                    proba_str = sprintf( '\nToo late\n');
                    failedTrial  = 1 ;
                else
                    if  EP.Get('Rew',evt) && S.Feedback
                        proba_str = sprintf( '\n%s%d\n' ,Parameters.Puni, note);%ER.Get('Rew',evt)) ); % looks like "33 %"
                    elseif ~ S.Feedback && EP.Get('Rew',evt)
                        Probability.color =     S.Parameters.Text.Color;    % S.Parameters.TextColor = [128 128 128]
                        proba_str = sprintf( '_ | o' );
                    else
                        proba_str = sprintf( '' );
                    end
                end
                if EXIT
                    break
                else
                    OutRecorder.AddSample([EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,8} EP.Data{evt,6} EP.Data{evt,9} EP.Data{evt,7} frame_start frame_stop round(ReactionTimeOUT*1000) round(TravelTimeOUT*1000) round(eAngle) round(note) failedTrial])
                end
                while stepShowRewardNotes
                    counter_step_show_reward_notes = counter_step_show_reward_notes + 1;
                    BigCircle.Draw
                    Target.Draw
                    if passed
                        MarkingPoint.Draw;
                    end
                    Probability.Draw( proba_str );
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))

                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])

                    % Record trial onset & step onset
                    if counter_step_show_reward_notes == 1
                        %RR.AddEvent({['ShowNote__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        RR.AddEvent([{['ShowNote__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                        step6onset = lastFlipOnset;
                        Common.SendParPortMessage( 'ShowNote' )
                    end

                    if lastFlipOnset >= step6onset + Parameters.RewardNoteDuration
                        stepShowRewardNotes = 0;
                    end

                    % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT
                        break
                    end

                end % while stepShowRewardNotes

                Probability.color = S.Parameters.TextColor;

                %% ~~~ Pause before dislpay of the reward ~~~
                BigCircle.frameCurrentColor = BigCircle.frameBaseColor;
                Target.frameCurrentColor = Target.frameBaseColor;
                Cursor.diskCurrentColor  =  Cursor.diskBaseColor;
                Cursor.frameCurrentColor =  Cursor.frameBaseColor;
                stepPausePostMotor = 1;
                counter_step_pause_postMotor = 0;

                while stepPausePostMotor

                    counter_step_pause_postMotor = counter_step_pause_postMotor + 1;

                    BigCircle.Draw
                    Cross.Draw
                    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))

                    Screen('DrawingFinished',S.PTB.wPtr);
                    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
                    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])

                    % Record trial onset & step onset
                    if counter_step_pause_postMotor == 1
                        %RR.AddEvent({['PausePreReward__' EP.Data{evt,1}] lastFlipOnset-StartTime [] EP.Data{evt,4} EP.Data{evt,5} EP.Data{evt,6} EP.Data{evt,7} EP.Data{evt,8} EP.Data{evt,9}})
                        RR.AddEvent([{['PausePreReward__' EP.Data{evt,1}] lastFlipOnset-StartTime []} EP.Data(evt,4:end) ]);
                        step5onset = lastFlipOnset;
                        Common.SendParPortMessage( 'PausePreReward' )
                    end

                    if lastFlipOnset >= step5onset + Parameters.PausePostMotor
                        stepPausePostMotor = 0;
                    end

                   % Check if ESCAPE 
                    [ EXIT, StopTime ] = Common.Interrupt(ER,RR,StartTime);
                    if EXIT
                        break
                    end

                end % while : step 5
                BigCircle.frameCurrentColor = BigCircle.frameBaseColor;

                if EXIT
                    break
                end


            otherwise % ---------------------------------------------------

                error('unknown envent')

        end % switch

        % This flag comes from Common.Interrupt, if ESCAPE is pressed
        if EXIT
            break
        end

    end % for

    % "The end"
    BigCircle.Draw
    Cross.Draw
    ADAPT.UpdateCursor(Cursor, EP.Get('Deviation',evt))
    Screen('DrawingFinished',S.PTB.wPtr);
    lastFlipOnset = Screen('Flip',S.PTB.wPtr);
    SR.AddSample([lastFlipOnset-StartTime Cursor.X Cursor.Y Cursor.R Cursor.Theta])


    %% End of stimulation

    TaskData = Common.EndOfStimulation( TaskData, EP,ER, RR, KL, SR, StartTime, StopTime );
    TaskData.Parameters = Parameters;

    OutRecorder.ClearEmptySamples;
    InRecorder. ClearEmptySamples;
    TaskData.OutRecorder = OutRecorder;
    TaskData.InRecorder  = InRecorder;
    assignin('base','OutRecorder', OutRecorder)
    assignin('base','InRecorder' , InRecorder )

    TaskData.TargetBigCirclePosition = TargetBigCirclePosition;

catch err

    Common.Catch( err );

end

end % function

