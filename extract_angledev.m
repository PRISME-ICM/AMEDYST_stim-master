
% x = 1;
% y = 4;
% 
% 
% for rep = 1:(size(OutRecorder.Data(:,11),1)/4)
% 
%     angle_dev(1,rep) = nanmean(OutRecorder.Data(x:y,11),1);
% 
%     x = x+4
%     y = y+4
%   
% 
% end
% % angle_dev = angle_dev';
% 
% figure;
% scatter([1:rep],angle_dev)
% hold on 
% xline([12,24,36,72], '-', 'LineWidth', 2)
% xline([48,60,84,96], '--', 'LineWidth', 2)
% ylim([0,20])
% xlim([0,108])
% 
%% all participants independent of the feedback
clear all
close all 

mainpath = ('C:\Users\martina.bracco\OneDrive - ICM\Documents\Projects\FORTE\Task_new2\data\')
cd(mainpath)

for nsub = [4, 5, 11:14];
    if nsub <= 9;
subfolder = ([mainpath,'0',num2str(nsub)])
    else 
subfolder = ([mainpath,num2str(nsub)])
    end

file = '*.mat';
filePattern = fullfile(subfolder, file);
theFiles = dir(filePattern);

 k = 1; % do not load the SPM file
 baseFileName = theFiles(k).name;
 fullFileName = fullfile(subfolder,baseFileName);
 fprintf(1, 'Now reading %s\n', fullFileName);
 load(fullFileName)

for tr = 1:(size(S.TaskData.OutRecorder.Data(:,11),1))
    if S.TaskData.OutRecorder.Data(tr,13) == 1
        tmp_angle(tr,1) = NaN;
        tmp_points(tr,1) = NaN;
    else
        tmp_angle(tr,1) = S.TaskData.OutRecorder.Data(tr,11);
        if S.TaskData.OutRecorder.Data(tr,5) == 1
        tmp_points(tr,1) = S.TaskData.OutRecorder.Data(tr,12);
        else 
        tmp_points(tr,1) = NaN;  
        end
    end
end

total_points(nsub) = nansum(tmp_points,1);

x = 1;
y = 4;

for rep = 1:(size(tmp_angle,1)/4)

    angle_dev(nsub,rep) = nanmean(tmp_angle(x:y,1),1);
  
    x = x+4
    y = y+4
  

end


figure (nsub);
scatter([1:rep],angle_dev(nsub,:))
hold on 
xline([12,24,36,72], '-', 'LineWidth', 2)
xline([48,60,84,96], '--', 'LineWidth', 2)
ylim([0,20])
xlim([0,108])
end


angle_dev(11,[97:108])= NaN;

%% REWARD

nsub_rew = [4,11,12];
avg_angle_rew = nanmean(angle_dev(nsub_rew,:),1);

figure (16);
plot([1:rep],avg_angle_rew,'Color','k','LineWidth',2)
hold on 
xline([12,24,36,72], '-', 'LineWidth', 2)
xline([48,60,84,96], '--', 'LineWidth', 2)
ylim([0,30])
xlim([0,108])


maximum = max(max(total_points(nsub_rew)));
[x,winner_rew]=find(total_points==maximum)

%% PUNISHMENT

nsub_pun = [5, 13,14];
avg_angle_pun = nanmean(angle_dev(nsub_pun,:),1);

figure (17);
plot([1:rep],avg_angle_pun,'Color','k','LineWidth',2)
hold on 
xline([12,24,36,72], '-', 'LineWidth', 2)
xline([48,60,84,96], '--', 'LineWidth', 2)
ylim([0,30])
xlim([0,108])


maximum = max(max(total_points(nsub_pun)));
[x,winner_pun]=find(total_points==maximum)

%% all

grayColor = [.7 .7 .7];

figure (18);
plot([13:rep],avg_angle_rew(13:end),'Color','r','LineWidth',2)
hold on
plot([13:rep],avg_angle_pun(13:end),'Color','k','LineWidth',2)
hold on 
xline([25,37,73], '-', 'Color', grayColor, 'LineWidth', 2)
xlabel('N trials (avg of 4 trials)')
xline([49,61,85,99], '--','Color', grayColor, 'LineWidth', 2)
ylabel('Error (degrees angle)')
ylim([-2,25])
xlim([13,108])


 


