function [ output ] = evolution_RT_TT_AUC_inRewardChance
global S


%% Shortcut

gloAU = S.Stats.global_AUC_inBlock;
% Values = floor(sort(S.TaskData.Parameters.Values));

Paradigm = S.TaskData.Parameters.Paradigm;


%% Extract data

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
    
    if ~isfield(gloAU,name)
        continue
    end
    
    values_in_block = floor([gloAU.(name).Trials.value]);
    [Values,~,trial2value] = unique(values_in_block);
    Values = floor(Values);
    
    s = struct;
    for value_idx = 1 : length(Values)
        s.Values(value_idx).value   = Values(value_idx);
        s.Values(value_idx).idx     = find(trial2value==value_idx);
        s.Values(value_idx).RT      = [gloAU.(name).Trials(s.Values(value_idx).idx).RT ];
        s.Values(value_idx).RTmean  = nanmean(s.Values(value_idx).RT);
        s.Values(value_idx).RTstd   = nanstd (s.Values(value_idx).RT);
        s.Values(value_idx).TT      = [gloAU.(name).Trials(s.Values(value_idx).idx).TT ];
        s.Values(value_idx).TTmean  = nanmean(s.Values(value_idx).TT);
        s.Values(value_idx).TTstd   = nanstd (s.Values(value_idx).TT);
        s.Values(value_idx).AUC     = [gloAU.(name).Trials(s.Values(value_idx).idx).auc];
        s.Values(value_idx).AUCmean = nanmean(s.Values(value_idx).AUC);
        s.Values(value_idx).AUCstd  = nanstd (s.Values(value_idx).AUC);
    end
    output.(name) = s;
    
end % block

output.content = mfilename;


end % function
