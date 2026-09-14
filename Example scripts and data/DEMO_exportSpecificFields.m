clc
close all
clear
addpath(genpath('Example data'));
% Notes and tips:
%{
    - Always filter by removing rows, not columns. You pick what to export
    at the very end from specific fields.
    - Each section will have its own controls (see FILTER 3 for example).
    - You can package this kind of filtering/reshaping into a function if
    desired. This makes it much easier to use with a loop (if looping over
    multiple .mat files in a folder).

David Alston 11-2024
david.alston@louisville.edu
%}
%% Load the .mat to filter
load('Olix (Baseline)_step4Mat'); % Change this to any .mat you have (must have some .avgStats data)
%% We have the original formattedMat, first I make a copy of it to work with
filteredMat = formattedMat;
originalNRows = numel(formattedMat); % Number of rows before any filtering
%% FILTER 1 - Now I will remove rows I don't want from this new mat, starting with .toUse == false rows 
% First, remove any rows that have .toUse == false (see .remReason as to why these should not be used).
% Data structure that consists of just a single column or just a single row = a vector.
toUseVector = [filteredMat.toUse].'; % Get just .toUse as a single column array of boolean (true/false).  Is the same size as filteredMat
filteredMat(~toUseVector) = []; % ~ inverts toUseVector (true -> false and vice versa). Now anywhere we don't want has a "true" value in the row.
% ^ We can pass that to filteredMat as target rows, then [] clears them
afterToUseRemovalNRows = numel(filteredMat);
fprintf('Removing .toUse == false removed %i of %i rows (%i remain)\n', ...
    originalNRows - afterToUseRemovalNRows, ...
    originalNRows, ...
    numel(filteredMat));
%% FILTER 2 - Lets say I only want right eye data. This removes any rows that are not 'R' as the 'Wavelabel'
wavelabelCellVector = {filteredMat.Wavelabel}.'; % Single column array of cells (cell is a Matlab structure that can hold mixed data types)
containsRVector = contains(wavelabelCellVector, 'R', 'IgnoreCase', true); % True in any rows that are 'R' (case insensitive)
filteredMat(~containsRVector) = [];
afterRRemovalNRows = numel(filteredMat);
fprintf('Removing non R eyes removed %i of %i rows (%i remain)\n', ...
    afterToUseRemovalNRows - afterRRemovalNRows, ...
    afterToUseRemovalNRows, ...
    numel(filteredMat));
%% FILTER 3 - For the final filter, I only want data from .StepNumber == 3 and .StepNumber == 4 (see typeNames)
targetStepNumbers = [3, 4]; %[3, 4] to find 3 and 4, [3] to find just 3, etc.
stepNumberVector = [filteredMat.StepNumber].'; % Contains the .StepNumber per row
containsTargetsVector = ismember(stepNumberVector, targetStepNumbers);
filteredMat(~containsTargetsVector) = [];
afterStepRemovalNRows = numel(filteredMat);
fprintf('Removing all but target .StepNumber(s) removed %i of %i rows (%i remain)\n', ...
    afterRRemovalNRows - afterStepRemovalNRows, ...
    afterRRemovalNRows, ...
    numel(filteredMat));
%% Lets say that is all the filtering I wanted. Now I want to pick specific field(s) to export to excel
clearvars -except filteredMat formattedMat % This isn't neccesary, but helps keep the workspace clean. Don't need filtering variables etc
%% First, convert filteredMat into a table so it can be sorted (date order, then all R if have R/L, then by Lastname so in animal ID order)
% Helps standardize excel data
toExport_asTbl = struct2table(filteredMat);
toExport_asTbl = sortrows(toExport_asTbl, 'Testtime', 'ascend'); % Even though year is 1899, the time in HH:MM:SS looks to be incremental
toExport_asTbl = sortrows(toExport_asTbl, 'Wavelabel', 'descend'); % all 'R' rows, then all 'L' rows.
toExport_asTbl = sortrows(toExport_asTbl, 'Lastname', 'ascend'); % If name starts with number, this will be correct (3912, then 3913, etc)
toExportStruct = table2struct(toExport_asTbl); % Convert sorted table back into struct
fprintf('Reordered struct now stored in toExportStruct\n');
%% Build standard excel header (for McCall lab ERG excel format)
R1 = {toExportStruct.Testtime}; % 1xN cells containing char
R2 = {toExportStruct.Lastname};
R3 = repmat({' '}, 1, numel(toExportStruct));
R4 = {toExportStruct.Wavelabel};
R5 = {toExportStruct.StepNumber};
headerCells = vertcat(R1, R2, R3, R4, R5);
%% Now we need to pick which fields to export from .avgStats. In this case, .TTT, .aWave, and .bWave
allAvgStats = [toExportStruct.avgStats]; % Have to do this first since .avgStats is a struct with multiple fields
TTT = [allAvgStats.TTT];
aWaveMicrovolts = [allAvgStats.aWave];
bWaveMicrovolts = [allAvgStats.bWave];
finalDataTable = table(TTT, aWaveMicrovolts, bWaveMicrovolts);
%% Write this final data to an excel called 'multiFilterDemo.xlsx' with the standard header. One variable per sheet
xlsName = 'multiFilterDemo.xlsx';
varNamesExported = {'TTT', 'aWave'};
for sheetN = 1:numel(finalDataTable)
    sheetName = finalDataTable(:, sheetN).Properties.VariableNames{1};
    writecell(headerCells, xlsName, 'WriteMode', 'overwritesheet', 'Sheet', sheetName);
    %^ write header using overwritesheet to clear the sheet first (in case this sheet already has data)    
    writetable(finalDataTable(:, sheetN), xlsName, 'WriteMode', 'append', 'Sheet', sheetName);
    %^ write data for this sheet using 'append' to put this data after the standard header
end