function pop_eventinfo(EEG)
    eventFields = fieldnames(EEG.event);
    rowCount = 1;
    for i=1:length(eventFields)
        if ~strcmp(eventFields{i}, 'latency')
            data{rowCount,1} = eventFields{i};
            if strcmp(eventFields{i}, 'type')
                data{rowCount,2} = 'value';
            elseif strcmp(eventFields{i}, 'usertags')
                data{rowCount,2} = 'HED';
            else
                data{rowCount,2} = '';
            end
            rowCount = rowCount + 1;
        end
    end
    f = figure;
    bidsFields = uitable(f, 'Data', data, 'ColumnName', { 'EEG.event field' 'BIDS field'}, 'RowName', [], 'unit', 'normalized', 'position', [0 0 1 1],'ColumnEditable', [false true], 'Tag', 'bidsFields');
    selectBtn = uicontrol(f, 'Style', 'pushbutton', 'String', 'Confirm', 'Position', [165 350 150 50], 'Callback', @confirmCallback); 
%     eInfoDesc.onset.Description = 'Event onset';
%     eInfoDesc.onset.Units = 'second';
%     eInfoDesc.duration.Description = 'Event duration';
%     eInfoDesc.duration.Units = 'second';
%     eInfoDesc.trial_type.Description = 'Type of event';
%     eInfoDesc.trial_type.Levels.wait = 'The instruction is to wait until the experiment starts';
%     eInfoDesc.trial_type.Levels.relax = 'The instruction is to relax';
%     eInfoDesc.trial_type.Levels.getready = 'The instruction is to get ready as the trial is about to start';
%     eInfoDesc.trial_type.Levels.concentrate = 'The instruction is to concentrate on the target';
%     eInfoDesc.response_time.Description = 'Response time column not use for this data';
%     %eInfoDesc.sample.Description = 'Event sample starting at 0 (Matlab convention starting at 1)';
%     eInfoDesc.value.Description = 'Original trial value';
%     eInfoDesc.second_after_ready.Description = 'Number of second after the instruction to get ready';
% 
%     allfields = fieldnames(eInfoDesc);
%     geometry  = {};
%     uilist    = {};
%     for index = 1:length(allfields)
%         if isfield(eInfoDesc.(allfields{index}), 'Units')
%             units = eInfoDesc.(allfields{index}).Units;
%         else
%             units = '';
%         end
%         if isfield(eInfoDesc.(allfields{index}), 'Levels')
%             levels = eInfoDesc.(allfields{index}).Levels;
%             levels = sprintf('%d levels', length(levels));
%         else
%             levels = '';
%         end
%         if isfield(eInfoDesc.(allfields{index}), 'Description')
%             description = eInfoDesc.(allfields{index}).Description;
%             if length(description) > 30,
%                 description = [ description(1:27) '...' ];
%             end
%         else
%             description = '';
%         end
% 
%         tableVals{index,1} = units;
%         tableVals{index,2} = levels;
%         tableVals{index,3} = description;
% 
%     %     geometry = { geometry{:} [2 1 1 3 0.5] };
%     %     uilist   = { uilist{:}, ...
%     %         { 'Style', 'text', 'string', allfields{index} 'fontweight' 'bold' }, ...
%     %         { 'Style', 'text', 'string', units }, ...
%     %         { 'Style', 'text', 'string', levels }, ...
%     %         { 'Style', 'text', 'string', description }, ...
%     %         { 'Style', 'pushbutton', 'string', '...' } };
%     %            colnames = {'X-Data', 'Y-Data', 'Z-Data'};
%     %        t = uitable(f, 'Data', data, 'ColumnName', colnames, ...
%     %                    'Position', [20 20 260 100]);
%     end
%     

    
    function confirmCallback(src, event)
        bidsTable = findobj('Tag','bidsFields');
        bidsTable.Enable = 'inactive';
        input = {bidsTable.Data{:,2}};
        fields = {};
        for j=1:length(input)
            if ~isempty(input{j})
                fields = [fields input{j}];
            end
        end
        h = uitable(f, 'Data', cell(length(fields), 5),'ColumnName', { 'LongName' 'Description' 'Levels' 'Units' 'TermURL' }, 'RowName', fields,'ColumnEditable',true);
    end
    %                    'Position', [20 20 260 100]);
    %inputgui( geometry, uilist, 'pophelp(''pop_editeventvals'');', 'Edit event values -- pop_editeventvals()', {}, 'plot');
end