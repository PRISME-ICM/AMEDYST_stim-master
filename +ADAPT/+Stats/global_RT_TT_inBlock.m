function [ output ] = global_RT_TT_inBlock

global S
output = struct;
%% Shortcut
data = S.TaskData.OutRecorder.Data;
Paradigm = S.TaskData.Parameters.Paradigm;

%% Make stats for each block

for block = 1 : size(Paradigm,1)
     name  = [Paradigm{block,1} '_' num2str(block)];
    
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
    
    fprintf('RT in block ''%s'': Mean = %g ms ; STD = %g\n', name, round(RTmean), round(RTstd));
    fprintf('TT in block ''%s'': Mean = %g ms ; STD = %g\n', name, round(TTmean), round(TTstd));
    
end % block

output.content = mfilename;

end % function
