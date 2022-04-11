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
    'Style', 'checkbox',...
    'Tag', 'displayevents',...
    'String', 'Display events',...
    'Value', 0,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.21 0.98],...
    'Callback', @(a, b) sub_plot_epochs(h, 0));
uicontrol(control_panel,...
    'Style', 'pushbutton',...
    'String', '< Previous epoch <',...
    'HorizontalAlignment', 'right',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_plot_epochs(h, -1),...
    'Position', [0.21 0.01 0.38 0.98]);
uicontrol(control_panel,...
    'Style', 'pushbutton',...
    'String', '> Next epoch >',...
    'HorizontalAlignment', 'right',...
    'Units', 'normalized',...
    'Callback', @(a, b) sub_plot_epochs(h, 1),...
    'Position', [0.59 0.01 0.38 0.98]);
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
    if n == 3 % Both eyes present in the data, therefore compute and display binocular average
        EYE = pupl_mergelr(EYE);
        plotinfo.data(end + 1) = pupl_epoch_getdata(EYE, epoch_selector, 'pupil', 'both');
        plotinfo.colours{end + 1} = 'k';
        plotinfo.legendentries{end + 1} = 'Binocular average';
        plotinfo.t{end + 1} = EYE.times(unfold(pupl_epoch_get(EYE, epoch_selector, '_abs')));
        plotinfo.srate{end + 1} = EYE.srate;
    end
end

axes(findobj(h, 'Tag', 'axes'));
cla; hold on

for dataidx = 1:numel(plotinfo.data)
    plot(...
        plotinfo.t{dataidx},...
        plotinfo.data{dataidx},...
        plotinfo.colours{dataidx});
end

t_lim = EYE.times(pupl_epoch_get(EYE, epoch_selector, '_abs'));

% Display baseline period
baselines = pupl_epoch_get(EYE, epoch_selector, '_base');
extra_entries = {};
if ~isempty(baselines)
    for baselineidx = 1:numel(baselines)
        baseline = baselines(baselineidx);
        rel_b_lim = parsetimestr(baseline.lims, EYE.srate);
        tl = pupl_epoch_get(EYE, {baseline}, '_tl', 'time');
        b_lim = rel_b_lim + tl.time;
        plot(b_lim([1 1]), ud.ylims, 'g--');
        plot(b_lim([2 2]), ud.ylims, 'g--');
    end
    extra_entries = {'Baseline'};
end

% Display events
if get(findobj(h, 'Tag', 'displayevents'), 'Value')
    pupl_plot_events(EYE, t_lim, ud.ylims);
end

xlim(t_lim);
ylim(ud.ylims);
xlabel('Time (s)');
ylabel(pupl_epoch_get(EYE, epoch_selector, '_units'));
legend(plotinfo.legendentries{:}, extra_entries{:});

currtitle = sprintf('Epoch %d/%d', trialidx, numel(EYE.epoch));
if epoch.reject
    currtitle = sprintf('%s [REJECTED]', currtitle);
end
epoch_name = pupl_epoch_get(ud.EYE, epoch_selector, '_name');
currtitle = sprintf('%s: "%s"', currtitle, epoch_name{:});
title(currtitle, 'Interpreter', 'none');

set(h, 'UserData', ud)

end