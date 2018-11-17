function plottrials(EYE, varargin)

p = inputParser;
addParameter(p, 'dataIdx', []);
addParameter(p, 'bin', []);
addParameter(p, 'errorBars', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end
    
if isempty(EYE.bin)
    uiwait(msgbox('Organize trials into sets first'));
    return
end

if ~isfield(mergefields(EYE, 'bin', 'data'), 'both')
    uiwait(msgbox('Merge the left and right streams before plotting'));
    return
end

figure; hold on

while true
    if isempty(p.Results.dataIdx)
        dataIdx = listdlg('PromptString', 'Plot from which dataset?',...
            'ListString', {EYE.name},...
            'SelectionMode', 'single');
    else
        dataIdx = p.Results.dataIdx;
    end

    if isempty(p.Results.bin)
        binNames = unique(mergefields(EYE, 'bin', 'name'));
        bin = binNames{listdlg('PromptString', 'Plot from which trial set?',...
            'ListString', binNames,...
            'SelectionMode', 'single')};
    else
        bin = p.Results.bin;
    end
    
    data = EYE(dataIdx).bin(strcmp({EYE(dataIdx).bin.name}, bin)).data.both;
    
    plot(mean(data))
    plot(mean(data) + std(data) / size(data,2), '--k');
    plot(mean(data) - std(data) / size(data,2), '--k');
    
    q = 'Plot more data?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

end