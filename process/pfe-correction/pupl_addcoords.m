
function EYE = pupl_addcoords(EYE, varargin)

objs = {
    {'camera' 'Camera'}
    {'left' 'Left pupil'}
    {'right' 'Right pupil'}
};

p = inputParser;
for ii = 1:size(objs, 1)
    addParameter(p, objs{ii}{1}, []);
end
parse(p, varargin{:});

% Display explanation
if any(structfun(@isempty, p.Results))
    msg = {
        'NOTE'
        'Enter coordinates in millimeters'
        'The origin (x = 0, y = 0, z = 0) is the top left side of the computer screen'
        'Positive y-direction is downward along the plane defined by the computer''s screen'
        'Positive x-direction is rightward'
        'Positive y-direction is outward from the screen (going from screen to eye)' 
    };
    msgbox(sprintf('%s\n',msg{:}));
end

for ii = 1:size(objs)
    objfield = objs{ii}{1};
    objname = objs{ii}{2};
    if isempty(p.Results.(objfield))
        if any(arrayfun(@(x) ~isnonemptyfield(x.coords, objfield), EYE))
            % Get default coords
            ax = {'x' 'y' 'z'};
            instr = strcat(objname, ax);
            coords = inputdlg(instr);
            if isempty(coords)
                return
            end
            coords = str2double(coords);
            curr = [];
            for jj = 1:numel(ax)
                curr.(ax{jj}) = coords(jj);
            end
        else
            curr = 'none';
        end
    else
        curr = p.Results.objfield;
    end
    eval(sprintf('%s = %s;', objfield, all2str(curr)));
end

fprintf('Adding coordinates...\n');
for dataidx = 1:numel(EYE)
    fprintf('\t%s...', EYE(dataidx).name);
    for ii = 1:size(objs)
        objfield = objs{ii}{1};
        if isnonemptyfield(EYE(dataidx).coords, objfield)
            % Already defined
            continue
        else
            EYE(dataidx).coords.(objfield) = eval(objfield);
        end
    end
    EYE(dataidx).history{end + 1} = getcallstr(p);
    fprintf('done\n');
end
fprintf('Done\n');

end