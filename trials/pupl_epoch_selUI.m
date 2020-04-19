
function sel = pupl_epoch_selUI(EYE, varargin)

if numel(varargin) < 1
    prompt = 'Select events';
else
    prompt = varargin{1};
end

listbox_str = {};
for dataidx = 1:numel(EYE)
    curr_evs = EYE(dataidx).event(:)';
    rec_names = repmat({sprintf('[%s]', EYE(dataidx).name)}, size(curr_evs));
    event_ns = cellfun(@(x) sprintf('%d.', x), num2cell(1:numel(curr_evs)), 'UniformOutput', false);
    event_times = cellfun(@(x) sprintf('[%ss]', num2str(x)), {curr_evs.time}, 'UniformOutput', false);
    event_names = pupl_epoch_get(EYE(dataidx), EYE(dataidx).epoch, 'name');
    listbox_str{end + 1} = strcat(...
        rec_names,...
        {' '},...
        event_ns,...
        {' '},...
        event_times,...
        {' '},...
        event_names);
end
listbox_str = [listbox_str{:}];

sel = pupl_event_selUI(EYE, prompt, true, listbox_str);

end