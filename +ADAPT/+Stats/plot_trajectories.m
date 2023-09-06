function plot_trajectories( S )


%% Shortcut

data = S.Stats.global_AUC_inBlock;

Paradigm = S.TaskData.Parameters.Paradigm;

%% Plot

figure('Name','Plot Y(X) in untilted referiential (like target=0°)', 'NumberTitle','off');
nAxes = 3;
ax = zeros(nAxes,1);

for a = 1:nAxes
    ax(a) = subplot(nAxes,1,a);
    hold(ax(a),'all');
end

for block = 1 :size(Paradigm,1)
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
    
    if ~isfield(data,name)
        continue
    end
    
    NrTrials = length(data.(name).Trials);
    colors = jet(NrTrials);
    
    for trial = 1 : NrTrials
        plot( ax(block), data.(name).Trials(trial).xy(:,1), data.(name).Trials(trial).xy(:,2), 'Color', colors(trial,:) )
    end % trial
    
    % ideal trajectorty
    plot( ax(block), [0 data.(name).Trials(trial).targetPx], [0 0], 'k', 'LineWidth', 2, 'DisplayName', 'optimal' );
    
    axis  (ax(block),'tight')
    % legend(ax(a),'show')
    xlabel(ax(block),'X (pixels)')
    ylabel(ax(block),'Y (pixels)')
    title (ax(block),name,'Interpreter','none')
    
end % block

linkaxes(ax,'xy')
% ScaleAxisLimits(ax(1))


end % function
