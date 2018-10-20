function ConditionAverages

Answer = inputdlg('How many conditions are there?');
nConds = str2double(Answer);

CondNames = cell(nConds,1);
for i = 1:nConds
    CondNames(i) = inputdlg(sprintf('Name of condition %d',i));
end

CondFiles = [];
for i = 1:nConds
    uiwait(msgbox(sprintf('Which files are part of condition ''%s''?',CondNames{i})));
    [Filenames,Path] = uigetfile('..\..\..\*.mat',...
        sprintf('Which files are part of condition ''%s''?',CondNames{i}),...
        'MultiSelect','on');
    Filenames = cellstr(Filenames);
    CondFiles(i).Path = Path;
    CondFiles(i).Files = Filenames;
end

uiwait(msgbox('Select a folder to save the condition averages to.'));
SaveTo = uigetdir([Path '\..'],'Select a folder to save the combined condition data to.');

for i = 1:nConds
    CondEYE = [];
    CondEYE.srate = [];
    CondEYE.epochinfo = [];
    CondEYE.bins = [];
    Filenames = CondFiles(i).Files;
    Path = CondFiles(i).Path;
    for Filename = Filenames
        MatData = load([Path '\' Filename{:}]);
        EYE = MatData.EYE;
        
        % Check consistency/initialize CondEYE fields
        if isempty(CondEYE.srate)
            CondEYE.srate = EYE.srate;
        else
            if CondEYE.srate ~= EYE.srate
                error('Unequal sample rates')
            end
        end
        if isempty(CondEYE.epochinfo)
            CondEYE.epochinfo = EYE.epochinfo;
        else
            for Field = fields(EYE.epochinfo)'
                if ~all(EYE.epochinfo.(Field{:}) == CondEYE.epochinfo.(Field{:}))
                    error('Incompatible epochs')
                end
            end
        end
        if isempty(CondEYE.bins)
            CondEYE.bins = EYE.bins;
            [CondEYE.bins.data] = deal([]);
        else
            for j = 1:length(EYE.bins)
                if ~strcmp(EYE.bins(j).name,CondEYE.bins(j).name)
                    error('Attempted to match %s with %s',EYE.bins(j).name,CondEYE.bins(j).name)
                end
                for k = 1:length(EYE.bins(j).events)
                    if ~strcmp(EYE.bins(j).events{k},CondEYE.bins(j).events{k})
                        error('File %s contains %d events in bin ''%s'', should contain %d',Filename{:},length(EYE.bins(j).event),EYE.bins(j).name)
                    end
                end
            end
        end
        
        % Combine data
        for Idx = 1:length(EYE.bins)
            CondEYE.bins(Idx).data = cat(1,CondEYE.bins(Idx).data,EYE.bins(Idx).data);
        end
    end
    CondEYE.cond = CondNames{i};
    Name = CondNames{i};
    save([SaveTo '\' Name '.mat'],'EYE');
end