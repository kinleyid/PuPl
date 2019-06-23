function EYE = PFEdetrend(EYE, varargin)

p = inputParser;
addParameter(p, 'axis', 'y');
addParameter(p, 'vis', 'yes');
parse(p, varargin{:});

axis = p.Results.axis;
vis = p.Results.vis;

callStr = sprintf('eyeData = %s(eyeData, ''axis'', %s, ''vis'', ''no'')',...
    mfilename,...
    all2str(axis));

switch vis
    case 'yes'
        vis = true;
    otherwise
        vis = false;
end

for dataidx = 1:numel(EYE) % Get params
    if isfield(EYE(dataidx).diam, 'both')
        currData = EYE(dataidx).diam.both(:);
    else
        currData = nanmean_bc([EYE(dataidx).diam.left(:) EYE(dataidx).diam.right(:)], 2);
    end
    currCoord = EYE(dataidx).gaze.(axis)(:);
    params = getdetrendparams(currCoord, currData, axis);
    detrendParams{dataidx} = params;
    if vis % Display for approval
        approval = displaydetrend(currCoord, currData, params, axis);
        if isempty(approval)
            return
        elseif ~approval % Detrend not approved
            detrendParams{dataidx} = [];
        end
    end
end

fprintf('Detrending...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s:\n\t', EYE(dataidx).name)
    currDetrendParams = detrendParams{dataidx};
    if isempty(currDetrendParams)
        fprintf('Skipping\n');
        continue
    end
    fprintf('Correcting for the following equation:\n\tDiam = C + ');
    switch axis
        case 'y'
            fprintf('%f*gaze_y\n', currDetrendParams(1))
        case 'x'
            fprintf('%f*gaze_x + %f*gaze_x^2\n', currDetrendParams(2), currDetrendParams(1))
    end
    est = polyval(currDetrendParams, EYE(dataidx).gaze.(axis));
    est = est - nanmean_bc(est);
    for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
        EYE(dataidx).diam.(stream{:}) = EYE(dataidx).diam.(stream{:}) - est;
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
end
fprintf('Done\n')

end

function params = getdetrendparams(x, y, axis)

x = x(:);
y = y(:);

badIdx = isnan(x) | isnan(y);

switch axis
    case 'y'
        n = 1;
    case 'x'
        n = 2;
end
params = polyfit(x(~badIdx), y(~badIdx), n);

end

function approval = displaydetrend(x, y, params, axis)

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', true);
p1 = uipanel(f,...
    'Tag', 'plotpanel',...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
axes(p1,...
    'Tag', 'scatter',...
    'NextPlot', 'add')
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08]);
approvebutton = uicontrol(p,...
    'String', 'Approve',...
    'Units', 'normalized',...
    'Callback', @(h,e) uiresume(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() uiresume(f)),...
    'Position', [0.01 0.01 0.48 0.98]);
uicontrol(p,...
    'String', 'Quit',...
    'Units', 'normalized',...
    'Callback', @(h,e) delete(f),...
    'KeyPressFcn', @(h,e) enterdo(e, @() delete(f)),...
    'Position', [0.51 0.01 0.48 0.98]);

s = scatter(x, y, 5, 'k', 'filled');
try
    alpha(s, 0.1);
end
linex = sort(x);
liney = polyval(params, linex);
plot(linex, liney, 'k');
%{
tr = polyval(params, x);
cory = y(:) - tr(:) + nanmean_bc(tr); 
s = scatter(x, cory, 5, 'r', 'filled');
try
    alpha(s, 0.02);
end
newparams = getdetrendparams(x, cory, axis);
liney = polyval(newparams, linex);
plot(linex, liney, 'r');
%}
xlabel(['Gaze ' axis]);
ylabel('Pupil diameter');

uicontrol(approvebutton);

uiwait(f);

if isgraphics(f)
    approval = get(f, 'UserData');
    close(f);
else
    approval = [];
end

end

function approve(f)

set(f, 'UserData', true);
uiresume(f);

end

function disapprove(f)

set(f, 'UserData', false);
uiresume(f);

end