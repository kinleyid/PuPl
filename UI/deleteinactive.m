function deleteinactive(dataType)

global userInterface

UserData = get(userInterface, 'UserData');
switch dataType
    case 'eye data'
        global eyeData
        dots = repmat({sprintf(' _ ')}, 1, numel(eyeData));
        dots(UserData.activeEyeDataIdx) = {' > '};
        [rmidx, ch] = listdlg(...
            'ListString', strcat(dots, {eyeData.name}),...
            'PromptString', 'Remove which?');
        if ch == 0
            return
        end
        % currIdx = ~UserData.activeEyeDataIdx;
        fprintf('Removing data...\n');
        for curridx = reshape(find(rmidx), 1, [])
            fprintf('\t%s\n', eyeData(curridx).name);
        end
        fprintf('Done\n');
        eyeData(rmidx) = [];
        UserData.activeEyeDataIdx(rmidx) = [];
    case 'event logs'
        global eventLogs
        rmidx = ~UserData.activeEventLogsIdx;
        fprintf('Removing data...\n');
        for currData = reshape(eventLogs(rmidx), 1, [])
            fprintf('\t%s\n', currData.name);
        end
        fprintf('Done\n');
        eventLogs(rmidx) = [];
        UserData.activeEventLogsIdx(rmidx) = [];
end

set(userInterface, 'UserData', UserData);

end