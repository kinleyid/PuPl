function EYE = PFEdetrend(EYE, varargin)

p = inputParser;
addParameter(p, 'axis', 'y');
addParameter(p, 'vis', 'yes'); % Show data first?
addParameter(p, 'proc', 'yes'); % Actually apply detrend?
parse(p, varargin{:});

ax = p.Results.axis;
vis = p.Results.vis;

callStr = sprintf('eyeData = %s(eyeData, ''axis'', %s, ''vis'', ''no'', ''proc'', ''yes'')',...
    mfilename,...
    all2str(ax));

switch vis
    case 'yes'
        vis = true;
    otherwise
        vis = false;
end

if vis
    for dataidx = 1:numel(EYE)
        approval = displaydetrend(EYE(dataidx), ax);
        if isempty(approval)
            return
        end
    end
end

if ~strcmp(p.Results.proc, 'no')
    fprintf('Detrending...\n')
    for dataidx = 1:numel(EYE)
        fprintf('\t%s:\n\t', EYE(dataidx).name);
        params = getPFEdetrendparams(EYE(dataidx), ax);
        currDetrendParams = detrendParams{dataidx};
        if isempty(currDetrendParams)
            fprintf('Skipping\n');
            continue
        end
        fprintf('Correcting for the following equation:\n\tDiam = C + ');
        switch ax
            case 'y'
                fprintf('%f*gaze_y\n', currDetrendParams(1))
            case 'x'
                fprintf('%f*gaze_x + %f*gaze_x^2\n', currDetrendParams(2), currDetrendParams(1))
        end
        est = polyval(currDetrendParams, EYE(dataidx).gaze.(ax));
        est = est - nanmean_bc(est);
        for stream = reshape(fieldnames(EYE(dataidx).diam), 1, [])
            EYE(dataidx).diam.(stream{:}) = EYE(dataidx).diam.(stream{:}) - est;
        end
        EYE(dataidx).history = cat(1, EYE(dataidx).history, callStr);
    end
    fprintf('Done\n')
end

end

function approval = displaydetrend(EYE, curraxis)

f = figure(...
    'ToolBar', 'none',...
    'MenuBar', 'none',...
    'UserData', true);
p1 = uipanel(f,...
    'Tag', 'plotpanel',...
    'Units', 'normalized',...
    'Position', [0.01 0.11 0.98 0.88]);
a = axes(p1, 'Tag', 'scatter');
p = uipanel(f,...
    'Units', 'normalized',...
    'Position', [0.01 0.01 0.98 0.08]);
approvebutton = uicontrol(p,...
    'String', 'Next',...
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

plotPFEtrend(a, EYE, curraxis);
uicontrol(approvebutton);

uiwait(f);

if isgraphics(f)
    approval = get(f, 'UserData');
    close(f);
else
    approval = [];
end

end