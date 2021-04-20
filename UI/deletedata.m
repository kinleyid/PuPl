function deletedata(varargin)

global pupl_globals

if isempty(varargin)
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
    fprintf('\t%s\n', global_data(rmidx).name);
    fprintf('Done\n');
else
    rmidx = varargin{1};
end

UserData.activeEyeDataIdx(rmidx) = [];
set(pupl_globals.UI, 'UserData', UserData);

updateglobals(rmidx, @() [], 1, true, 'remove data');

end