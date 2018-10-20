
function InterpolateEyeData

Question = 'Select the eye data for interpolating';
uiwait(msgbox(Question));
[Filenames,Path] = uigetfile('..\..\..\*.mat',...
    Question,...
    'MultiSelect','on');
Filenames = cellstr(Filenames);

Question = 'Select a folder to save the interpolated eye data to';
uiwait(msgbox(Question));
SaveTo = uigetdir([Path '\..'],...
    Question);

for Filename = Filenames
    MatData = load([Path Filename{:}]);
    EYE = MatData.EYE;
    fprintf('Interpolating [%s]\n',EYE.name);
    if isfield(EYE,'epochs')
        for EpochIdx = 1:numel(EYE.epochs)
            FieldNames = fieldnames(EYE.epochs(EpochIdx).data);
            for FieldName = FieldNames(:)'
                EYE.epochs(EpochIdx).data.(FieldName{:}) = InterpolateVector(EYE.epochs(EpochIdx).data.(FieldName{:}));
            end
        end
    end
    if isfield(EYE,'bins')
        for BinIdx = 1:numel(EYE.bins)
            FieldNames = fieldnames(EYE.bins(EpochIdx).data);
            for FieldName = FieldNames(:)'
                for i = 1:size(EYE.data.bins(BinIdx).(FieldName{:}),1)
                    EYE.bins(BinIdx).data.(FieldName{:})(i,:) = InterpolateVector(EYE.bins(BinIdx).data.(FieldName{:})(i,:));
                end
            end
        end
    end
    fprintf('Replicating uninterpolated continuous data as ''urdata'' for rejection purposes\n');
    EYE.urdata = EYE.data;
    FieldNames = fieldnames(EYE.data);
    for FieldName = FieldNames(:)'
        EYE.data.(FieldName{:}) = InterpolateVector(EYE.data.(FieldName{:}));
    end
    fprintf('Saving [%s] to [%s]\n',Filename{:},SaveTo)
    save([SaveTo '\' EYE.name '.mat'],'EYE');
end

end

function Vector = InterpolateVector(Vector)

Vector(isnan(Vector)) = interp1(find(~isnan(Vector)), Vector(~isnan(Vector)), find(isnan(Vector)) );

end