function pupl_plot_epochs(h, EYE)

% Get limits
[l, rej] = pupl_epoch_getdata(EYE, [], 'pupil', 'left');
r = pupl_epoch_getdata(EYE, [], 'pupil', 'right');
alldata = [l{~rej} r{~rej}];
if isempty(alldata) % If all are rejected
    alldata = [l{:} r{:}];
end
lims = [min(alldata) max(alldata)];

set(h,...
    'UserData', struct(...
        'trialidx', 1,...
        'ylims', lims,...
        'EYE', EYE));

% Prepare figure
control_panel = uipanel(h,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08]);
uicontrol(control_panel,...
    'Style', 'pushbutton',...
    'String', '< Previous epoch <',...
    'HorizontalAlignment', 'right',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_plot_epochs(h, -1),...
    'Position', [0.01 0.01 0.48 0.98]);
uicontrol(control_panel,...
    'Style', 'pushbutton',...
    'String', '> Next epoch >',...
    'HorizontalAlignment', 'right',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_plot_epochs(h, 1),...
    'Position', [0.51 0.01 0.48 0.98]);
p = uipanel(h,...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
axes(p, 'Tag', 'axes');

sub_plot_epochs(h, 0)

end

function sub_plot_epochs(h, n)

ud = get(h, 'UserData');
trialidx = ud.trialidx;
EYE = ud.EYE;
epoch = EYE.epoch(trialidx);

trialidx = trialidx + n;
if trialidx < 1
    trialidx = 1;
elseif trialidx > numel(EYE.epoch)
    trialidx = numel(EYE.epoch);
end

ud.trialidx = trialidx;

[pupil, urpupil] = deal([]);
for field = {'left' 'right'}
    pupil.(field{:}) = cell2mat(pupl_epoch_getdata(EYE, trialidx, 'pupil', field{:}));
    urpupil.(field{:}) = cell2mat(pupl_epoch_getdata(EYE, trialidx, 'urpupil', field{:}));
end
if isfield(EYE.pupil, 'both')
    pupil.both = cell2mat(pupl_epoch_getdata(EYE, trialidx, 'pupil', 'both'));
end

axes(findobj(h, 'Tag', 'axes'));
cla; hold on

t = unfold(parsetimestr(epoch.lims, EYE.srate, 'smp') + epoch.event.latency) / EYE.srate; % Time in seconds
eventidx = unfold(parsetimestr(epoch.lims, EYE.srate, 'smp')) == 0; % Find where the event occurs
plot(repmat(t(eventidx), 1, 2), ud.ylims, 'k--');
plot(t, pupil.left, 'b');
plot(t, pupil.right, 'r');
if isfield(pupil, 'both')
    plot(t, pupil.both, 'k');
end
plot(t, urpupil.left, 'b:');
plot(t, urpupil.right, 'r:');

xlim([t(1) t(end)]);
ylim(ud.ylims);
xlabel('Time (s)');
ylabel(sprintf('Pupil %s (%s, %s)', EYE.units.epoch{:}));
legendentries = {'Event', 'Left', 'Right', 'Unprocesssed left', 'Unprocessed right'};
if isfield(pupil, 'both')
    legendentries = [legendentries(1:3) 'both' legendentries(4:end)];
end
legend(legendentries{:});

currtitle = ud.EYE.epoch(ud.trialidx).name;

if EYE.epoch(trialidx).reject
    currtitle = ['[REJECTED] ' currtitle];
end
title(currtitle);

set(h, 'UserData', ud)

end