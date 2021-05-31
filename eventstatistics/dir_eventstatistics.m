function report = dir_eventstatistics(inDir, varargin)

%% Parse input arguments
if nargin < 1
    help dir_eventstatistics
    return;
else
    g = finputcheck(varargin,...
                    {'doSubDirs'    'boolean'   [0,1]   1;
                     'writeToFile'  'boolean'   [0,1]   0;
                     'filepath'     'string'    []      './';
                     'pattern'      'string'    []      ''});
end
if isempty(inDir)
    error("Empty path provided"); 
else
    fPaths = getfilelist(inDir, '.set', g.pattern, g.doSubDirs);
    report = eeg_eventstatistics(fPaths, varargin{:});
   
end
% Gets a list of the files in a directory tree.
% Usage:
%   >>  fPaths = getfilelist(inDir, fileExt, doSubDirs)
%
% Input:
%   Required:
%   inDir            The full path to a directory tree.
%   fileExt          The file extension of the files to search for in the
%                    inDir directory tree.
%   doSubDirs        If true (default) the entire inDir directory tree is
%                    searched. If false only the inDir directory is
%                    searched.
% Output:
%   fPaths           A one-dimensional cell array of full file names that
%                    have the file extension 'fileExt'.
%
% Copyright (C) 2012-2016 Thomas Rognon tcrognon@gmail.com,
% Jeremy Cockfield jeremy.cockfield@gmail.com, and
% Kay Robbins kay.robbins@utsa.edu
function fPaths = getfilelist(inDir, fileExt, pattern, doSubDirs)
fPaths = {};
directories = {inDir};
while ~isempty(directories)
    nextDir = directories{end};
    files = dir(nextDir);
    fileNames = {files.name}';
    fileDirs = cell2mat({files.isdir}');
    compareIndex = ~strcmp(fileNames, '.') & ~strcmp(fileNames, '..');
    subDirs = strcat([nextDir filesep], fileNames(compareIndex & fileDirs));
    fileNames = fileNames(compareIndex & ~fileDirs);
    if nargin > 1 && ~isempty(fileExt) && ~isempty(fileNames)
        fileNames = processExts(fileNames, fileExt);
    end
    fileNames = strcat([nextDir filesep], fileNames);
    directories = [directories(1:end-1); subDirs(:)];
    if ~isempty(pattern) && ~isempty(fileNames)
        matched = cellfun(@(x) ~isempty(x),regexp(fileNames,pattern));
        fPaths = [fPaths(:); fileNames(matched)];
    else
        fPaths = [fPaths(:); fileNames(:)];
    end
    if nargin > 2 && ~doSubDirs
        break;
    end
end

    function fileNames = processExts(fileNames, fileExt)
        % Return a cell array of file names with the specified file extension
        fExts = cell(length(fileNames), 1);
        for k = 1:length(fileNames)
            [x, y, fExts{k}] = fileparts(fileNames{k}); %#ok<ASGLU>
        end
        matches = strcmp(fExts, fileExt);
        fileNames = fileNames(matches);
    end % processExts

end % getfilelist
end