
function scrollplot(a, EYE, varargin)

p = inputParser;
addParameter(p, 'type', []);
parse(p, varargin{:});

set(ancestor(a, 'figure'), 'KeyPressFcn', @scrollplot_move);

if isempty(p.Results.type)
    q = 'Plot which type of data?';
    a = questdlg(q, q, 'Dilation', 'Gaze', 'Cancel', 'Dilation');
    switch a
        case 'Dilation'
            type = 'diam';
        case 'Gaze'
            type = 'gaze';
        otherwise
            return
    end
else
    type = p.Results.type;
end

plotinfo = [];
if strcmpi(type, 'diam')
    for dataidx = 1:numel(EYE)
        plotinfo(dataidx).data = {
            getfield(getfromur(EYE(dataidx), 'diam'), 'left')
            getfield(getfromur(EYE(dataidx), 'diam'), 'right')
            EYE(dataidx).diam.left
            EYE(dataidx).diam.right};
        plotinfo(dataidx).legendentries = {
            'Unprocessed left'
            'Unprocessed right'
            'Left'
            'Right'};
        plotinfo(dataidx).colours = {
            'b:'
            'r:'
            'b'
            'r'};
        if isfield(EYE(dataidx).diam, 'both')
            plotinfo(dataidx).data{end + 1} = EYE(dataidx).diam.both;
            plotinfo(dataidx).colours{end + 1} = 'k';
            plotinfo(dataidx).legendentries{end + 1} = 'Both';
        end
        plotinfo(dataidx).ylim = [min(structfun(@min, EYE(dataidx).diam)) max(structfun(@max, EYE(dataidx).diam))];
    end
elseif strcmpi(type, 'gaze')
    for dataidx = 1:numel(EYE)
        plotinfo(dataidx).data = {
            getfield(getfromur(EYE(dataidx), 'gaze'), 'x')
            getfield(getfromur(EYE(dataidx), 'gaze'), 'y')
            EYE(dataidx).gaze.x
            EYE(dataidx).gaze.y};
        plotinfo(dataidx).colours = {
            'b:'
            'r:'
            'b'
            'r'};
        plotinfo(dataidx).legendentries = {
            'Unprocessed x'
            'Unprocessed y'
            'x'
            'y'};
        plotinfo(dataidx).ylim = [min(structfun(@min, EYE(dataidx).gaze)) max(structfun(@max, EYE(dataidx).gaze))];
    end
end

if numel(unique([EYE.srate])) > 1
    uiwait(msgbox('Inconsistent sample rates'))
    return
else
    srate = EYE(1).srate;
end
nSeconds = 10;
x = 1:(nSeconds*srate);

set(a, 'UserData', struct(...
    'plotinfo', plotinfo,...
    'EYE', EYE,...
    'x', x,...
    'srate', srate));

scrollplot_update(a);

end