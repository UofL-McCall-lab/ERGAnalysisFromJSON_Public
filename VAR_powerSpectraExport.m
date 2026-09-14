%{ 
% VAR_powerSpectraExport.m
% PURPOSE: Export data/figures from power spectra analysis of photopic
%   flicker.
%
% INPUTS: A .mat created by VAR_powerSpectraAnalysis.m
%
% OUTPUTS: Data in .xlsx plus figures stored as .fig files
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions). 
%   - Requires at least R2023a due to xregion function.
%  
% AUTHOR: David C Alston/Mattia Di Paolo 5-2025
%
% NOTES:
%       - .xlsx data stored where you request, but .fig files are stored
%       in the 'Figures' folder in the code folder.
%
%       - Assumes all rows in formattedMat are the same type: 
%           (.StepNumber 7, which is Photopic Flicker).
%}
clc
close all
clear
addpath(genpath('Functions'));
%% Load the .mat with power spectra data
[file, path] = uigetfile('*.mat', 'Select STEP4 mat with power spectra data');
if file == 0; return; end % User cancelled prompt
load(fullfile(path, file)); % loads struct called formattedMat
if ~isfield(formattedMat, 'powerSpectraStats')
    beep;
    fprintf(['ERROR::Chosen .mat does not have the .powerSpectraStats field ' ...
        'in its data structure. Check input data. Closing...\n']);
    return
