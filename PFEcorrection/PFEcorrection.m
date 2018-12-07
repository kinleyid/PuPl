function EYE = PFEcorrection(EYE, varargin)

% This function makes a few assumptions:
% 1. the data stored in EYE.data is pupil diameter, not pupil area
% 2. On average, the participant is looking at the middle of the screen

% However, it makes no assumptions about the units that pupil diameter are
% measured in nor the units that the gaze coordinates are measured in

for dataIdx = 1:numel(EYE)
    params = cell(1, nargout(@UI_getPFEsurfaceparams));
    [params{:}] = UI_getPFEsurfaceparams(EYE);
    if isempty(params{1})
        EYE = [];
        return
    end
    
    if params{end}
        EYE.gaze.y = -EYE.gaze.y;
    end
    
    params = params(1:end-1);
    
    initialValues = [
        rand - 0.5                          % 1 Cx Should be approx. 0
        -1.5*range(EYE.gaze.y)              % 2 Cy Roughly one screen height above camera
        8*range(EYE.gaze.y)                 % 3 Cz Roughly 4 screen heights distance from camera
        median(EYE.gaze.x, 'omitnan')       % 4 Tx0 Participant should be looking roughly at center of screen
        median(EYE.gaze.y, 'omitnan')       % 5 Ty0 Ditto
        9*range(EYE.gaze.y)                 % 6 Tz One screen height distance between camera and screen
    ];
    options = optimset('PlotFcns',@optimplotfval);
    optimFunc = @(v) pfe(v(1), v(2), v(3), v(4), v(5), v(6), EYE, params{:});
    c = fminsearch(optimFunc, initialValues, options);
    % c = initialValues;
    coords = struct(...
        'Cx', c(1),...
        'Cy', c(2),...
        'Cz', c(3),...
        'Tx0', c(4),...
        'Ty0', c(5),...
        'Tz', c(6));
    
    tmpEYE = applyPFEcorrection(EYE,coords);
    [d, x, y] = computePFEsurface(EYE, params{:});
    d0 = computePFEsurface(tmpEYE, params{:});
    figure;
    subplot(1,2,1)
    image(x,y,d,'cDataMapping','scaled','AlphaData',~isnan(d)); colorbar
    title('Before PFE correction')
    subplot(1,2,2)
    image(x,y,d0,'cDataMapping','scaled','AlphaData',~isnan(d0)); colorbar
    title('After PFE correction')
    if isempty(UI_getPFEsurfaceparams(tmpEYE))
        EYE = [];
        return
    end
    EYE(dataIdx) = tmpEYE;
end

end

function err = pfe(Cx, Cy, Cz, Tx0, Ty0, Tz, EYE, varargin)

coords = struct(...
    'Cx', Cx,...
    'Cy', Cy,...
    'Cz', Cz,...
    'Tx0', Tx0,...
    'Ty0', Ty0,...
    'Tz', Tz);

EYE = applyPFEcorrection(EYE, coords);

d0 = computePFEsurface(EYE, varargin{:});
err = mean(((d0(:) - mean(d0(:), 'omitnan'))/mean(d0(:), 'omitnan')).^2, 'omitnan');
% err = mean(abs((d0(:) - mean(d0(:), 'omitnan'))), 'omitnan');

end