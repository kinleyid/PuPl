function deletedata

global pupl_globals
global_data = evalin('base', pupl_globals.datavarname);
UserData = get(pupl_globals.UI, 'UserData');
dots = repmat({sprintf(' _ ')}, 1, numel(global_data));
dots(UserData.activeEyeDataIdx) = {' > '};
rmidx = listdlgregexp(...
    'ListString', strcat(dots, {global_data.name}),...
    'PromptString', 'Remove which?');
if isempty(rmidx)
    return
end
fprintf('Removing data...\n');
for curridx = reshape(rmidx, 1, [])
    fprintf('\t%s\n', global_data(curridx).name);
end
fprintf('Done\n');
global_data(rmidx) = [];
if isempty(global_data)
    global_data = struct([]);
end
UserData.activeEyeDataIdx(rmidx) = [];

set(pupl_globals.UI, 'UserData', UserData);

assignin('base', pupl_globals.datavarname, global_data);

update_UI;

end