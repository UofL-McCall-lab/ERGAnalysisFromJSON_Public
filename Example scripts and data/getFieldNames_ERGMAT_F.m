function [reorgFieldNames] = getFieldNames_ERGMAT_F(formattedMat)
% mattia_Extractor_BATCH.mlx helper to get names for drop down filter
origStructNoAvgStats = rmfield(formattedMat, 'avgStats');
justAvg = extractfield(formattedMat, 'avgStats')';
emptyVec = cellfun(@isempty, justAvg);
tableFormat = struct2table(justAvg{find(~emptyVec, 1)}, 'AsArray', true);
finalStruct = table2struct(repmat(tableFormat, [numel(justAvg), 1])); % Full populated with first data
for N = 1:numel(justAvg)
    if isempty(justAvg{N})
        finalStruct(N).finalAverage = NaN; % Don't need to set all correctly, just change nan to help keep track
        continue;
    end
    finalStruct(N).finalAverage = justAvg{N}.finalAverage;
    finalStruct(N).minVal = justAvg{N}.minVal;
    finalStruct(N).maxVal = justAvg{N}.maxVal;
    finalStruct(N).aWave = justAvg{N}.aWave;
    finalStruct(N).bWave = justAvg{N}.bWave;
    finalStruct(N).TTP = justAvg{N}.TTP;
    finalStruct(N).TTT = justAvg{N}.TTT;
    finalStruct(N).smoothMethod = justAvg{N}.smoothMethod;
    finalStruct(N).smoothWindow = justAvg{N}.smoothWindow;
    if isfield(justAvg{N}, 'searchWindows_ms')
        % These fields added with newer data format
        finalStruct(N).searchWindows_ms = justAvg{N}.searchWindows_ms;
        finalStruct(N).searchWindows_rowTypes = justAvg{N}.searchWindows_rowTypes;
    end
end
reorgStruct = table2struct(horzcat(struct2table(origStructNoAvgStats), struct2table(finalStruct)));
clearvars formattedMat finalStruct justAvg origStructNoAvgStats
reorgFieldNames = string(fieldnames(reorgStruct));
end