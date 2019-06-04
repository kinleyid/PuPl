
function EYE = defineAOIs(EYE, varargin)

% Populates aoi field of EYE
%   Inputs:
% EYE: struct array
% type: 'rect' 'poly' 'circ' 'ellipse'
% aoidescs: AOI decsriptions, struct array with fields:
%   coords: [x y w h]
%   spandesc: span description struct
%   Outputs:
% EYE: struct array with aoi field populated

callstr = sprintf('eyeData = %s(eyeData, ', mfilename);
p = inputParser;
addParameter(p, 'type', 'rect');
addParameter(p, 'aoidescs', []);
parse(p, varargin{:});

if isempty(p.Results.aoidescs)
    aoidescs = UI_getaoidescs(EYE, p.Results.type);
    if isempty(aoidescs)
        return
    end
else
    aoidescs = p.Results.aoidescs;
end
callstr = sprintf('%s''aoidescs'', %s)', callstr, all2str(aoidescs));

fprintf('Defining areas of interest (AOIs)...\n')
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    for aoiidx = 1:numel(aoidescs)
        currAOIdesc = aoidescs{aoiidx};
        allLatencies = spandesc2lats(EYE(dataidx), currAOIdesc.spandesc);
        for latidx = 1:numel(allLatencies)
            currAOI = struct(...
                'name', currAOIdesc.spandesc.name,...
                'type', 'polygon',...
                'absLatencies', allLatencies{latidx},...
                'gaze', struct(...
                    'x', EYE(dataidx).gaze.x(allLatencies{latidx}),...
                    'y', EYE(dataidx).gaze.y(allLatencies{latidx})...
                    ),...
                'stats', struct([])...
            );
            switch p.Results.type
                case 'rect'
                    currAOI.coords = struct(...
                        'x', repmat([
                            currAOIdesc.coords(1)
                            currAOIdesc.coords(1)
                            currAOIdesc.coords(1) + currAOIdesc.coords(3)
                            currAOIdesc.coords(1) + currAOIdesc.coords(3)
                            ], 1, numel(allLatencies{latidx})),...
                        'y', repmat([
                            currAOIdesc.coords(2)
                            currAOIdesc.coords(2) + currAOIdesc.coords(4)
                            currAOIdesc.coords(2)
                            currAOIdesc.coords(2) + currAOIdesc.coords(4)
                            ], 1, numel(allLatencies{latidx}))...
                        );
                case 'poly'
                    currAOI.coords = struct(...
                        'x', repmat(currAOIdesc.coords.x(:), 1, numel(allLatencies{latidx})),...
                        'y', repmat(currAOIdesc.coords.y(:), 1, numel(allLatencies{latidx}))...
                        );
                case 'circ'
                    currAOI.coords = struct(...
                        'x', repmat(currAOIdesc.coords(1), 1, numel(allLatencies{latidx})),...
                        'y', repmat(currAOIdesc.coords(2), 1, numel(allLatencies{latidx})),...
                        'a', repmat(currAOIdesc.coords(3), 1, numel(allLatencies{latidx})),...
                        'b', repmat(currAOIdesc.coords(3), 1, numel(allLatencies{latidx}))...
                        );
                case 'ellipse'
                    currAOI.coords = struct(...
                        'x', repmat(currAOIdesc.coords(1), 1, numel(allLatencies{latidx})),...
                        'y', repmat(currAOIdesc.coords(2), 1, numel(allLatencies{latidx})),...
                        'a', repmat(currAOIdesc.coords(3), 1, numel(allLatencies{latidx})),...
                        'b', repmat(currAOIdesc.coords(4), 1, numel(allLatencies{latidx}))...
                        );
            EYE(dataidx).aoi = cat(1, EYE(dataidx).aoi, currAOI);
        end
    end
    EYE(dataidx).history = cat(1, EYE(dataidx).history, callstr);
end
fprintf('Done\n');

end

function aoidescs = UI_getaoidescs(EYE, type)

aoidescs = struct([]);
while true
    switch type
        case 'rect'
            coords = inputdlg({sprintf('Coordinates:\n\nx') 'y' 'width' 'height'}, 'Coordinates');
        case 'poly'
            coords = inputdlg({sprintf('Polygon coordinates\n\nx') 'y'}, 'Coordinates');
        case 'circ'
            coords = inputdlg({sprintf('Coordinates:\n\nx') 'y' 'radius'}, 'Coordinates');
        case 'ellipse'
            coords = inputdlg({sprintf('Coordinates for x2/a2 + y2/b2 = 1\n\nx') 'y' 'a (semi-major axis)' 'b (semi-minor axis)'}, 'Coordinates');
    end
    if any(cellfun(@isempty, coords)) || isempty(coords)
        aoidescs = [];
        return
    end
    spandesc = UI_getspandescs(EYE, 'spanName', 'AOI', 'basic', 'off', 'n', 'single');
    if isempty(spandesc)
        aoidescs = [];
        return
    end
    aoidescs = cat(2, aoidescs, struct(...
        'coords', str2num(coords{:}),...
        'spandesc', spandesc));
    q = 'Define more AOIs?';
    a = questdlg(q, q, 'Yes', 'No', 'Cancel');
    switch a
        case 'Yes'
            continue
        case 'No'
            break
        otherwise
            aoidescs = [];
            return
    end
end

end