% eeg_eventstatistics() - generate report of event types and statistics of their
%                      appearance across dataset. Return a report structure
%                      and can also write report into a tab separated file
%                      if specified
%
% Usage:
%        >> report = eeg_eventstatistics(inDir);
%        >> report = eeg_eventstatistics(inDir, 'key', 'val');
% Inputs:
%        inDir       - path to directory containing EEGLAB .set files
%
% Optional input keys:
%   'doSubDirs'      - ['boolean'] If true (default) the entire inDir directory tree is
%                      searched. If false only the inDir directory is searched.
%   'writeToFile'    - ['boolean'] if true write report into a tab-separated-value (tsv) file. Default false
%   'filepath'       - ['string'] path to directory where tsv report will be.
%                      Specify if want to write report into a tsv file. Default current directory
% Outputs:
%        report      - struct containing report of event diagnostic
%
% Author: Dung Truong, SCCN/UCSD, May 8, 2019
% Example:
%        >> report = eventdiagnostics('path_to_eeg_dir');
%        >> report = eventdiagnostics('path_to_eeg_dir','writeToFile','true');
% Log:
%       5/8/2019: First version
%       5/31/2019: Add subject count
function report = eeg_eventstatistics(fPaths, varargin)

%% Parse input arguments
if nargin < 1
    help eventdstatistic
    return;
else
    g = finputcheck(varargin,...
                    {'doSubDirs'    'boolean'   [0,1]   1;
                     'writeToFile'  'boolean'   [0,1]   0;
                     'filepath'     'string'    []      './'});
end
%% Get path of all .set files
%fPaths = getfilelist(inDir, '.set', g.doSubDirs);
if isempty(fPaths)
    warning('badcode_report:nofiles', 'No .set file found\n');
    return;
end
%% Load datasets
ALLEEG = pop_loadset('filename',fPaths,'loadmode','info','check','off');

%% generate report fields
types_all = []; % array containing all event type codes for all dataset
numbers_all = []; % array containing count of appearance of all event code for each dataset
type_fileIdx = containers.Map; % map of event type and list of file index the event appeared in
for i=1:numel(ALLEEG)
    [types, numbers] = eeg_eventtypes(ALLEEG(i));
    types_all = [types_all(:); types(:)];
    numbers_all = [numbers_all(:); numbers(:)]; 
    
    for j=1:numel(types)
        if isKey(type_fileIdx,types{j})
            type_fileIdx(types{j}) = [type_fileIdx(types{j}(:)) i];
        else
            type_fileIdx(types{j}) = [i];
        end
    end
end

%% write report
types_unique = unique(types_all);
ntype = numel(types_unique);
fidReport = -1;
filelist = cell(numel(ALLEEG),1);
for i=1:numel(ALLEEG)
    filelist{i} = [ALLEEG(i).filepath '/' ALLEEG(i).filename];
end
if g.writeToFile
    try
        fidReport = fopen([g.filepath 'EventStatistic.tsv'],'w');
        fidFileList = fopen([g.filepath 'FileList.tsv'],'w');
        fprintf(fidReport,'EventType\tAppearedInCount\tAbsentFromCount\tSumNum\tMaxNum\tMinNum\tMeanNum\tAppearedIn\tAbsentFrom\tAppearedInSubjCount\tAbsentFromSubjCount\tAppearedInSubj\tAbsentFromSubj\n');
        fprintf(fidFileList,'Index\tFile Name\n');
        for i=1:numel(ALLEEG)
            fprintf(fidFileList,'%d\t%s\n',i,filelist{i});
        end
        fclose(fidFileList);
    catch ME
        error(['' ME.identifier]);
    end
end

