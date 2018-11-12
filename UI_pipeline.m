% function UI_pipeline
%{
% Format data
uiwait(msgbox('Format the eye data'));
EYE = pupl_format('type', 'eye data');
uiwait(msgbox('Format the event logs'));
eventLogs = pupl_format('type', 'event logs');
%}
EYE = getfakeeyedata;
pupl_save('data', EYE, 'type', 'eye data');
%{
% Write event log events to eye data
uiwait(msgbox('Write events from event logs to eye data'));
EYE = attachevents(EYE, 'eventLogs', eventLogs);
%}
EYE = eyefilter(EYE);
EYE = interpeyedata(EYE);
EYE = mergelr(EYE);

uiwait(msgbox('Epoch the data'));
EYE = epoch(EYE);

uiwait(msgbox('Bin the epochs'));
EYE = binepochs(EYE);

writetospreadsheet(EYE);

% end