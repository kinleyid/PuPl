function plottrials(a, EYE)

set(ancestor(a, 'figure'), 'KeyPressFcn', @(h, e) plotcurrtrial(a, e));

reject = [EYE.epoch.reject];
tmpEYE = EYE;
tmpEYE.epoch(reject) = [];
l = getalltrialdata(tmpEYE, 'diam', 'left');
r = getalltrialdata(tmpEYE, 'diam', 'right');
alldata = [l{:} r{:}];

set(a, 'UserData', struct(...
        'trialidx', 1,...
        'ylims', [min(alldata) max(alldata)],...
        'EYE', EYE,...
        'srate', EYE.srate));

plotcurrtrial(a, [])

end

function plotcurrtrial(a, e)

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

[diam, urdiam] = deal([]);
for field = {'left' 'right'}
    diam.(field{:}) = gettrialdata(EYE, trialidx, 'diam', field{:});
    urdiam.(field{:}) = gettrialdata(EYE, trialidx, 'urdiam', field{:});
end
try
    diam.both = gettrialdata(EYE, trialidx, 'diam', 'both');
end

axes(a);
cla; hold on

t = (unfold(epoch.abslims) - 1) / EYE.srate;
eventidx = unfold(epoch.rellims) == 0;
plot(repmat(t(eventidx), 1, 2), ud.ylims, 'k--');
plot(t, diam.left, 'b');
plot(t, diam.right, 'r');
if isfield(diam, 'both')
    plot(t, diam.both, 'k');
end
plot(t, urdiam.left, 'b:');
plot(t, urdiam.right, 'r:');

xlim([t(1) t(end)]);
ylim(ud.ylims);
xlabel('Time (s)');
ylabel(sprintf('Pupil %s (%s, %s)', EYE.units.epoch{:}));
legendentries = {'Event', 'Left', 'Right', 'Unprocesssed left', 'Unprocessed right'};
if isfield(diam, 'both')
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