report = [];
report.filelist = filelist;
report.nfile = numel(ALLEEG);
eventtype = [];
for i=1:ntype
    typename = types_unique{i};
    number = numbers_all(strcmp(types_all,typename)); % types_all corresponds to numbers_all
    appearedInIdx = type_fileIdx(typename);
    absentFromIdx = setdiff(1:numel(ALLEEG),appearedInIdx);

    type = [];
    type.name = typename;
    type.appearedInCount    = numel(appearedInIdx);
    type.absentFromCount    = numel(absentFromIdx);
    type.sumNum             = sum(number);
    type.maxNum             = max(number);
    type.minNum             = min(number);
    type.roundedMeanNum     = round(mean(number));
    if numel(appearedInIdx) == numel(ALLEEG)
        type.appearedIn = inf;
        type.absentFrom = 0;
    elseif numel(absentFromIdx) == numel(ALLEEG)
        type.appearedIn = 0;
        type.absentFrom = inf;
    elseif numel(appearedInIdx) >= numel(absentFromIdx)
        type.appearedIn = nan;
        type.absentFrom = absentFromIdx;
    else
        type.appearedIn = appearedInIdx;
        type.absentFrom = nan;
    end
    
    % subject occurences count
    subj_all = unique({ALLEEG.subject});
    temp = {ALLEEG(appearedInIdx).subject}; % list of subjects the event type appeared in, duplicate allowed
    subjAppearedIn = unique(temp); % list of Unique subjects the event type appeared in
    subjAbsentFrom = setdiff(subj_all,subjAppearedIn);
    if isempty(find(strcmp(subjAppearedIn,''),1)) % if there's NO empty subject value --> all dataset have subject info
        type.appearedInSubjCount = numel(subjAppearedIn);
        type.absentFromSubjCount = numel(subjAbsentFrom);
        if numel(subjAppearedIn) == numel(subj_all)
            type.appearedInSubj = inf;
            type.absentFromSubj = 0;
        elseif numel(subjAbsentFrom) == numel(subj_all)
            type.appearedInSubj = 0;
            type.absentFromSubj = inf;
        elseif numel(subjAppearedIn) >= numel(subjAbsentFrom)
            type.appearedInSubj = nan;
            type.absentFromSubj = subjAbsentFrom;
        else
            type.appearedInSubj = subjAppearedIn;
            type.absentFromSubj = nan;
        end
    else
        type.appearedInSubjCount = nan;
        type.absentFromSubjCount = nan;
        type.appearedInSubj = nan;
        type.absentFromSubj = nan;
    end
    
    % if write to file option ON
    if g.writeToFile
        % correspond to fprintf(fidReport,'EventType\tAppearedInCount\tAbsentFromCount\tSumNum\tMaxNum\tMinNum\tMeanNum\t');
        fprintf(fidReport,'%s\t%d\t%d\t%d\t%d\t%d\t%.2f\t',typename,numel(appearedInIdx),numel(absentFromIdx),sum(number),max(number),min(number),mean(number));
        % AppearedIn\tAbsentFrom\t
        if numel(appearedInIdx) == numel(ALLEEG)
            fprintf(fidReport,'Inf\t0\t');
        elseif numel(absentFromIdx) == numel(ALLEEG)
            fprintf(fidReport,'0\tInf\t');
        elseif numel(appearedInIdx) >= numel(absentFromIdx)
            fprintf(fidReport,'NaN\t%s\t',num2str(absentFromIdx,'%d,'));
        else
            fprintf(fidReport,'%s\tNaN\t',num2str(appearedInIdx,'%d,'));
        end 
        % AppearedInSubjCount\tAbsentFromSubjCount\tAppearedInSubj\tAbsentFromSubj
        if isempty(find(strcmp(subjAppearedIn,''),1)) % if there's NO empty subject value --> all dataset have subject info
            fprintf(fidReport,'%d\t%d\t',numel(subjAppearedIn),numel(subjAbsentFrom));
            if numel(subjAppearedIn) == numel(subj_all)
                fprintf(fidReport,'Inf\t0\n');
            elseif numel(subjAbsentFrom) == numel(subj_all)
                fprintf(fidReport,'0\tInf\n');
            elseif numel(subjAppearedIn) >= numel(subjAbsentFrom)
                fprintf(fidReport,'NaN\t%s\n',num2str(subjAbsentFrom,'%d,'));
            else
                fprintf(fidReport,'%s\tNaN\n',num2str(subjAppearedIn,'%d,'));
            end
        else
            fprintf(fidReport,'NaN\tNaN\tNaN\tNaN\n');
        end
    end
    eventtype = [eventtype(:);type];
end
report.eventtype = eventtype;

if g.writeToFile
    fclose(fidReport);
end

end
