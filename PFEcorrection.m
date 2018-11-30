function [c, err] = PFEcorrection(EYE, varargin)

% This function makes a few assumptions:
% 1. the data stored in EYE.data is pupil diameter, not pupil area
% 2. On average, the participant is looking at the middle of the screen

% However, it makes no assumptions about the units that pupil diameter are
% measured in nor the units that the gaze coordinates are measured in

errorSurface = getPFEerrorsurface(EYE);

[Cx, Tx] = deal(median(errorSurface.x));

if isfield(EYE.data, 'both')
    dilation = EYE.data.both;
else
    dilation = mean([EYE.data.left; EYE.data.right], 'omitnan');
end

badIdx = isnan(dilation) | isnan(EYE.gaze.x) | isnan(EYE.gaze.y) | EYE.isBlink;

params = {};
errs = {};
relTx = {};
relTy = {};

gridN = 32;
boxCar = 5;
trimPpn = 0.3;
sorteds = structfun(@(v) sort(v(~badIdx)), EYE.gaze, 'un', 0);
ranges = structfun(@(v)...
            linspace(v(max(round(trimPpn*numel(v)), 1)),...
                     v(min(round((1 - trimPpn)*numel(v)), numel(v))),...
                     gridN),...
    sorteds, 'un', 0);
widths = structfun(@(x) (x(2) - x(1))*boxCar, ranges, 'un', 0);

dilation = pi*(EYE.data.both/2).^2;
averages = nan(gridN);

for xi = 1:numel(ranges.x)
    for yi = 1:numel(ranges.y)
        currIdx = abs(EYE.gaze.x - ranges.x(xi)) <= widths.x...
            & abs(EYE.gaze.y - ranges.y(yi)) <= widths.y...
            & ~badIdx;
        averages(yi, xi) = mean(dilation(currIdx), 'omitnan');
    end
end

Tx = sort(reshape(repmat(ranges.x(:), 1, numel(ranges.y)), [], 1));
Ty = reshape(repmat(ranges.y(:), 1, numel(ranges.x)), [], 1);
D = averages(:);
figure;
subplot(2, 2, 1)
image(Tx, Ty, reshape(D, gridN, gridN), 'CDataMapping', 'scaled');
colorbar;
prevColourLims = caxis;

% R(1) := Cx
% R(2) := Cy
% R(3) := Cz
% R(4) := Tz -- unsafely assumed constant
% R(5) := Tx offset
% R(6) := Ty offset
% R(7) := A0

error = @(R) sum(...
    ( ...
        D ./ ( ... % Measured diameters
            R(1)*(Tx + R(5)) + R(2)*(Ty + R(6)) + R(3)*R(4) ./ ( ... Correction factor numerator
                sqrt(R(1)^2 + R(2)^2 + R(3)^2) * sqrt((Tx + R(5)).^2 + (Ty + R(6)).^2 + R(4)^2) ... Correction factor denominator
                ) ...
            ) ...
        - (1.2*max(D)) ... Theoretical true pupil area
    ).^2 ... Square error
);
initialValues = [
    rand - .5 % Cx Should be approx. 0
    -range(Ty) % Cy Roughly one screen height above camera
    4*range(Ty) % Cz Roughly 4 screen heights distance from camera
    5*range(Ty) % Tz One screen height distance between camera and screen
    % max(D) + median(D) % A0 Slightly more than the max. measured value
    -median(Tx) % Tx offset Participant should be looking roughly at center of screen
    -median(Ty) % Ty offset Ditto
];
[R, err] = fminsearch(error, initialValues)

newD = D ./ ( ... % Measured diameters
    R(1)*(Tx + R(5)) + R(2)*(Ty + R(6)) + R(3)*R(4) ./ ( ... Correction factor numerator
        sqrt(R(1)^2 + R(2)^2 + R(3)^2) * sqrt((Tx + R(5)).^2 + (Ty + R(6)).^2 + R(4)^2) ... Correction factor denominator
        ) ...
    );
subplot(2, 2, 2)
image(Tx, Ty, reshape(newD, gridN, gridN), 'CDataMapping', 'scaled')
colorbar;
caxis(prevColourLims);

subplot(2, 2, [3 4])
correctionFactor = 1 ./ ( ... % Measured diameters
    R(1)*(Tx + R(5)) + R(2)*(Ty + R(6)) + R(3)*R(4) ./ ( ... Correction factor numerator
        sqrt(R(1)^2 + R(2)^2 + R(3)^2) * sqrt((Tx + R(5)).^2 + (Ty + R(6)).^2 + R(4)^2) ... Correction factor denominator
        ) ...
    );
image(Tx, Ty, reshape(correctionFactor, gridN, gridN), 'CDataMapping', 'scaled');
colorbar;

figure;
image(Tx, Ty, reshape(newD, gridN, gridN), 'CDataMapping', 'scaled')
colorbar;
title('Corrected')