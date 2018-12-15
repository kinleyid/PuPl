function eyeheatmap(EYE, varargin)

p = inputParser;
addParameter(p, 'dataIdx', []);
addParameter(p, 'bin', []);
parse(p, varargin{:});

if isempty(EYE)
    uiwait(msgbox('No eye data'));
    return
end
    
if any(arrayfun(@(x) isempty(x.bin), EYE))
    uiwait(msgbox('Organize trials into sets first'));
    return
end

if ~isfield(EYE(1).bin(1).data, 'both')
    uiwait(msgbox('Merge the left and right streams before plotting'));
    return
end

if isempty(p.Results.dataIdx)
    dataIdx = listdlg('PromptString', 'Plot from which dataset?',...
        'ListString', {EYE.name},...
        'SelectionMode', 'single');
    if isempty(dataIdx)
        return
    end
else
    dataIdx = p.Results.dataIdx;
end

if isempty(p.Results.bin)
    binNames = unique(mergefields(EYE, 'bin', 'name'));
    bin = binNames{listdlg('PromptString', 'Plot from which trial set?',...
        'ListString', binNames,...
        'SelectionMode', 'single')};
    if isempty(bin)
        return
    end
else
    bin = p.Results.bin;
end

data = EYE(dataIdx).bin(strcmp({EYE(dataIdx).bin.name}, bin)).data.both;

latencies = 1:size(data, 2);
times = (latencies - 1)/EYE(dataIdx).srate;
figure;
image(times, 1:size(data, 1), data,'CDataMapping','scaled','AlphaData',~isnan(data));
ylabel('Trial')
xlabel('Time (s)')
cb = colorbar;
ylabel(cb, 'Pupil diameter')
title([EYE(dataIdx).name ' ' EYE(dataIdx).bin.name]);

end