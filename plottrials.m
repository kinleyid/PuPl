function plottrials(EYE, varargin)

if numel(EYE) > 1
    EYE = EYE(listdlg('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name}));
    if isempty(EYE)
        return
    end
end

alldata = [mergefields(EYE, 'epoch', 'diam', 'left')...
    mergefields(EYE, 'epoch', 'diam', 'right')];


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

diam = f.UserData.EYE.epoch(f.UserData.trialidx).diam;

figure(f);
clf; hold on

x = 1:numel(diam.left);
t = (x - 1) / f.UserData.EYE.srate;

plot(t, diam.left, 'b');
plot(t, diam.right, 'r');
if isfield(diam, 'both')
    plot(t, diam.both, 'k');
end
ylim(f.UserData.ylims);
xlabel('Time (s)');
ylabel('Pupil diameter');

currtitle = f.UserData.EYE.epoch(f.UserData.trialidx).name;

if f.UserData.EYE.epoch(f.UserData.trialidx).reject
    currtitle = ['[REJECTED] ' currtitle];
end
title(currtitle);

end