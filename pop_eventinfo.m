% pop_eventinfo() - GUI for BIDS event info editing, generated based on
%                   fields of EEG.event
%
% Usage:
%   >> eventBIDS = pop_eventinfo( EEG );
%                                              
% Inputs:
%   EEG        - EEG dataset structure. May only contain one dataset.
%
% Outputs:
%   eventBIDS  - a struct containing BIDS event fields and their
%   information
%
% Author: Dung Truong, Arnaud Delorme
function pop_eventinfo(EEG)
    appWidth = 800;
    appHeight = 500;
    bg = [0.65 0.76 1];
    fg = [0 0 0.4];
    levelThreshold = 20;
    fontSize = 14;
    
    eventBIDS = newEventBIDS();
    eventFields = fieldnames(EEG.event);
    rowCount = 1;
    for i=1:length(eventFields)
        data{i,1} = eventFields{i};
        if strcmp(eventFields{i}, 'type')
            data{i,2} = 'value';
        elseif strcmp(eventFields{i}, 'usertags')
            data{i,2} = 'HED';
        elseif strcmp(eventFields{i}, 'latency')
            data{i,2} = 'onset';    
        else
            data{i,2} = '';
        end
    end
    f = figure('MenuBar', 'None', 'ToolBar', 'None', 'Name', 'Edit BIDS event info - pop_eventinfo', 'Color', bg);
    f.Position(3) = appWidth;
    f.Position(4) = appHeight;
    c1 = uicontrol(f, 'Style', 'text', 'String', 'EEG.event to BIDS mapping', 'Units', 'normalized','FontWeight','bold','ForegroundColor', fg,'BackgroundColor', bg);
    c1.Position = [0 0.9 0.24 0.1];
    bidsFields = uitable(f);
    bidsFields.Data = data;
    bidsFields.Units = 'normalized';
    bidsFields.Position = [0 0.22 0.24 0.73];
    bidsFields.ColumnName = {'EEG.event field' 'BIDS field'};
    bidsFields.RowName = [];
    bidsFields.ColumnEditable = [false true];
    bidsFields.Tag = 'bidsFields';
    bidsFields.FontSize = fontSize;
    bidsFields.ColumnWidth = {appWidth*0.24/2,appWidth*0.24/2};
    c2 = uicontrol(f, 'Style', 'text', 'String', 'Note: BIDS field duration is automatically calculated and filled out by EEGLAB', 'Units','normalized', 'ForegroundColor', fg,'BackgroundColor', bg);
    c2.Position = [0 0 0.24 0.18];
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Proceed', 'Units', 'normalized', 'Position', [0.25 0.54 0.1 0.05], 'Callback', @confirmCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Ok', 'Units', 'normalized', 'Position', [0.85 0 0.1 0.05], 'Callback', @okCB); 
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Cancel', 'Units', 'normalized', 'Position', [0.7 0 0.1 0.05], 'Callback', @cancelCB); 
    
    function cancelCB(src, event)
        eventBIDS = newEventBIDS();
        close(f);
    end
    function okCB(src, event)
        close(f);
        eventBIDS
    end

    function confirmCB(src, event)
        bidsTable = findobj('Tag','bidsFields');
        map = bidsTable.Data;
        fields = {};
        t = {};
        for j=1:size(map,1)
            if ~isempty(map{j,2})
                fields = [fields map{j,2}];
                bidsField = map{j,2};
                if ~isfield(eventBIDS, bidsField)
                    eventBIDS.(bidsField) = [];
                    eventBIDS.(bidsField).LongName = '';
                    eventBIDS.(bidsField).Description = '';
                    eventBIDS.(bidsField).Levels = [];
                    eventBIDS.(bidsField).Units = '';
                    eventBIDS.(bidsField).TermURL = '';
                    
                    % pre-populate
                    if strcmp(bidsField, 'onset')
                        eventBIDS.(bidsField).LongName = 'Event onset';
                        eventBIDS.(bidsField).Description = 'Onset (in seconds) of the event measured from the beginning of the acquisition of the first volume in the corresponding task imaging data file';
                        eventBIDS.(bidsField).Units = 'second';
                    elseif strcmp(bidsField, 'value')
                        eventBIDS.(bidsField).LongName = 'Event marker';
                        eventBIDS.(bidsField).Description = 'Marker value associated with the event';
                    elseif strcmp(bidsField, 'trial_type')
                        eventBIDS.(bidsField).LongName = 'Trial type (different from EEGLAB type)';
                        eventBIDS.(bidsField).Description = 'Primary categorisation of each trial to identify them as instances of the experimental conditions';     
                    elseif strcmp(bidsField, 'HED')
                        eventBIDS.(bidsField).LongName = 'Hierarchical Event Descriptor';
                        eventBIDS.(bidsField).Description = 'Tags describing the nature of the event';                        
                    end
                end
                eventBIDS.(bidsField).eeglab = map{j,1}; 
                if strcmp(bidsField, 'onset') || strcmp(bidsField, 'HED')
                    level = 'n/a';
                else
                    level = [];
                end
                t = [t; {eventBIDS.(bidsField).eeglab eventBIDS.(bidsField).LongName eventBIDS.(bidsField).Description level eventBIDS.(bidsField).Units eventBIDS.(bidsField).TermURL}];
            end
        end
        c3 = uicontrol(f, 'Style', 'text', 'String', 'BIDS fields information', 'Units', 'normalized','FontWeight','bold','ForegroundColor', fg,'BackgroundColor', bg);
        c3.Position = [0.36 0.9 0.64 0.1];
        h = uitable(f,'Data', t, 'ColumnName', { 'EEGLAB Field' 'LongName' 'Description' 'Levels' 'Units' 'TermURL' }, 'Units', 'normalized', 'FontSize', fontSize,'Position', [0.36 0.54 0.64 0.41], 'CellSelectionCallback', @levelSelectedCB, 'CellEditCallback', @fieldEditCB,'ColumnEditable',[false true true false true true]);
        h.RowName = fields;
    end

    function fieldEditCB(arg1, obj)
        bfield = obj.Source.RowName{obj.Indices(1)};
        column = obj.Source.ColumnName{obj.Indices(2)};
        if ~strcmp(column, 'Levels')
            eventBIDS.(bfield).(column) = obj.EditData;
        end
    end
    function levelSelectedCB(arg1, obj) 
        if size(obj.Indices,1) == 1 && strcmp(obj.Source.ColumnName{obj.Indices(2)}, 'Levels')% if single cell level selection
            row = obj.Indices(1);
            bfield = obj.Source.RowName{row};
            if ~strcmp(bfield,'HED') && ~strcmp(bfield,'onset') % ignore fields
                eeglabField = eventBIDS.(bfield).eeglab;
                if isnumeric(EEG.event(1).(eeglabField))
                    values = arrayfun(@(x) num2str(x), [EEG.event.(eeglabField)], 'UniformOutput', false);
                    levels = unique(values)';
                else
                    levels = unique({EEG.event.(eeglabField)})';
                end
                if length(levels) <= levelThreshold 
                    createLevelUI('','',bfield,levels);   
                else
                    % remove old ui items if exist
                    h = findobj('Tag', 'levelEditMsg');
                    if ~isempty(h)
                        delete(h);
                    end
                    h = findobj('Tag', 'levelEditTbl');
                    if ~isempty(h)
                        delete(h);
                    end

                    msg = sprintf('There are more than %d unique levels for field %s.\nAre you sure you want to specify levels for it?', levelThreshold, bfield);
                    c4 = uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'FontWeight', 'bold', 'ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'confirmMsg');
                    c4.Position = [(0.36+((0.64-c4.Extent(3))/2)) 0.38 0.5 0.1];
                    c5 = uicontrol(f, 'Style', 'pushbutton', 'String', 'Yes', 'Units', 'normalized','Tag', 'confirmBtn', 'Callback', {@createLevelUI,bfield,levels});
                    c5.Position = [(0.36+((0.64-c5.Extent(3))/2)) 0.33 0.1 0.05];
                end
            end
        end
    end
    function createLevelUI(src,event,bfield,levels)
        % remove old ui items if exist
        h = findobj('Tag', 'confirmMsg');
        if ~isempty(h)
            delete(h);
        end
        h = findobj('Tag', 'confirmBtn');
        if ~isempty(h)
            delete(h);
        end

        % build data
        t = cell(length(levels),2);
        for lvl=1:length(levels)
            t{lvl,1} = levels{lvl};
            if isfield(eventBIDS.(bfield).Levels, checkFormat(levels{lvl}))
                t{lvl,2} = eventBIDS.(bfield).Levels.(checkFormat(levels{lvl}));
            end
        end
        uicontrol(f, 'Style', 'text', 'String', ['Specify levels for field ' bfield], 'Units', 'normalized', 'Position', [0.45 0.45 0.5 0.05],'FontWeight', 'bold','ForegroundColor', fg,'BackgroundColor', bg, 'Tag', 'levelEditMsg');
        h = uitable(f, 'Data', t, 'ColumnName', {'Level' 'Description'}, 'RowName', [], 'Units', 'normalized', 'Position', [0.36 0.07 0.64 0.38], 'FontSize', fontSize, 'Tag', 'levelEditTbl', 'CellEditCallback',{@levelEditCB, bfield},'ColumnEditable',true); 
        h.ColumnWidth = {appWidth*0.64/2,appWidth*0.64/2};
    end
    function levelEditCB(arg1, obj, bfield)
        name = obj.Source.RowName{obj.Indices(1)};
        description = obj.EditData;
        eventBIDS.(bfield).Levels.(checkFormat(name)) = description;
    end
    function formatted = checkFormat(str)
        if ~isempty(str2num(str))
            formatted = ['x' str];
        else
            formatted = str;
        end
    end
    function event = newEventBIDS()
        event = [];
        % duration field is automatically calculated by EEGLAB
        event.duration.LongName = 'Event duration';
        event.duration.Description = 'Duration of the event (measured from onset) in seconds';
        event.duration.Units = 'second';
    end
end