function spans = UI_getspandescriptions(EYE)

% Add name of span as arg

spans = [];

LimPrompts = {'Start of epoch (s relative to %s)'
              'End of epoch (s relative to %s)'};

% Get unique events
allEvents = {};
for dataIdx = 1:numel(EYE)
    allEvents = cat(2, allEvents, {EYE(dataIdx).event.type});
end
eventTypes = unique(allEvents);

while true
    fprintf('%d spans currently defined\n', numel(spans))
    q = 'Add spans?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a,'No') || isempty(a)
        fprintf('Created %d epochs\n\n', numel(spans))
        return
    else
        currSpan = [];
        currSpan.name = inputdlg('name of span?');
        currSpan.name = currSpan.name{1};
        currSpan(1).lims = struct([]);
        for limIdx = 1:2
            currSpan.lims(limIdx).event = eventTypes(listdlg(...
                'PromptString', 'Select a limiting event type',...
                'ListString', eventTypes));
            currSpan.lims(limIdx).event = currSpan.lims(limIdx).event{1};
            currSpan.lims(limIdx).instance = str2double(inputdlg(...
                'Instance (0 for any)'));
            currSpan.lims(limIdx).bookend = str2double(inputdlg(...
                'Bookend (s)'));
        end
        spans = [spans currSpan];
    end
end

end