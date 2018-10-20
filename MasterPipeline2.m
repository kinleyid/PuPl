%{
cd('Align events')
AlignEvents
cd ..

cd('Filtering')
FilterEyeData
cd ..

cd('Interpolate')
InterpolateEyeData
cd ..

cd('Epoch2')
EpochEyeData
cd ..

cd('Reject epochs')
RejectEpochs
cd ..
%}

cd('Baseline correction')
BaselineCorrection
cd ..

cd('Bin epochs')
BinEpochs
cd ..

cd('Merge left and right')
MergeLeftAndRight
cd ..

cd('Merge eye data')
MergeEyeDataFiles
cd ..

cd('Plot2')
PlotEyeData
cd ..