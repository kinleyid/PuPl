
function EYE = pupl_pxmmconversion(EYE, varargin)

p = inputParser;
addParameter(p, 'mmdims', []);
addParameter(p, 'pxdims', []);
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

fprintf('Converting gaze in pixels to gaze in millimeters\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    EYE(dataidx).gaze.x = EYE(dataidx).gaze.x * mmdims(1) / pxdims(1);
    EYE(dataidx).gaze.y = EYE(dataidx).gaze.y * mmdims(2) / pxdims(2);
    fprintf('done\n');
    EYE(dataidx).history{end + 1} = getcallstr(p);
end
fprintf('Done\n');

end