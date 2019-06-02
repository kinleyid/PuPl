function plottrials(EYE, varargin)

if numel(EYE) > 1
    EYE = EYE(listdlg('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name}));
    if isempty(EYE)
        return
    end
end

reject = [EYE.epoch.reject];
tmpEYE = EYE;
tmpEYE.epoch(reject) = [];
alldata = [mergefields(tmpEYE, 'epoch', 'diam', 'left')...
    mergefields(tmpEYE, 'epoch', 'diam', 'right')];


f = figure('Name', 'Use H J K L keys to scroll',...
    'NumberTitle', 'off',...
    'Toolbar', 'none',...
    'MenuBar', 'none',...
    'KeyPressFcn', @plotcurrtrial,...
    'UserData', struct(...
        'trialidx', 1,...
        'ylims', [min(alldata) max(alldata)],...
        'EYE', EYE,...
        'srate', EYE.srate));

plotcurrtrial(f, [])

end

function plotcurrtrial(f, e)

UserData = get(f, 'UserData');
if ~isempty(e)
    switch e.Key
        case {'pagedown', 'rightarrow'}
            UserData.trialidx = UserData.trialidx + 1;
        case {'pageup', 'leftarrow'}
            UserData.trialidx = UserData.trialidx - 1;
        otherwise
            return
    end
end

if UserData.trialidx < 1
    UserData.trialidx = 1;
elseif UserData.trialidx > numel(UserData.EYE.epoch)
    UserData.trialidx = numel(UserData.EYE.epoch);
end

epoch = UserData.EYE.epoch(UserData.trialidx); 
diam = epoch.diam;

figure(f);
clf; hold on

t = (epoch.relLatencies - 1) / UserData.EYE.srate;

plot(t, diam.left, 'b');
plot(t, diam.right, 'r');
if isfield(diam, 'both')
    plot(t, diam.both, 'k');
end
xlim([t(1) t(end)]);
ylim(UserData.ylims);
xlabel('Relative time (s)');
ylabel('Pupil diameter');

currtitle = UserData.EYE.epoch(UserData.trialidx).name;

if UserData.EYE.epoch(UserData.trialidx).reject
    currtitle = ['[REJECTED] ' currtitle];
end
title(currtitle);

set(f, 'UserData', UserData)

end