
function sel = pupl_epoch_selUI(EYE, varargin)

if numel(varargin) < 1
    prompt = 'Select events';
else
    prompt = varargin{1};
end

listbox_str = {};
for dataidx = 1:numel(EYE)
    curr_eps = EYE(dataidx).epoch(:)';
    rec_names = repmat({sprintf('[%s]', EYE(dataidx).name)}, size(curr_eps));
    event_ns = cellfun(@(x) sprintf('%d.', x), num2cell(1:numel(curr_eps)), 'UniformOutput', false);
    tls = pupl_epoch_get(EYE(dataidx), [], '_tl');
    event_times = cellfun(@(x) sprintf('[%ss]', num2str(x)), {tls.time}, 'UniformOutput', false);
    epoch_names = pupl_epoch_get(EYE(dataidx), EYE(dataidx).epoch, 'name');
    num_idx = cellfun(@isnumeric, {EYE(dataidx).epoch.name});
    event_names = {tls.name};
    event_names(num_idx) = {''};
    event_names(~num_idx) = strcat('[', event_names(~num_idx), ']');
    listbox_str{end + 1} = strcat(...
        rec_names,...
        {' '},...
        event_ns,...
        {' '},...
        event_times,...
        {' '},...
        epoch_names,...
        {' '},...
        event_names);
end
listbox_str = [listbox_str{:}];

sel = pupl_event_selUI(EYE, prompt, true, listbox_str, pupl_epoch_get(EYE, [], '_tl'));

end