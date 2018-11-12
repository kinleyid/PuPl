% function UI_pipeline
%{
% Format data
uiwait(msgbox('Format the eye data'));
EYE = formatdata('type', 'eye data');
uiwait(msgbox('Format the event logs'));
eventLogs = formatdata('type', 'event logs');

% Write event log events to eye data
uiwait(msgbox('Write events from event logs to eye data'));
EYE = attachevents(EYE, 'eventLogs', eventLogs);
%}
%{
EYE = getfakeeyedata;

EYE = eyefilter(EYE);
EYE = interpeyedata(EYE);
EYE = mergelr(EYE);

uiwait(msgbox('Epoch the data'));
EYE = epoch(EYE, 'saveTo', 'none');

uiwait(msgbox('Bin the epochs'));
EYE = binepochs(EYE);
%}
% EYE = loadeyedata;

writetospreadsheet(EYE);

% end