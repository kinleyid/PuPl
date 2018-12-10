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
    
if any(arrayfun(@(x) isempty(x.bin), EYE))
    uiwait(msgbox('Organize trials into sets first'));
    return
end

if ~isfield(mergefields(EYE, 'bin', 'data'), 'both')
    uiwait(msgbox('Merge the left and right streams before plotting'));
    return
end

f = figure('Visible', 'off'); hold on
xlabel('Time (s)');

while true
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
    
    x = 1:size(data, 2);
    t = (x - 1)/EYE(dataIdx).srate;
    f.Visible = 'on';
    figure(f);
    plot(t, mean(data, 'omitnan'))
    plot(t, mean(data, 'omitnan') + std(data, 'omitnan') ./ sum(~isnan(data)), '--k');
    plot(t, mean(data, 'omitnan') - std(data, 'omitnan') ./ sum(~isnan(data)), '--k');
    q = 'Add more data to this plot?';
    a = questdlg(q, q, 'Yes', 'No', 'Yes');
    if strcmp(a, 'No')
        return
    end
end

    end