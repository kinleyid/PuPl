function EYE = GetEYESpecs(EYE)

% Ask user for specifics of eye file

Answers = inputdlg({'Name of file' 'Sample rate (Hz)'},'Alter eye data',1,{EYE.name,num2str(EYE.srate)});

EYE.name = Answers{1};
EYE.srate = str2double(Answers{2});

end