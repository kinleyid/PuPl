%{
cd('Align events')
uiwait(msgbox('First, align eye tracker and event log timelines'))
AlignEvents2
cd ..
%}
cd Epoch
uiwait(msgbox('Next, epoch the eye data'))
EpochEyeData
cd ..

cd('Process epoched data')
uiwait(msgbox('Next, process the eye data'))
ProcessEpochedData
cd ..

cd('Attach bin info')
uiwait(msgbox('Next, bin the events'))
AttachBinInfo
cd ..

cd('Condition averages')
uiwait(msgbox('Finally, lump the data together by condition'))
ConditionAverages
cd ..

cd('Plot data')
uiwait(msgbox('Finally, plot the data'))
PlotData
cd ..