
function [data, colnames] = pupl_event_toUITcell(all_events)
% Get cell array for UI table

colnames = fieldnames(all_events);
colnames(strcmp(colnames, 'uniqid')) = [];
colnames = colnames(:)';
data = cell(numel(all_events), numel(colnames));
for colidx = 1:numel(colnames)
    data(:, colidx) = {all_events.(colnames{colidx})};
end

end