end
%% CONTROLS. Also define plotting constants
animalType = 'Wt'; % 'Wt' or 'Tg'
powerSpectraYlim = [-5 35]; % As [min_dB max_dB]
yAxLabel = strcat('Amplitude (', char(181), 'V)');
xAxLabel = 'Time (ms)';
Tmsec = 1000*([1:formattedMat(1).Sampleswave]/formattedMat(1).Samplerate)'; %#ok<NBRAK>
[yLimitsPhotopicFlicker, ~] = selYLimits_F(animalType, 'Photopic Flicker');
fprintf('INFO::Using Y limits below for plotting average flash:\n');
disp(yLimitsPhotopicFlicker);
%% Check if all data rows in formattedMat are Photopic Flicker (.StepNumber == 7)
if ~all([formattedMat.StepNumber].' == 7)
    beep;
    fprintf("ERROR::At least one entry in the loaded .mat has a .StepNumber not equal to 7 (Photopic Flicker). Check input .mat\n");
    return
end
%% First, export all the R/L pairs as figures. Start by generating the average waveform (same method from STEP4_excludeAndAverage.mlx)
% After filtering, should be ordered without reference etc. So can do 1/2, 3/4, etc
if mod(numel(formattedMat), 2) ~= 0
    beep;
    fprintf("ERROR::Odd number of entries in your PS mat. Need even to find all R/L pairs, check input mat. Closing...\n");
    return
end
fprintf("INFO::Exporting power spectra figures to Figures folder...\n");
peakWindowHz = formattedMat(1).powerSpectraStats.peakWindow_Hz;
for leftRow = 2:2:numel(formattedMat)
    if ~strcmp(formattedMat(leftRow).Wavelabel, 'L')
        beep;
        fprintf("ERROR::End row is not left eye. Issue with sorting, contact David Alston\n");
        return
    end
    leftData = formattedMat(leftRow);
    rightData = formattedMat(leftRow - 1);
    if ~strcmp(leftData.Lastname, rightData.Lastname)
        beep;
        fprintf("ERROR::Left and right eye have different .Lastname values. Different animals? Contact David Alston\n");
        return
    end
    figure;
    tiledlayout(2, 2);

    % Right eye average flash
    nexttile;
    plot(Tmsec, rightData.avgStats.finalAverage);
    title('Right eye average flash');
    ylabel(yAxLabel);
    xlabel(xAxLabel);
    yline(0, '--k', 'LineWidth', 2); % Dashed black line at 0 volts
    ylim(yLimitsPhotopicFlicker);

    % Right eye power spectra
    cAxes = nexttile;
    hold(cAxes, 'on');
    findpeaks(rightData.powerSpectraStats.meanPowerdB, rightData.powerSpectraStats.powerFreqsHz);
    plot(cAxes, rightData.powerSpectraStats.powerFreqsHz, rightData.powerSpectraStats.meanPowerdB + rightData.powerSpectraStats.semPowerdB, '--r');
    plot(cAxes, rightData.powerSpectraStats.powerFreqsHz, rightData.powerSpectraStats.meanPowerdB- rightData.powerSpectraStats.semPowerdB, '--r');
    yline(cAxes, 0, '--k', 'LineWidth', 2); % Dashed black line at 0 dB
    hold(cAxes, 'off');
    title('Right eye average power spectra (+/- SEM)'); % 
    ylabel('Power (dB)');
    xlabel('Frequency (Hz)');
    ylim(powerSpectraYlim);
    xregion(rightData.powerSpectraStats.peakWindow_Hz);
    text(peakWindowHz(2), powerSpectraYlim(2)-3, ...
        strcat('Area under curve in highlighted region=', string(rightData.powerSpectraStats.peakWindow_areadB)));

    % Left eye average flash
    nexttile;
    plot(Tmsec, leftData.avgStats.finalAverage);
    title('Left eye average flash');
    ylabel(yAxLabel);
    xlabel(xAxLabel);
    yline(0, '--k', 'LineWidth', 2); % Dashed black line at 0 volts
    ylim(yLimitsPhotopicFlicker);

    % Left eye power spectra
    cAxes = nexttile;  
    hold(cAxes, 'on');
    findpeaks(leftData.powerSpectraStats.meanPowerdB, leftData.powerSpectraStats.powerFreqsHz);
    plot(cAxes, leftData.powerSpectraStats.powerFreqsHz, leftData.powerSpectraStats.meanPowerdB + leftData.powerSpectraStats.semPowerdB, '--r');
    plot(cAxes, leftData.powerSpectraStats.powerFreqsHz, leftData.powerSpectraStats.meanPowerdB- leftData.powerSpectraStats.semPowerdB, '--r');
    yline(cAxes, 0, '--k', 'LineWidth', 2); % Dashed black line at 0 dB
    hold(cAxes, 'off');
    title('Left eye average power spectra (+/- SEM)'); % 
    ylabel('Power (dB)');
    xlabel('Frequency (Hz)');
    ylim(powerSpectraYlim);
    xregion(leftData.powerSpectraStats.peakWindow_Hz);
    text(peakWindowHz(2), powerSpectraYlim(2)-3, ...
        strcat('Area under curve in highlighted region=', string(leftData.powerSpectraStats.peakWindow_areadB)));
    
    baseTitle = strcat(leftData.Lastname, '-PhotopicFlicker');
    sgtitle(baseTitle, 'Interpreter', 'none');
    outAvgFigName = ['Figures\PS-', baseTitle, '.fig'];
    set(gcf, 'Visible', 'on');
    cFig = gcf;
    cFig.WindowState = 'maximized';
    saveas(gcf, outAvgFigName); % Overwrites if figure with this name already exists
    close all
end
fprintf('INFO::Figure export complete.\n');
%% Second, convert filteredMat into a table so it can be sorted (date order, then all R if have R/L, then by Lastname so in animal ID order)
toExport_asTbl = struct2table(formattedMat);
toExport_asTbl = sortrows(toExport_asTbl, 'Testtime', 'ascend'); % Even though year is 1899, the time in HH:MM:SS looks to be incremental
toExport_asTbl = sortrows(toExport_asTbl, 'Wavelabel', 'descend'); % all 'R' rows, then all 'L' rows.
toExport_asTbl = sortrows(toExport_asTbl, 'Lastname', 'ascend'); % If name starts with number, this will be correct (3912, then 3913, etc)
toExportStruct = table2struct(toExport_asTbl); % Convert sorted table back into struct
%% Build standard excel header (for McCall lab ERG excel format)
R1 = {toExportStruct.Testtime}; % 1xN cells containing char
R2 = {toExportStruct.Lastname};
R3 = repmat({' '}, 1, numel(toExportStruct));
R4 = {toExportStruct.Wavelabel};
R5 = {toExportStruct.StepNumber};
headerCells = vertcat(R1, R2, R3, R4, R5);
%% Grab power spectra data to export
PS_Stats = [toExportStruct.powerSpectraStats];
peakPowerdB = [PS_Stats.peakWindow_maxdB];
peakPowerHz = [PS_Stats.peakWindow_maxFreqHz];
peakPowerAreadB = [PS_Stats.peakWindow_areadB];
meanPowerdB = [PS_Stats.meanPowerdB];
semPowerdB = [PS_Stats.semPowerdB];
powerFreqsHz = [PS_Stats.powerFreqsHz];
peakDataTable = table(peakPowerdB, peakPowerHz, peakPowerAreadB);
overallPSDataTable_mean = table(meanPowerdB, powerFreqsHz);
overallPSDataTable_SEM = table(semPowerdB, powerFreqsHz);
%% Build the output excel file name and pick saving location
[~, filenameNoExt, ~] = fileparts(file);
[outFile, outPath] = uiputfile([filenameNoExt, '_PSPeak.xlsx']);
if outFile == 0; disp('Saving cancelled'); return; end % User cancelled prompt
%% Export the power spectra peak data. One variable per sheet
fullOutPath = fullfile(outPath, outFile);
for sheetN = 1:numel(peakDataTable)
    sheetNamePeak = peakDataTable(:, sheetN).Properties.VariableNames{1};
    writecell(headerCells, fullOutPath, 'WriteMode', 'overwritesheet', 'Sheet', sheetNamePeak);
    %^ write header using overwritesheet to clear the sheet first (in case this sheet already has data)    
    writetable(peakDataTable(:, sheetN), fullOutPath, 'WriteMode', 'append', 'Sheet', sheetNamePeak);
    %^ write data for this sheet using 'append' to put this data after the standard header
end
%% Export the overall power spectra data
fullOutPath = fullfile(outPath, [filenameNoExt, '_PSOverall.xlsx']);
sheetNameOverall = overallPSDataTable_mean.Properties.VariableNames{1};
% Write meanPowerDb sheet
writecell(headerCells, fullOutPath, 'WriteMode', 'overwritesheet', 'Sheet', sheetNameOverall);
writetable(overallPSDataTable_mean, fullOutPath, 'WriteMode', 'append', 'Sheet', sheetNameOverall);
% Write semPowerDb sheet
writecell(headerCells, fullOutPath, 'WriteMode', 'overwritesheet', 'Sheet', 'semPowerdB');
writetable(overallPSDataTable_SEM, fullOutPath, 'WriteMode', 'append', 'Sheet', 'semPowerdB');
% Write N sheet (N flashes used in mean/sem)
writecell(headerCells, fullOutPath, 'WriteMode', 'overwritesheet', 'Sheet', 'nFlashUsed');
writecell({PS_Stats.meanPowerNFlash}, fullOutPath, 'WriteMode', 'append', 'Sheet', 'nFlashUsed');
fprintf("Done\n");