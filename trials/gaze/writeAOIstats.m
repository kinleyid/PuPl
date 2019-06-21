
function writeAOIstats(EYE, varargin)

p = inputParser;
addParameter(p, 'fullpath', []);
addParameter(p, 'setwise', []);
parse(p, varargin{:});

if isempty(p.Results.fullpath)
    [file, dir] = uiputfile('*.csv');
    fullpath = sprintf('%s', dir, file);
else
    fullpath = p.Results.fullpath;
end

% Write stats from individual AOIs?
setwise_opts = {
    'Average of AOI sets'
    'Individual members of AOI sets'
};
if isempty(p.Results.setwise)
    [sel, issel] = listdlg('PromptString', 'Write stats how?',...
        'ListString', setwise_opts);
    if ~issel
        return
    else
        setwise = setwise_opts{sel};
    end
else
    setwise = p.Results.setwise;
end

allstats = unique(mergefields(EYE, 'aoi', 'stat', 'name'));

% I can feel that this isn't the most efficient way to program this part
switch setwise
    case setwise_opts{1} % For each stat, compute the average of AOI set members
        statstable = ['Subject' 'AOIset' allstats]; % Column names
    case setwise_opts{2}
        statstable = ['Subject' 'AOIset' 'AOIname' allstats]; % Column names
end
for dataidx = 1:numel(EYE)
    for aoisetidx = 1:numel(EYE(dataidx).aoiset)
        row = {
            EYE(dataidx).name...
            EYE(dataidx).aoiset(aoisetidx)
        };
        aoiidx = ismember({EYE(dataidx).aoi.name}, EYE(dataidx).aoiset(aoisetidx).members);
        switch setwise
            case setwise_opts{1}
                for statname = allstats
                    statidx = strcmp({EYE(dataidx).aoi(aoiidx).stat.name}, statname{:});
                    row = [row sprintf('%f', nanmean_bc([EYE(dataidx).aoi(aoiidx).stat(statidx).value]))];
                end
            case setwise_opts{2}
                for curraoiidx = find(aoiidx)
                    for statname = allstats
                        row = [row EYE(dataidx).aoi(curraoiidx).name];
                        statidx = strcmp(EYE(dataidx).aoi(curraoiidx).stat.name, statname{:});
                        if ~any(statidx)
                            row = [row ''];
                        else
                            row = [row sprintf('%f', EYE(dataidx).aoi(aoiidx).stat(statidx).value)];
                        end
                    end
                end
        end
        statstable = [
            statstable
            row
        ];
    end
end

writecell(fullpath, statstable, ',');

end