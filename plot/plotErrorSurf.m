function plotErrorSurf(varargin)

graphicsIdx = cellfun(@(x) all(isgraphics(x)), varargin);
if any(graphicsIdx)
    f = varargin{graphicsIdx};
else
    f = gcbf;
end

UserData = get(f, 'UserData');

EYE = UserData.EYE;

gridN = str2num(get(getcomponentbytag(f, 'controlPanel', 'gridN'), 'String'));
trimPpn = str2num(get(getcomponentbytag(f, 'controlPanel', 'trimPpn'), 'String'));
inputRange = str2num(get(getcomponentbytag(f, 'controlPanel', 'inputRange'), 'String'));
boxcar = str2num(get(getcomponentbytag(f, 'controlPanel', 'boxcar'), 'String'));

UserData.gridN = gridN;
UserData.trimPpn = trimPpn;
UserData.inputRange = inputRange;
UserData.boxcar = boxcar;

fprintf('Computing error surface...\n')
[surface, density, x, y] = computePFEsurface(EYE, gridN, trimPpn, inputRange, boxcar);

fprintf('Plotting...\n')
axes(getcomponentbytag(f, 'errorSurface'));
if any(strcmpi(varargin, 'density'))
    title('Measured dilation by gaze coordinates')
    image(x, y, density,...
        'CDataMapping', 'scaled');
    cbarLabel = 'N. data points';
elseif any(strcmpi(varargin, 'error'))
    title('Measured dilation by gaze coordinates')
    im = image(x, y, surface,...
        'CDataMapping', 'scaled');
    set(im, 'AlphaData', ~isnan(surface))
    cbarLabel = 'Average measured pupil diameter';
end
set(gca, 'YDir', 'normal');
xlabel('Gaze x');
ylabel('Gaze y');
c = colorbar;
c.Label.String = cbarLabel;

set(f, 'UserData', UserData);

fprintf('done\n')

end