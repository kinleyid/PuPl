function UI_pipeline

% Format data
uiwait(msgbox('Format the eye data'));
EYE = pupl_format('type', 'eye data');
pupl_save('data', EYE, 'type', 'eye data');
uiwait(msgbox('Format the event logs'));
eventLogs = pupl_format('type', 'event logs');
pupl_save('data', eventLogs, 'type', 'event logs');

% Write event log events to eye data
uiwait(msgbox('Write events from event logs to eye data'));
EYE = attachevents(EYE, 'eventLogs', eventLogs);

% Process the data
uiwait(msgbox('Filter the data'));
EYE = eyefilter(EYE);
EYE = interpeyedata(EYE);
EYE = mergelr(EYE);

% Organize the data into trials
uiwait(msgbox('Epoch the data'));
EYE = epoch(EYE);
uiwait(msgbox('Bin the epochs'));
EYE = binepochs(EYE);

% Write the data to a spreadsheet
writetospreadsheet(EYE);

end