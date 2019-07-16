
function EYE = pupl_pxmmconversion(EYE, varargin)

p = inputParser;
addParameter(p, 'mmdims', []);
addParameter(p, 'pxdims', []);
addParameter(p, 'flipy', []);
parse(p, varargin{:});

if isempty(p.Results.mmdims)
    mmdims = inputdlg({
        'Screen x size (mm)'
        'Screen y size (mm)'});
    if isempty(mmdims)
        return
    end
    mmdims = str2double(mmdims);
else
    mmdims = p.Results.mmdims;
end

if isempty(p.Results.pxdims)
    pxdims = inputdlg({
        'Screen x size (px)'
        'Screen y size (px)'});
    if isempty(pxdims)
        return
    end
    pxdims = str2double(pxdims);
else
    pxdims = p.Results.pxdims;
end

if isempty(p.Results.flipy)
    q = 'Reverse gaze y coordinates?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel', 'No');
    switch lower(a)
        case 'yes'
            flipy = true;
        case 'no'
            flipy = false;
        otherwise
            return
    end
else
    flipy = p.Results.flipy;
end

fprintf('Converting gaze in pixels to gaze in millimeters\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    EYE(dataidx).gaze.x = EYE(dataidx).gaze.x * mmdims(1) / pxdims(1);
    EYE(dataidx).units.gaze.x{1} = 'mm';
    EYE(dataidx).gaze.y = EYE(dataidx).gaze.y * mmdims(2) / pxdims(2);
    EYE(dataidx).units.gaze.y{1} = 'mm';
    if flipy
        EYE(dataidx).gaze.y = mmdims(1) - EYE(dataidx).gaze.y;
        EYE(dataidx).coords.gaze.y{2} = 'screen bottom';
    end
    fprintf('done\n');
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end