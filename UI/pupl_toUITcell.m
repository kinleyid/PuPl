
function [data, colnames] = pupl_toUITcell(EYE, which_type)
% Get cell array for UI table from events or epochs

switch which_type
    case 'event'
        all_events = mergefields(EYE, 'event');
    case 'epoch'
        % Get timelocking events
        all_events = pupl_epoch_get(EYE, '_tl');
end
colnames = fieldnames(all_events);
% Don't display uniqid, since it's for internal use only
colnames(strcmp(colnames, 'uniqid')) = [];
colnames = colnames(:)';
data = cell(numel(all_events), numel(colnames));
for colidx = 1:numel(colnames)
    data(:, colidx) = {all_events.(colnames{colidx})};
end

if numel(EYE) > 1
    % Add columns for recording and event number
    colnames = [{'recording' sprintf('%s n.', which_type)} colnames];
    new_data = cell(numel(all_events, 2));
    s_idx = 0;
    for dataidx = 1:numel(EYE)
        event_n = 1:numel(EYE(dataidx).event);
        row_idx = event_n + s_idx;
        new_data(row_idx, 1) = {EYE(dataidx).name};
        new_data(row_idx, 2) = num2cell(event_n);
        s_idx = s_idx + numel(EYE(dataidx).event);
    end
    data = [new_data data];
end

end