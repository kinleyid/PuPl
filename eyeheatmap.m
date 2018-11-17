function eyeheatmap(EYE, varargin)

p = inputParser;
addParameter(p, 'dataIdx', []);
addParameter(p, 'bin', []);
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

latencies = 1:size(data, 2);
times = (latencies - 1)/EYE(dataIdx).srate;
figure;
image(times, 1:size(data, 1), data,'CDataMapping','scaled')
ylabel('Trial')
xlabel('Time (s)')

end