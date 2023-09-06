function [csvfile] = trajectory_to_CSV(SR,EP,csvfile)
%   [csvfile] = trajectory_to_CSV(SR,EP,csvfile)
% Export trajectories to CSV
if nargin<3 
    csvfile='trajectory.csv';
end
if nargin==0
    SR=evalin('caller','SR');
    EP=evalin('caller','EP');
end
%csvfile=fullfile(S.DataPath,[S.DataFileName,'.csv']);

% SR = S.TaskData.SR;
t = array2table(SR.Data, 'VariableNames',SR.Header);
writetable(t,csvfile)

% KND: extra infos
% Trial Number
trial  = SR.