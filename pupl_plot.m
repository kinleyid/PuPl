function pupl_plot(EYE, varargin)

p = inputParser;
addParameter(p, 'dataIdx', []);
addParameter(p, 'bin', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end

if isempty(p.Resuslts.dataIdx)
    if isfield(EYE, cond)
        q = 'Epoch by condition?';
        a = questdlg(q, q, 'Yes', 'No', 'Yes');
        if strcmp(a, 'Yes')
            
        end
    else
        
    end
else
    dataIdx = p.Results.dataIdx;
end

if isempty(p.Results.bin)
    
else
    bin = p.Results.bin;
end

end