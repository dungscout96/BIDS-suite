% pop_eventinfo() - GUI for BIDS event info editing, generated based on
%                   fields of EEG.event
%
% Usage:
%   >> [eInfoDesc, eInfo] = pop_eventinfo( EEG );
%                                              
% Inputs:
%   EEG        - EEG dataset structure. May only contain one dataset.
%
% Outputs:
%  'eInfoDesc' - [struct] structure describing BIDS event fields as you specified.
%                See BIDS specification for all suggested fields.
%
%  'eInfo'     - [cell] BIDS event fields and their corresponding
%                event fields in the EEGLAB event structure. Note that
%                EEGLAB event latency, duration, and type are inserted
%                automatically as columns "onset" (latency in sec), "duration"
%                (duration in sec), "value" (EEGLAB event type)
%
% Author: Dung Truong, Arnaud Delorme
function [EEG, eInfoDesc, eInfo] = pop_eventinfo(EEG)
    % default settings
    appWidth = 800;
    appHeight = 500;
    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    levelThreshold = 20;
    fontSize = 12;
    eventBIDS = newEventBIDS();
    columnDefinition.LongName = 'Long, unabbreviated name of the field';
    columnDefinition.Description = 'Description of the field';
    columnDefinition.Levels = 'For categorical variables: possible values and their descriptions';
    columnDefinition.Units = 'Measurement units - format [<prefix>]<name>';
    columnDefinition.TermURL = 'URL pointing to a formal definition of this type of data in an ontology available on the web';
    
    eInfo = {};
    eInfoDesc = [];
    
    % create UI
    eventFields = fieldnames(EEG.event);
    f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'Edit BIDS event info - pop_eventinfo', 'Color', bg);
    f.Position(3) = appWidth;
    f.Position(4) = appHeight;
    uicontrol(f, 'Style', 'text', 'String', 'BIDS information for EEG.event fields', 'Units', 'normalized','FontWeight','bold','ForegroundColor', fg,'BackgroundColor', bg, 'Position', [0 0.9 1 0.1]);
    tbl = uitable(f, 'RowName', eventFields, 'ColumnName', { 'BIDS Field' 'Levels' 'LongName' 'Description' 'Unit Name' 'Unit Prefix' 'TermURL' }, 'Units', 'normalized', 'FontSize', fontSize, 'Tag', 'bidsTable');
    tbl.Position = [0.01 0.54 0.98 0.41];
    tbl.CellSelectionCallback = @cellSelectedCB;
    tbl.CellEditCallback = @cellEditCB;
    tbl.ColumnEditable = [true false true true true true];
    tbl.ColumnWidth = {appWidth/9,appWidth/9,appWidth*2/9,appWidth*2/9,appWidth/9,appWidth/9,appWidth/9};
    unitPrefixes = {' ','deci','centi','milli','micro','nano','pico','femto','atto','zepto','yocto','deca','hecto','kilo','mega','giga','tera','peta','exa','zetta','yotta'};
    tbl.ColumnFormat = {[] [] [] [] [] unitPrefixes []};
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'Units', 'normalized', 'Position', [0.85 0 0.1 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.7 0 0.1 0.05], 'Callback', @cancelCB); 
    
    % pre-populate table
    data = cell(length(eventFields),6);
    for i=1:length(eventFields)
        if strcmp(eventFields{i}, 'type') || strcmp(eventFields{i}, 'latency') || strcmp(eventFields{i}, 'usertags')
            data{i,1} = eventBIDS.(eventFields{i}).BIDSField;   
            data{i,find(strcmp(tbl.ColumnName, 'LongName'))} = eventBIDS.(eventFields{i}).LongName;
            data{i,find(strcmp(tbl.ColumnName, 'Description'))} = eventBIDS.(eventFields{i}).Description;
            data{i,find(strcmp(tbl.ColumnName, 'Levels'))} = eventBIDS.(eventFields{i}).Levels;
            data{i,find(strcmp(tbl.ColumnName, 'Unit Name'))} = eventBIDS.(eventFields{i}).Units;
        end
    end
    tbl.Data = data;
    waitfor(f);
  
    function cancelCB(src, event)
        clear('eventBIDS');
        close(f);
    end
    function okCB(src, event)
        % duration field is automatically calculated by EEGLAB
        eInfoDesc.duration.LongName = 'Event duration';
        eInfoDesc.duration.Description = 'Duration of the event (measured from onset) in seconds';
        eInfoDesc.duration.Units = 'second';
        
        % prepare return struct
        fields = fieldnames(eventBIDS);
        for idx=1:length(fields)
            eegField = fields{idx};
            bidsField = eventBIDS.(eegField).BIDSField;
            if ~isempty(bidsField)
                eInfo = [eInfo; {bidsField eegField}]; 
                
