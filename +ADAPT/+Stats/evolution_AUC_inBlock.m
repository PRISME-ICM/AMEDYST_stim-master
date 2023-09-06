function [ output ] = evolution_AUC_inBlock
global S

output = struct;


%% Shortcut

data     = S.TaskData.OutRecorder.Data;
samples  = S.TaskData.SR         .Data;
targetPx = S.TaskData.TargetBigCirclePosition;
NrAngles = length(S.TaskData.Parameters.TargetAngles);
Paradigm = S.TaskData.Parameters.Paradigm;
%% Make stats for each block

for block = 1 : size(Paradigm,1)
     name  = [Paradigm{block,1} '_' num2str(block)];
    % Block name
%     switch block
%         case 1
%             name = 'Direct__Pre';
%         case 2
%             name = 'Deviation';
%         case 3
%             name = 'No_vision';
%         otherwise
%             error('block ?')
%     end % switch
    
    % Fetch data in the current block
    block_idx     = find(data(:,1)==block);
    data_in_block = data( block_idx , : );
    
    % Adjust number of chunks if necessary, be thow a warning
    NrChunks = size(data_in_block,1)/NrAngles;
    if NrChunks ~= round(NrChunks)
        warning('chunk error : not an integer, in block #%d', block)
    end
    NrChunks = floor(NrChunks);
    
    s = struct;
    chunk_idx = cell(NrChunks,1);
    
    
    for  chunk = 1 : NrChunks
        
        chunk_idx{chunk} = NrAngles * (chunk-1) + 1   :   NrAngles * chunk;
        data_in_chunk = data_in_block(chunk_idx{chunk},:);
        
        for trial = 1 : NrAngles
            
            frame_start = data_in_chunk(trial,7);
            frame_stop  = data_in_chunk(trial,8);
            
            xy = samples(frame_start:frame_stop,2:3);
            % target angle in radians:
            angle = data_in_chunk(trial,6)*pi/180; % degree to rad
            rotation_matrix = [cos(angle) -sin(angle); sin(angle) cos(angle)];
            xy = xy*rotation_matrix; % change referential
            % xy = xy/targetY; % normalize
            
           % KND:  Signed AUC 
            signed_auc = trapz(xy(:,1),xy(:,2));
            auc = abs(signed_auc);
            
            s.Chunk(chunk).Trials(trial).idx         = data_in_chunk(trial,2);
            s.Chunk(chunk).Trials(trial).frame_start = frame_start;
            s.Chunk(chunk).Trials(trial).frame_stop  = frame_stop;
            s.Chunk(chunk).Trials(trial).xy          = xy;
            s.Chunk(chunk).Trials(trial).deviation   = data_in_chunk(trial,4);
            s.Chunk(chunk).Trials(trial).value       = data_in_chunk(trial,5);
            s.Chunk(chunk).Trials(trial).target      = data_in_chunk(trial,6);
            s.Chunk(chunk).Trials(trial).targetPx    = targetPx;
            s.Chunk(chunk).Trials(trial).auc         = auc;
            
            s.Chunk(chunk).auc(trial) = auc;

            % KND : Save SIGNED AUC
            s.Chunk(chunk).Trials(trial).signed_auc         = signed_auc;

            % KND: Peak Velocity
            [ s.Chunk(chunk).Trials(trial).peak_Velocity.value , s.Chunk(chunk).Trials(trial).peak_Velocity.sample ] = max(sum(diff(xy,1,1).^2,2));


        end % trial
        
        s.Chunk(chunk).idx     = chunk_idx{chunk};
        s.Chunk(chunk).AUCmean = nanmean(s.Chunk(chunk).auc);
        s.Chunk(chunk).AUCstd  = nanstd (s.Chunk(chunk).auc);
        
    end % chunk
    
    output.(name) = s;
    
end % block

output.content = mfilename;


end % function
