function [ output ] = global_RT_TT_inBlock
global S

output = struct;


%% Shortcut

data = S.TaskData.OutRecorder.Data;
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
%             name = 'Direct__Post';
%         otherwise
%             error('block ?')
%     end % switch
    
    % Fetch data in the current block
    block_idx     = find(data(:,1)==block);
    data_in_block = data( block_idx , : );
    
    RTmean = nanmean(data_in_block(:,9));
    RTstd  =  nanstd(data_in_block(:,9));
    
    TTmean = nanmean(data_in_block(:,10));
    TTstd  =  nanstd(data_in_block(:,10));
    
    s = struct;
    s.RTmean = RTmean;
    s.RTstd  = RTstd ;
    s.TTmean = TTmean;
    s.TTstd  = TTstd ;
    s.block_index = block_idx;
    
    output.(name)  = s;
    
    fprintf('mean RT in block ''%s'' = %g ms \n', name, round(RTmean))
    fprintf('std  RT in block ''%s'' = %g ms \n', name, round(RTstd ))
    fprintf('mean TT in block ''%s'' = %g ms \n', name, round(TTmean))
    fprintf('std  TT in block ''%s'' = %g ms \n', name, round(TTstd ))
    
end % block

output.content = mfilename;


end % function
