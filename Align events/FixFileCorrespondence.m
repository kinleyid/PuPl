function [EyeFiles,EventLogFiles] = FixFileCorrespondence(EyeFiles,EventLogFiles)


PreTxt = '';
for i = 1:length(EyeFiles)
    PreTxt = [PreTxt sprintf('%d: %s\n',i,EyeFiles{i})];
end
PreTxt = [PreTxt sprintf('\n')];

Txt = cell(length(EventLogFiles),1);
Txt(1) = {[PreTxt sprintf('[%s] goes with which file above?',EventLogFiles{1})]};
for i = 2:length(Txt)
    Txt(i) = {sprintf('[%s] goes with which file above?',EventLogFiles{i})};
end
Defaults = cell(length(EventLogFiles),1);
for i = 1:length(Defaults)
    if i > length(EyeFiles)
        n = length(EyeFiles);
    else
        n = i;
    end
    Defaults(n) = {sprintf('%d',n)};
end

Idx = inputdlg(Txt,'File correspondence',1,Defaults);
Idx = cellfun(@str2num, Idx);

EventLogFiles = EventLogFiles(Idx);

FormatSpec = 'Matching [%s] with [%s]\n';
for i = 1:length(EyeFiles)
    fprintf(FormatSpec,EyeFiles{i},EventLogFiles{i});
end
fprintf('\n');