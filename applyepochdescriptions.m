function EYE = applyepochdescriptions(EYE, epochDescriptions, rejectionThreshold)

% Adds 'epoch' field to EYE structs
%   Inputs
% EYE--struct array
% epochDescriptions--struct array
% rejection threshold--number from 0 to 1
%   Outputs
% EYE--struct array

for dataIdx = 1:numel(EYE)
    fprintf('Epoching %s...\n', EYE(dataIdx).name)
    if ~isfield(EYE(dataIdx), 'epoch')
        EYE(dataIdx).epoch = [];
    else
        EYE(dataIdx).epoch = EYE(dataIdx).epoch(:)';
    end
    for epochIdx = 1:numel(epochDescriptions)
        spans = getlatenciesfromspandescription(EYE(dataIdx),...
            epochDescriptions(epochIdx));
        for spanIdx = 1:numel(spans)
            currEpoch = struct(...
                'description', epochDescriptions(epochIdx),...
                'latencies', spans{spanIdx},...
                'name', epochDescriptions(epochIdx).name);  
            for stream = reshape(fieldnames(EYE(dataIdx).data), 1, [])
                currEpoch.data.(stream{:}) = EYE(dataIdx).data.(stream{:})(currEpoch.latencies);
            end
            % Decide based on EYE(dataIdx).urData whether to reject
            urData = [EYE(dataIdx).urData.left(currEpoch.latencies)...
                      EYE(dataIdx).urData.right(currEpoch.latencies)];
            if nnz(isnan(urData))/numel(urData) > rejectionThreshold
                currEpoch.reject = true;
            else
                currEpoch.reject = false;
            end
            
            EYE(dataIdx).epoch = [EYE(dataIdx).epoch currEpoch];
        end
    end
    fprintf('%d discrete trials created\n', numel(EYE(dataIdx).epoch))
end
fprintf('Finished epoching\n');
end
