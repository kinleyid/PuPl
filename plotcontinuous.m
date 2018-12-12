function plotcontinuous(EYE, varargin)

p = inputParser;
addParameter(p, 'type', []);
parse(p, varargin{:});

if isempty(p.Results.type)
    q = 'Plot which type of data?';
    a = questdlg(q, q, 'Dilation', 'Gaze', 'Cancel', 'Dilation');
    switch a
        case 'Dilation'
            type = 'dilation';
        case 'Gaze'
            type = 'gaze';
        otherwise
            return
    end
else
    type = p.Results.type;
end

plotinfo = [];
if strcmpi(type, 'dilation')
    for dataIdx = 1:numel(EYE)
        plotinfo(dataIdx).data = {
            EYE(dataIdx).diam.left
            EYE(dataIdx).diam.right
            mean([
                EYE(dataIdx).urDiam.left.x
                EYE(dataIdx).urDiam.left.y]);
            mean([
                EYE(dataIdx).urDiam.right.x
                EYE(dataIdx).urDiam.right.y])};
        plotinfo(dataIdx).colours = {
            'b'
            'r'
            'b:'
            'r:'};
        plotinfo(dataIdx).greyblinks = [
            true
            true
            false
            false];
        if isfield(EYE(dataIdx).diam, 'both')
            plotinfo(dataIdx).data = [plotinfo(dataIdx).data; EYE(dataIdx).diam.both];
            plotinfo(dataIdx).colours = [plotinfo(dataIdx).colours; 'k'];
            plotinfo(dataIdx).greyblinks = [plotinfo(dataIdx).greyblinks; true];
        end
        plotinfo(dataIdx).ylim = [min(structfun(@min, EYE(dataIdx).diam)) max(structfun(@max, EYE(dataIdx).diam))];
    end
elseif strcmpi(type, 'gaze')
    for dataIdx = 1:numel(EYE)
        plotinfo(dataIdx).data = {
            EYE(dataIdx).gaze.x
            EYE(dataIdx).gaze.y};
        plotinfo(dataIdx).colours = {
            'b'
            'r'};
        plotinfo(dataIdx).greyblinks = [
            true
            true];
        plotinfo(dataIdx).ylim = [min(structfun(@min, EYE(dataIdx).gaze)) max(structfun(@max, EYE(dataIdx).gaze))];
    end
end

% Plots continuous data, scrollable

if numel(unique([EYE.srate])) > 1
    uiwait(msgbox('Inconsistent sample rates'))
    return
else
    srate = EYE(1).srate;
end
nSeconds = 5;
x = 1:(nSeconds*srate);

f = figure('Name', 'Use H J K L keys to scroll',...
    'NumberTitle', 'off',...
    'Toolbar', 'none',...
    'MenuBar', 'none',...
    'KeyPressFcn', @moveData,...
    'UserData', struct(...
        'plotinfo', plotinfo,...
        'EYE', EYE,...
        'x', x,...
        'srate', srate,...
        'axes', []));

plotdata(f)

end

function moveData(h, e)

switch e.Key
    case {'h', 'pageup'}
        change = -5;
    case {'l', 'pagedown'}
        change = 5;
    case {'k', 'rightarrow'}
        change = 1;
    case {'j', 'leftarrow'}
        change = -1;
    otherwise
        return
end
h.UserData.x = h.UserData.x + change*h.UserData.srate;
if any(h.UserData.x < 1)
    h.UserData.x = h.UserData.x - min(h.UserData.x) + 1;
end

plotdata(h);

end

function plotdata(f)

figure(f);

plotinfo = f.UserData.plotinfo;
EYE = f.UserData.EYE;
x = f.UserData.x;
srate = f.UserData.srate;
xtimes = (x - 1)/srate;
%{
for dataIdx = 1:numel(EYE)
    if any(x > numel(plotinfo(dataIdx).data))
        return
    end
end
%}
for plotIdx = 1:numel(plotinfo)
    cla(subplot(numel(plotinfo), 1, plotIdx)); hold on
    blinkIdx = EYE(plotIdx).isBlink(x);
    for dataIdx = 1:numel(plotinfo(plotIdx).data)
        currData = plotinfo(plotIdx).data{dataIdx};
        currData = currData(x);
        plot(xtimes, currData, plotinfo(plotIdx).colours{dataIdx});
        if plotinfo(plotIdx).greyblinks(dataIdx)
            currData(~blinkIdx) = nan;
            plot(xtimes, currData,...
                'color', [0.5 0.5 0.5],...
                'linewidth', 2);
        end
    end
    xlim([xtimes(1) xtimes(end)]);
    if ~isempty(EYE(plotIdx).event)
        for eventIdx = find(ismember([EYE(plotIdx).event.latency], x))
            t = (EYE(plotIdx).event(eventIdx).latency - 1)/EYE(plotIdx).srate;
            plot(repmat(t, 1, 2), plotinfo(plotIdx).ylim, 'k');
            text(t, mean(plotinfo(plotIdx).ylim), num2str(EYE(plotIdx).event(eventIdx).type),...
                'FontSize', 8,...
                'Rotation', 20);
        end
    end
    ylim(plotinfo(plotIdx).ylim);
    xlabel('Time (s)');
    title(EYE(plotIdx).name, 'Interpreter', 'none');
end

end