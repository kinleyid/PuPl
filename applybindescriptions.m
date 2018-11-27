function EYE = applybindescriptions(EYE, binDescriptions)

%  Inputs
% EYE--struct array
% binDescriptions--struct array
%  Outputs
% EYE--struct array
%  Description
% Adds a field to EYE called bin, which is a struct array. The data in each
% element of EYE.bin is a numerical array of dimension (n. trials x trial
% length)--I.e., each row 

for dataIdx = 1:numel(EYE)
    fprintf('Merging trials from %s...\n', EYE(dataIdx).name);
    if ~isfield(EYE(dataIdx), 'bin')
        EYE(dataIdx).bin = [];
    else
        EYE(dataIdx).bin = EYE(dataIdx).bin(:)';
    end
    for binIdx = 1:numel(binDescriptions)
        currBin = struct('name', binDescriptions(binIdx).name,...
            'data', []);
        binMembers = find(ismember({EYE(dataIdx).epoch.name},...
            binDescriptions(binIdx).epochs));
        % [EYE(dataIdx).epoch(binMembers).description];
        dataStreams = fieldnames(EYE(dataIdx).epoch(1).data);
        for stream = dataStreams(:)'
            currBin.data.(stream{:}) = [];
            for binMemberIdx = binMembers
                if ~EYE(dataIdx).epoch(binMemberIdx).reject
                    currData = [EYE(dataIdx).epoch(binMemberIdx).data.(stream{:})];
                    currBin.data.(stream{:}) = cat(1, currBin.data.(stream{:}), currData(:)');
                end
            end
        end
        fprintf('Trial set ''%s'' contains data from %d trials\n', binDescriptions(binIdx).name, nnz(binMembers))
        EYE(dataIdx).bin = [EYE(dataIdx).bin currBin];
    end
end

end