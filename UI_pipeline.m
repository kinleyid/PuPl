% function UI_pipeline
%{
% Format data
uiwait(msgbox('Format the eye data'));
EYE = formatdata('type', 'eye data');
uiwait(msgbox('Format the event logs'));
eventLogs = formatdata('type', 'event logs');

% Write event log events to eye data
uiwait(msgbox('Write events from event logs to eye data'));
EYE = attachevents(EYE);
%}

EYE = getfakeeyedata;

EYE = eyefilter(EYE, 'saveTo', 'none');
EYE = interpeyedata(EYE, 'saveTo', 'none');
EYE = mergelr(EYE, 'saveTo', 'none');

uiwait(msgbox('Epoch the data'));
EYE = epoch(EYE, 'saveTo', 'none');
%}
uiwait(msgbox('Bin the epochs'));
EYE = binepochs(EYE);

% end