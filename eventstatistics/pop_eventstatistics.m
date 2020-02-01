function pop_eventstatistics(path)
    report = eeg_eventstatistics(path);
    T = struct2table(report.eventtype);
    variables = T.Properties.VariableNames;
    colIdx = [find(strcmp(variables,'appearedIn')) find(strcmp(variables,'absentFrom')) find(strcmp(variables,'appearedInSubj')) find(strcmp(variables,'absentFromSubj'))];
    for i=colIdx
        col = T{:,i};
        if ~isa(col,'double')
            newCol = cellfun(@(x) num2str(x),col,'UniformOutput',false);
            T{:,i} = newCol;
        end
    end
    f = uifigure('Position',[300 1000 1000 500],'Name','Event Statistic Report');
    uit = uitable(f,'Position', [25 25 950 450],'Data',T);
    supergui(
    filelistStruct = [];
    filelistStruct.Index = [1:numel(report.filelist)]';
    filelistStruct.Filepath  = report.filelist;
    T2 = struct2table(filelistStruct);
    f2 = uifigure('Name','File List');
    uit2 = uitable(f2,'Position', [25 20 500 380],'Data',T2);
end

