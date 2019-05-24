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

if ~isempty(e)
    switch e.Key
        case {'pagedown', 'rightarrow'}
            f.UserData.trialidx = f.UserData.trialidx + 1;
        case {'pageup', 'leftarrow'}
            f.UserData.trialidx = f.UserData.trialidx - 1;
        otherwise
            return
    end
end

if f.UserData.trialidx < 1
    f.UserData.trialidx = 1;
elseif f.UserData.trialidx > numel(f.UserData.EYE.epoch)
    f.UserData.trialidx = numel(f.UserData.EYE.epoch);
end

epoch = f.UserData.EYE.epoch(f.UserData.trialidx); 
diam = epoch.diam;

figure(f);
clf; hold on

t = (epoch.relLatencies - 1) / f.UserData.EYE.srate;

plot(t, diam.left, 'b');
plot(t, diam.right, 'r');
if isfield(diam, 'both')
    plot(t, diam.both, 'k');
end
xlim([t(1) t(end)]);
ylim(f.UserData.ylims);
xlabel('Relative time (s)');
ylabel('Pupil diameter');

currtitle = f.UserData.EYE.epoch(f.UserData.trialidx).name;

if f.UserData.EYE.epoch(f.UserData.trialidx).reject
    currtitle = ['[REJECTED] ' currtitle];
end
title(currtitle);

end