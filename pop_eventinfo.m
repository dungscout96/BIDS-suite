function pop_eventinfo(EEG)
    eventBIDS = [];
    levelThreshold = 20;
    
    % duration field is automatically calculated by EEGLAB
    eventBIDS.duration.LongName = 'Event duration';
    eventBIDS.duration.Description = 'Duration of the event (measured from onset) in seconds';
    eventBIDS.duration.Units = 'second';
    
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
    f = figure;
    f.Position(3) = 800;
    bidsFields = uitable(f);
    bidsFields.Data = data;
    bidsFields.Units = 'normalized';
    bidsFields.Position = [0 0 0.24 1];
    bidsFields.ColumnName = {'EEG.event field' 'BIDS field'}
    bidsFields.RowName = [];
    bidsFields.ColumnEditable = [false true];
    bidsFields.Tag = 'bidsFields';
    uicontrol(f, 'Style', 'pushbutton', 'String', 'Confirm', 'Units', 'normalized', 'Position', [0.25 0.5 0.1 0.05], 'Callback', @confirmCB); 

    
    function confirmCB(src, event)
        bidsTable = findobj('Tag','bidsFields');
%         bidsTable.Enable = 'inactive';
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
                t = [t; {eventBIDS.(bidsField).eeglab eventBIDS.(bidsField).LongName eventBIDS.(bidsField).Description [] eventBIDS.(bidsField).Units eventBIDS.(bidsField).TermURL}];
            end
        end
        h = uitable(f,'Data', t, 'ColumnName', { 'EEGLAB Field' 'LongName' 'Description' 'Levels' 'Units' 'TermURL' }, 'Units', 'normalized', 'Position', [0.36 0.6 0.64 0.4], 'CellSelectionCallback', @levelSelectedCB, 'CellEditCallback', @fieldEditCB,'ColumnEditable',[false true true false true true]);
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
                    uicontrol(f, 'Style', 'text', 'String', msg, 'Units', 'normalized', 'Position', [0.4 0.45 0.5 0.1], 'Tag', 'confirmMsg');
                    uicontrol(f, 'Style', 'pushbutton', 'String', 'Yes', 'Units', 'normalized', 'Position', [0.55 0.4 0.1 0.05], 'Tag', 'confirmBtn', 'Callback', {@createLevelUI,bfield,levels});
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
            if isfield(eventBIDS.(bfield).Levels, levels{lvl})
                t{lvl,2} = eventBIDS.(bfield).Levels.(levels{lvl});
            end
        end
        uicontrol(f, 'Style', 'text', 'String', ['Specify levels for field ' bfield], 'Units', 'normalized', 'Position', [0.4 0.5 0.5 0.05], 'Tag', 'levelEditMsg');
        uitable(f, 'Data', t, 'ColumnName', {'Description'}, 'RowName', levels, 'Units', 'normalized', 'Position', [0.36 0 0.64 0.5], 'Tag', 'levelEditTbl', 'CellEditCallback',{@levelEditCB, bfield},'ColumnEditable',true); 
    end
    function levelEditCB(arg1, obj, bfield)
        name = obj.Source.RowName{obj.Indices(1)};
        description = obj.EditData;
        eventBIDS.(bfield).Levels.(name) = description;
    end
end