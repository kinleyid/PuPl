function spans = UI_getspandescriptions(EYE, spanName)

spans = struct([]);
eventTypes = unique(mergefields(EYE, 'event', 'type'));

while true
    currSpan = struct('name', char(inputdlg(sprintf('name of %s?', spanName))),...
        'lims', struct([]));
    currSpan.lims(1).event = char(eventTypes(listdlg(...
        'PromptString', sprintf('%s begins relative to which event?', spanName),...
        'ListString', eventTypes)));
    currSpan.lims(1).instance = str2double(inputdlg(...
        sprintf('relative to which instance of %s? (0 for any)', currSpan.lims(1).event)));
    currSpan.lims(1).bookend = str2double(inputdlg(...
        sprintf('%s begins how many seconds relative to %s?', spanName, currSpan.lims(1).event)));
    
    currSpan.lims(2).event = char(eventTypes(listdlg(...
        'PromptString', sprintf('%s ends relative to which event?', spanName),...
        'ListString', eventTypes)));
    if currSpan.lims(1).instance == 0
        currSpan.lims(2).instance = 0;
    else
        currSpan.lims(2).instance = str2double(inputdlg(...
            sprintf('relative to which instance of %s? (0 not allowed)', currSpan.lims(2).event)));
    end
    currSpan.lims(2).bookend = str2double(inputdlg(...
        sprintf('%s ends how many seconds relative to %s?', spanName, currSpan.lims(2).event)));
    
    spans = cat(2, spans, currSpan);

    q = sprintf('define more %ss?', spanName);
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No') || isempty(a)
        return
    end
end

end