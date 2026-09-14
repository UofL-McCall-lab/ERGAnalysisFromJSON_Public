%{
% exportAvgStatsFromMat
% PURPOSE: Export final ERG data from the .mat to an excel file. Step 5 in
%   manual.
%
% INPUTS: A .mat that has been run through all steps of the workflow (STEP4 mat). 
%    - formattedMat must have at least one entry in the 'avgStats' field.
%    - Load your mat in the workspace to examine this.
%
% OUTPUTS: An excel file that mimics the structure of 
%   what the old method creates.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions). 
%   - Requires at least R2019b due to writecell function.
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 3-2025
%
% NOTES:
%   - Rounds aWave, bWave, TTP, and TTT to the nearest tenth place
%       (10.1943425 -> 10.2). 3-24-2025 change
%}
clc
close all
clear
%% Load file
[file, path] = uigetfile('*.mat', 'Select .mat with ERG data that has average calculated (step 4)');
if file == 0; return; end % User cancelled prompt
if ~contains(file, 'step4', 'IgnoreCase', true)
    beep;
    fprintf('%s does not contain step4 in filename. Did you select the correct mat? Closing...\n', file);
    return
end
load(fullfile(path, file)); % loads struct called formattedMat
%% Select only rows with toUse = true
toUseTrue = [formattedMat.toUse].'; % Skip any that have toUse = false
%% From that, select only rows with average data that can be exported
hasAvgTrue = false([numel(formattedMat), 1]);
for N = 1:numel(toUseTrue)
    if ~isempty(formattedMat(N).avgStats)
        hasAvgTrue(N) = true;
    else
        hasAvgTrue(N) = false;
    end
end
toExport = formattedMat(and(toUseTrue, hasAvgTrue)); % only those with average data that exists to be exported AND toUse = true
fprintf('Exporting %i of %i rows that have average data\n', numel(toExport), numel(formattedMat));
startShift = 5; % This +1 rows is where to start waveform data in raw and average sheets
clearvars -except toExport startShift file
%% Change output formatting to match old excel (8-2024 change)
% By date, then by animal within each date, then all R (flash type 1->7), then all L?
if isscalar(toExport) % Single entry (single row).
    fprintf("WARNING::Chosen .mat has only a single valid entry to export. Exporting with AsArray = true\n");
    toExport_asTbl = struct2table(toExport, 'AsArray', true);
else % Multiple rows
    toExport_asTbl = struct2table(toExport); % So can use sortrows()
end
toExport_asTbl = sortrows(toExport_asTbl, 'Testtime', 'ascend'); % Even though year is 1899, the time in HH:MM:SS looks to be incremental
toExport_asTbl = sortrows(toExport_asTbl, 'Wavelabel', 'descend'); % all 'R' rows, then all 'L' rows.
toExport_asTbl = sortrows(toExport_asTbl, 'Lastname', 'ascend'); % If name starts with number, this will be correct (3912, then 3913, etc)
toExport = table2struct(toExport_asTbl);
%% Define standard header that is in all sheets
R1 = {toExport.Testtime}; % 1xN cells containing char
R2 = {toExport.Lastname};
R3 = repmat({' '}, 1, numel(toExport));
R4 = {toExport.Wavelabel};
R5 = {toExport.StepNumber};
headerCells = vertcat(R1, R2, R3, R4, R5);
%% Sheet 1 - Raw waveform data (not rounded)
% Format excel sheets as:
%{
    Sheet 1 = Raw data. Each column is:
            Date
            Name
            Empty
            R or L
            1 through 7
            All flashes appended end to end

   Sheet 2 = Average data. Each column is:
        Same as sheet 1, but just the average flash (512 x 1 for all)
        instead of all flashes

   Sheet 3 = TTP data
        Each column has the TTP ms number for a given row

   Sheet 4 = TTT data
        As sheet 3, but TTT

   Sheet 5 = a-Wave uV data
        As sheet 4, but a-wave uV values

   Sheet 6 = b-Wave uV data
        As sheet 5, but b-Wave uV values
%}
sheet1Cells = headerCells;
R6 = {toExport.Data};
for N = 1:numel(toExport)
    currRawWaveData = R6{N};
    for cPoint = 1:numel(currRawWaveData)
        sheet1Cells{cPoint+startShift, N} = currRawWaveData(cPoint, 1);
    end
end
%% Sheet 2 - Average waveform data (not rounded)
sheet2Cells = headerCells;
for N = 1:numel(toExport) % For each row you are exporting
    currAvgWaveData = toExport(N).avgStats.finalAverage;
    for cPoint = 1:numel(currAvgWaveData)
        sheet2Cells{cPoint+startShift, N} = currAvgWaveData(cPoint, 1);
    end
end
%% Sheet 3 - TTP ms values (rounded to tenths)
sheet3Cells = headerCells;
avgData = struct('avgStats', {toExport(:).avgStats});
insRow = size(sheet3Cells, 1) + 1;
for N = 1:numel(avgData) 
    sheet3Cells(insRow, N) = {round(avgData(N).avgStats.TTP, 1)}; 
end
%% Sheet 4 - TTT ms values (rounded to tenths)
sheet4Cells = headerCells;
avgData = struct('avgStats', {toExport(:).avgStats});
insRow = size(sheet4Cells, 1) + 1;
for N = 1:numel(avgData)
    sheet4Cells(insRow, N) = {round(avgData(N).avgStats.TTT, 1)}; 
end
%% Sheet 5 - a-Wave uV values (rounded to tenths)
sheet5Cells = headerCells;
avgData = struct('avgStats', {toExport(:).avgStats});
insRow = size(sheet5Cells, 1) + 1;
for N = 1:numel(avgData) 
    sheet5Cells(insRow, N) = {round(avgData(N).avgStats.aWave, 1)}; 
end 
%% Sheet 6 - b-Wave uV values (rounded to tenths)
sheet6Cells = headerCells;
avgData = struct('avgStats', {toExport(:).avgStats});
insRow = size(sheet6Cells, 1) + 1;
for N = 1:numel(avgData) 
    sheet6Cells(insRow, N) = {round(avgData(N).avgStats.bWave, 1)}; 
end
%% Ask user where to save excel file
splitFile = split(file, '.');
[outFile, outPath] = uiputfile([splitFile{1}, '_avgData.xlsx']);
if outFile == 0; disp('Saving cancelled'); return; end % User cancelled prompt
fullOutPath = fullfile(outPath, outFile);
%% Write all excel sheets
fprintf('Writing excel file please wait...\n');
writecell(sheet1Cells, fullOutPath, 'Sheet', 'Raw waveforms', 'WriteMode', 'overwritesheet');     % Sheet 1
writecell(sheet2Cells, fullOutPath, 'Sheet', 'AvgData', 'WriteMode', 'overwritesheet');           % Sheet 2
writecell(sheet3Cells, fullOutPath, 'Sheet', 'Time To Peak ms', 'WriteMode', 'overwritesheet');   % Sheet 3
writecell(sheet4Cells, fullOutPath, 'Sheet', 'Time To Trough ms', 'WriteMode', 'overwritesheet'); % Sheet 4
writecell(sheet5Cells, fullOutPath, 'Sheet', 'a-Wave uV', 'WriteMode', 'overwritesheet');         % Sheet 5
writecell(sheet6Cells, fullOutPath, 'Sheet', 'b-Wave uV', 'WriteMode', 'overwritesheet');         % Sheet 6
fprintf('.xlsx file saved to %s\n', fullfile(outPath, outFile));