
function pupl_BIDS_save(EYE, varargin)

if isempty(varargin)
    datapath = uigetdir(pwd, 'Select data folder (e.g. sourcedata/)');
    if datapath == 0
        return
    end
else
    datapath = varargin{1};
end

for dataidx = 1:numel(EYE) % Populate
    masterfilehead = getfilehead(EYE(dataidx).BIDS);
    currfilehead = fullfile(datapath, masterfilehead);
    mkdir(fileparts(currfilehead)); % Create folder
    pupl_save(EYE(dataidx), sprintf('%s_eyetrack', currfilehead));
    curreventlog = EYE(dataidx).eventlog;
    if ~isempty(curreventlog)
        fprintf('\t');
        eventlog2tsv(curreventlog, sprintf('%s_events.tsv', currfilehead));
    end
    fprintf('done\n');
end

if ~isempty(gcbf)
    global pupl_globals
    fprintf('Equivalent command:\n%s(%s, %s)\n\n', mfilename, pupl_globals.datavarname, all2str(datapath));
end

end

function filehead = getfilehead(BIDS)

currpath = sprintf('sub-%s/', BIDS.sub);
% Session-specific data?
if isfield(BIDS, 'ses')
    sespath = fullfile(currpath, sprintf('ses-%s', BIDS.ses));
    currpath = sespath;
end
currpath = fullfile(currpath, 'eyetrack');
filehead = fullfile(currpath, sprintf('sub-%s', BIDS.sub));
for field = {'ses' 'task' 'acq'  'run' 'recording' 'proc'}
    if isfield(BIDS, field{:})
        if ~isempty(BIDS.(field{:}))
            filehead = sprintf('%s_%s-%s', filehead, field{:}, BIDS.(field{:}));
        end
    end
end

end