function [ output ] = evolution_RT_TT_inBlock
global S

output = struct;


%% Shortcut

data = S.TaskData.OutRecorder.Data;
NrAngles = length(S.TaskData.Parameters.TargetAngles);
Paradigm = S.TaskData.Parameters.Paradigm;

%% Make stats for each chucnk of NrAngles

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
    
    % Pre-allocation
    RTmean = zeros(1,NrChunks);
    RTstd  = RTmean;
    TTmean = RTmean;
    TTstd  = RTmean;
    
    chunk_idx = cell(NrChunks,1);
    
    for chunk = 1 : NrChunks
        
        chunk_idx{chunk} = NrAngles * (chunk-1) + 1   :   NrAngles * chunk;
        
        RTmean(chunk) = nanmean(data_in_block(chunk_idx{chunk},9));
        RTstd (chunk) =  nanstd(data_in_block(chunk_idx{chunk},9));
        
        TTmean(chunk) = nanmean(data_in_block(chunk_idx{chunk},10));
        TTstd (chunk) =  nanstd(data_in_block(chunk_idx{chunk},10));
        
    end % chunk
    
    s = struct;
    s.RTmean = RTmean;
    s.RTstd  = RTstd ;
    s.TTmean = TTmean;
    s.TTstd  = TTstd ;
    s.block_index = block_idx;
    s.chunk_idx   = chunk_idx;
    
    output.(name)  = s;
    
    
end % block

output.content = mfilename;


end % function
