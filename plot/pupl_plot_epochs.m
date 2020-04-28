function pupl_plot_epochs(h, EYE)

pupil_fields = reshape(fieldnames(EYE.pupil), 1, []);

% Get limits
alldata = [];

for field = pupil_fields
    [x, rej] = pupl_epoch_getdata(EYE, [], 'pupil', field{:});
    alldata = [alldata x{~rej}];
end

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
axes('Parent', p, 'Tag', 'axes');

sub_plot_epochs(h, 0)

end

function sub_plot_epochs(h, cidx)

ud = get(h, 'UserData');
trialidx = ud.trialidx;
EYE = ud.EYE;

trialidx = trialidx + cidx;
if trialidx < 1
    trialidx = numel(EYE.epoch);
elseif trialidx > numel(EYE.epoch)
    trialidx = 1;
end

ud.trialidx = trialidx;

epoch_selector = [];
epoch_selector.idx = trialidx;
epoch = pupl_epoch_get(EYE, epoch_selector);

% Get plot data
plotinfo = struct(...
    'data', [],...
    'legendentries', [],...
    'colours', [],...
    't', [],...
    'srate', []);
colours = {'b' 'r'};
n = 1;
for side = {'left' 'right'}
    if isfield(EYE.pupil, side{:})
        plotinfo.data = [
            plotinfo.data
            [
                pupl_epoch_getdata(EYE, epoch_selector, 'ur', 'pupil', side{:})
                pupl_epoch_getdata(EYE, epoch_selector, 'pupil', side{:})
            ]
        ];
        plotinfo.legendentries = [
            plotinfo.legendentries
            {
                ['Unprocessed ' side{:}]
                [upper(side{:}(1)) side{:}(2:end)]
            }
        ];
        plotinfo.colours = [
            plotinfo.colours
            {
                sprintf('%s:', colours{n})
                colours{n}
            }
        ];
        n = n + 1;
        plotinfo.t = [
            plotinfo.t
            {
                EYE.ur.times(unfold(pupl_epoch_get(EYE, epoch_selector, '_abs', 'ur')))
                EYE.times(unfold(pupl_epoch_get(EYE, epoch_selector, '_abs')))
            }
        ];
        plotinfo.srate = [
            plotinfo.srate
            {
                EYE.ur.srate
                EYE.srate
            }
        ];
    end
end

axes(findobj(h, 'Tag', 'axes'));
cla; hold on

tl_time = pupl_epoch_get(EYE, epoch_selector, 'time');

for dataidx = 1:numel(plotinfo.data)
    plot(...
        plotinfo.t{dataidx},...
        plotinfo.data{dataidx},...
        plotinfo.colours{dataidx});
end

plot(repmat(tl_time, 1, 2), ud.ylims, 'k--');

xlim(EYE.times(pupl_epoch_get(EYE, epoch_selector, '_abs')));
ylim(ud.ylims);
xlabel('Time (s)');
ylabel(pupl_epoch_get(EYE, epoch_selector, '_units'));
legend(plotinfo.legendentries{:}, 'Timelocking event');

currtitle = sprintf('Epoch %d.', trialidx);
if epoch.reject
    currtitle = sprintf('%s [REJECTED]', currtitle);
end
epoch_name = pupl_epoch_get(ud.EYE, epoch_selector, '_name');
tl_name = pupl_epoch_get(ud.EYE, epoch_selector, 'name');
currtitle = sprintf('%s %s\nTimelocking: %s', currtitle, epoch_name{:}, tl_name{:});
title(currtitle, 'Interpreter', 'none');

set(h, 'UserData', ud)

end