%                 eInfoDesc.(bidsField).EEGField = eegField;
                if ~isempty(eventBIDS.(eegField).LongName)
                    eInfoDesc.(bidsField).LongName = eventBIDS.(eegField).LongName;
                end
                if ~isempty(eventBIDS.(eegField).Description)
                    eInfoDesc.(bidsField).Description = eventBIDS.(eegField).Description;
                end
                if ~isempty(eventBIDS.(eegField).Units)
                    eInfoDesc.(bidsField).Units = eventBIDS.(eegField).Units;
                end
                if ~isempty(eventBIDS.(eegField).Levels)
                    eInfoDesc.(bidsField).Levels = eventBIDS.(eegField).Levels;
                end
                if ~isempty(eventBIDS.(eegField).TermURL)
                    eInfoDesc.(bidsField).TermURL = eventBIDS.(eegField).TermURL;
                end
            end
        end
        
        EEG.BIDS.eInfoDesc = eInfoDesc;
        EEG.BIDS.eInfo = eInfo;
        clear('eventBIDS');
        close(f);
    end

    function cellEditCB(arg1, obj)
        field = obj.Source.RowName{obj.Indices(1)};
        column = obj.Source.ColumnName{obj.Indices(2)};
        if ~strcmp(column, 'Levels')
            if strcmp(column, 'BIDS Field')
                otherBIDSFieldsIdx = setdiff(1:size(obj.Source.Data,1),obj.Indices(1));
                curBIDSFields = {obj.Source.Data{otherBIDSFieldsIdx,obj.Indices(2)}};
                if any(strcmp(obj.EditData, curBIDSFields)) % check for duplication of BIDS field
                    obj.Source.Data{obj.Indices(1),obj.Indices(2)} = obj.PreviousData; % reset if found
                else
                    eventBIDS.(field).BIDSField = obj.EditData;
                end
            elseif strcmp(column, 'Unit Name') || strcmp(column, 'Unit Prefix')
                unit = [obj.Source.Data{obj.Indices(1),find(strcmp(obj.Source.ColumnName, 'Unit Prefix'))} obj.Source.Data{obj.Indices(1),find(strcmp(obj.Source.ColumnName, 'Unit Name'))}];
                eventBIDS.(field).Units = unit;
            else
                eventBIDS.(field).(column) = obj.EditData;
            end
        end
    end
    function cellSelectedCB(arg1, obj) 
        if size(obj.Indices,1) == 1
            removeLevelUI();
            row = obj.Indices(1);
            col = obj.Indices(2);
            field = obj.Source.RowName{row};
            bfield = obj.Source.Data{row,1};
            columnName = obj.Source.ColumnName{col};
            
            if strcmp(columnName, 'BIDS Field')
                c6 = uicontrol(f, 'Style', 'text', 'String', sprintf('Enter BIDS field or choose one of the suggested below:'), 'Units', 'normalized', 'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'selectBIDSMsg');
                c6.Position = [0.01 0.38 1 0.05];
                c6.HorizontalAlignment = 'left';
                c = uicontrol(f,'Style','popupmenu', 'Units', 'normalized', 'Tag', 'selectBIDSDD');
                c.Position = [0.01 0.28 0.3 0.1];
                curBIDSFields = {obj.Source.Data{:,col}};
                c.String = setdiff({'onset', 'trial_type','value','stim_file','sample','HED','response_time'}, curBIDSFields(~cellfun(@isempty, curBIDSFields)));
                c.Callback = {@bidsFieldSelected, obj.Source, row, col};
            elseif strcmp(columnName, 'Levels')
                % retrieve all unique values from EEG.event.(field)
                    if isnumeric(EEG.event(1).(field))
                        values = arrayfun(@(x) num2str(x), [EEG.event.(field)], 'UniformOutput', false);
                        levels = unique(values)';
                    else
                        levels = unique({EEG.event.(field)})';
                    end
                    % create UI
                    if length(levels) <= levelThreshold 
                        createLevelUI('','',field,levels);   
                    else
                        msg = sprintf('\tThere are more than %d unique levels for field %s.\nAre you sure you want to specify levels for it?', levelThreshold, field);
                        c4 = uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'FontWeight', 'bold', 'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'confirmMsg');
                        c4.Position = [0 0.38 1 0.1];
                        c5 = uicontrol(f, 'Style', 'pushbutton', 'String', 'Yes', 'Units', 'normalized','Tag', 'confirmBtn', 'Callback', {@createLevelUI,field,levels});
                        c5.Position = [(1-c5.Extent(3))/2 0.33 0.1 0.05];
                    end
            else % any other column selected
                if isempty(bfield)
                    c6 = uicontrol(f, 'Style', 'text', 'String', sprintf('No BIDS name specified\nPlease remember to specify BIDS name for this field'), 'Units', 'normalized', 'FontWeight', 'bold', 'ForegroundColor', [0.9 0 0],'BackgroundColor', bg, 'Tag', 'noBidsMsg');
                    c6.Position = [0.01 0.38 1 0.1];
                    c6.HorizontalAlignment = 'Left';
                end
                if ~strcmp(columnName, 'BIDS Field')
                    % display cell content in lower panel
                    if strcmp(columnName, 'Unit Name') || strcmp(columnName, 'Unit Prefix')
                        columnName = 'Units';
                        content = [obj.Source.Data{row,find(strcmp(obj.Source.ColumnName, 'Unit Prefix'))} obj.Source.Data{row,find(strcmp(obj.Source.ColumnName, 'Unit Name'))}];
                    else
                        content = obj.Source.Data{row,col};
                    end
                    uicontrol(f, 'Style', 'text', 'String', sprintf('%s (%s):\n%s',columnName, columnDefinition.(columnName),content), 'Units', 'normalized', 'Position',[0.01 0.08 0.98 0.3], 'HorizontalAlignment', 'left','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'cellContentMsg');
                end
            end
        end
    end

    function createLevelUI(src,event,field,levels)
        removeLevelUI();
        
        if strcmp(field, 'usertags')
            uicontrol(f, 'Style', 'text', 'String', 'Levels editing not applied for HED. Use ''pop_tageeg(EEG)'' of HEDTools plug-in to edit event HED tags', 'Units', 'normalized', 'Position', [0.01 0.45 1 0.05],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
        else
            % build table data
            t = cell(length(levels),2);
            for lvl=1:length(levels)
                t{lvl,1} = levels{lvl};
                formattedLevel = checkFormat(levels{lvl}); % put level in the right format for indexing. Number is prepended by 'x'
                if ~isempty(eventBIDS.(field).Levels) && isfield(eventBIDS.(field).Levels, formattedLevel)
                    t{lvl,2} = eventBIDS.(field).Levels.(formattedLevel);
                end
            end
            % create UI
            uicontrol(f, 'Style', 'text', 'String', ['Describe the categorical values of EEG.event.' field], 'Units', 'normalized', 'HorizontalAlignment', 'left', 'Position', [0.31 0.45 0.7 0.05],'FontWeight', 'bold','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
            msg = 'BIDS allow you to describe the level for each of your categorical field. Describing levels help other researchers understand your experiment better';
            uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'HorizontalAlignment', 'Left','Position', [0.01 0 0.3 0.4],'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelMsg');
            h = uitable(f, 'Data', t, 'ColumnName', {'Level' 'Description'}, 'RowName', [], 'Units', 'normalized', 'Position', [0.31 0.07 0.68 0.38], 'FontSize', fontSize, 'Tag', 'levelEditTbl', 'CellEditCallback',{@levelEditCB,field},'ColumnEditable',[false true]); 
            h.ColumnWidth = {appWidth/5,appWidth*3/5};
        end
    end

    function levelEditCB(arg1, obj, field)
        level = checkFormat(obj.Source.Data{obj.Indices(1),1});
        description = obj.EditData;
        eventBIDS.(field).Levels.(level) = description;
    end
    
    function bidsFieldSelected(src, event, table, row, col) 
        val = src.Value;
        str = src.String;
        selected = str{val};
        table.Data{row,col} = selected;
        field = table.RowName{row};
        eventBIDS.(field).BIDSField = selected;
    end
    function formatted = checkFormat(str)
        if ~isempty(str2num(str))
            formatted = ['x' str];
        else
            formatted = str;
        end
    end
    function removeLevelUI()
        % remove old ui items of level section if exist
        h = findobj('Tag', 'levelEditMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'levelEditTbl');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'confirmMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'confirmBtn');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'noBidsMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'cellContentMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'selectBIDSMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'selectBIDSDD');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'levelMsg');
        if ~isempty(h)
            delete(h);
        end
    end
    function event = newEventBIDS()
        event = [];
        
        fields = fieldnames(EEG.event);
        for idx=1:length(fields)
            if strcmp(fields{idx}, 'type')
                event.type.BIDSField = 'value';
                event.type.LongName = 'Event marker';
                event.type.Description = 'Marker value associated with the event';
                event.type.Units = '';
                event.type.Levels = [];
                event.type.TermURL = '';
            elseif strcmp(fields{idx}, 'usertags')
                event.usertags.BIDSField = 'HED';
                event.usertags.LongName = 'Hierarchical Event Descriptor';
                event.usertags.Description = 'Tags describing the nature of the event';      
                event.usertags.Levels = [];
                event.usertags.Units = '';
                event.usertags.TermURL = '';
            elseif strcmp(fields{idx}, 'latency')
                event.latency.BIDSField = 'onset';
                event.latency.LongName = 'Event onset';
                event.latency.Description = 'Onset (in seconds) of the event measured from the beginning of the acquisition of the first volume in the corresponding task imaging data file';
                event.latency.Units = 'second';
                event.latency.Levels = [];
                event.latency.TermURL = '';
            else
                event.(fields{idx}).BIDSField = '';
                event.(fields{idx}).LongName = '';
                event.(fields{idx}).Description = '';
                event.(fields{idx}).Units = '';
                event.(fields{idx}).Levels = [];
                event.(fields{idx}).TermURL = '';
            end
        end
    end
end