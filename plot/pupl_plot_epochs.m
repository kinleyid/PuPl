function pupl_plot_epochs(a, EYE)

set(ancestor(a, 'figure'), 'KeyPressFcn', @(h, e) sub_plot_epochs(a, e));

% Get limits
[l, rej] = pupl_epoch_getdata(EYE, [], 'pupil', 'left');
r = pupl_epoch_getdata(EYE, [], 'pupil', 'right');
alldata = [l{~rej} r{~rej}];
lims = [min(alldata) max(alldata)];

set(a,...
    'UserData', struct(...
        'trialidx', 1,...
        'ylims', lims,...
        'EYE', EYE,...
        'srate', EYE.srate));

sub_plot_epochs(a, [])

end

function sub_plot_epochs(a, e)

ud = get(a, 'UserData');
trialidx = ud.trialidx;
EYE = ud.EYE;
epoch = EYE.epoch(trialidx);

if ~isempty(e)
    switch e.Key
        case {'pagedown', 'rightarrow'}
            trialidx = trialidx + 1;
        case {'pageup', 'leftarrow'}
            trialidx = trialidx - 1;
        otherwise
            return
    end
end

if trialidx < 1
    trialidx = 1;
elseif trialidx > numel(EYE.epoch)
    trialidx = numel(EYE.epoch);
end

ud.trialidx = trialidx;

[pupil, urpupil] = deal([]);
for field = {'left' 'right'}
    pupil.(field{:}) = pupl_epoch_getdata(EYE, trialidx, 'pupil', field{:});
    urpupil.(field{:}) = pupl_epoch_getdata(EYE, trialidx, 'urpupil', field{:});
end
if isfield(EYE.pupil, 'both')
    pupil.both = pupl_epoch_getdata(EYE, trialidx, 'pupil', 'both');
end

for field = reshape(fieldnames(urpupil), 1, [])
    urpupil.(field{:}) = urpupil.(field{:}){:};
end

for field = reshape(fieldnames(pupil), 1, [])
    pupil.(field{:}) = pupil.(field{:}){:};
end

axes(a);
cla; hold on

t = (unfold(epoch.abslims) - 1) / EYE.srate;
eventidx = unfold(epoch.rellims) == 0;
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

set(a, 'UserData', ud)

end