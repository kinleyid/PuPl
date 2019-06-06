
function EYE = computeAOIstats(EYE, varargin)

% Populates EYE.aoi.stats field

p = inputParser;
addParameter(p, 'stats', []);
parse(p, varargin{:});
callstr = sprintf('eyeData = %s(eyeData, ', mfilename);

statOptions = {
    'Time to first fixation' @(isinaoi, srate, datalabel) find(isinaoi, 1)*srate;
    'Time spent' @(isinaoi, srate, datalabel) (sum(isinaoi) - 1)*srate;
    'N. fixations' @(isinaoi, srate, datalabel) sum(isinaoi & [false diff(datalabel == 'f') == 1 false])
    'N. visits' @(isinaoi, varargin) sum(diff(isinaoi) == 1);
    'First fixation duration' @(isinaoi, srate, datalabel)...
        srate*(find(isinaoi & datalabel == 's', 1) - find(isinaoi, 1))
    'Average fixation duration' @afd
};
if isempty(p.Results.stats)
    stats = statOptions(listdlgregexp('PromptString', 'Compute which stats?',...
            'ListString', statOptions(:, 1)), 1);
    if isempty(stats)
        return
    end
else
    stats = p.Results.stats;
end
callstr = sprintf('%s''stats'', %s)', callstr, all2str(stats));

for dataidx = 1:numel(EYE)
    x = EYE(dataidx).gaze.x;
    y = EYE(dataidx).gaze.y;
    srate = EYE(dataidx).srate;
    for aoiidx = 1:numel(EYE(dataidx).aoi)
        aoi = EYE(dataidx).aoi(aoiidx);
        switch aoi.type
            case 'polygon'
                isinaoi = arrayfun(@(lat)...
                    inpolygon(...
                        aoi.gaze.x(lat),...
                        aoi.gaze.y(lat),...
                        aoi.coords.x(:, lat),...
                        aoi.coords.y(:, lat)),...
                    aoi.absLatencies);
            case 'ellipse'
                isinaoi = ((aoi.gaze.x - aoi.coords.x)*cos(aoi.coords.theta) +...
                           (aoi.gaze.y - aoi.coords.y)*sin(aoi.coords.theta) ./ aoi.coords.a).^2 +...
                          ((aoi.gaze.y - aoi.coords.y)*sin(aoi.coords.theta) +...
                           (aoi.gaze.x - aoi.coords.x)*cos(aoi.coords.theta) ./ aoi.coords.b).^2 < 1;
        end
        for statidx = find(ismember(statOptions(:, 1), stats))
            EYE(dataidx).aoi(aoiidx).stats = cat(2, EYE(dataidx).aoi(aoiidx).stats,...
                struct(...
                    'name', statOptions{statidx, 1},...
                    'stat', feval(statOptions{statidx, 2},...
                                    isinaoi,...
                                    srate,...
                                    EYE(dataidx).datalabel(EYE(dataidx).aoi(aoiidx).absLatencies(1:end-1)))));
        end
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end

end

function d = afd(isinaoi, srate, datalabel)

% This won't work for moving AOIs--rewrite
starts = isinaoi & [false diff(datalabel == 'f') == 1 false];
ends = isinaoi & [false diff(datalabel == 'f') == -1 false];
d = mean(find(starts) - find(ends)) * srate;

end