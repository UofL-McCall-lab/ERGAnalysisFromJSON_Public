%{
% PURPOSE: Take .fig files created by VAR_powerSpectraVsAvg_BATCH and
%   extract the peak locations (power and frequency)
%
% INPUTS: A folder of .fig files
%
% OUTPUTS: One excel file put into the top level folder selected.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions). Also:
%       - The getAllFiles_F.m function
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 4-2025
%
% NOTES:
%}
clc
close all
clear
addpath(genpath('Functions'));
%% Get folder containing .fig files (and in any subfolders)
figPath = uigetdir('');
if figPath == 0; return; end
allFigFiles = getAllFiles_F(figPath, {'.fig'}); % Recursive search
if numel(allFigFiles) == 0
    beep;
    fprintf("ERROR:: No .fig files found in folder or any of its subfolders. Check the folder selected. Closing...\n");
    return
end
fprintf("INFO:: Found %i .fig files to extract data from\n", numel(allFigFiles));
%% Loop over each fig and extract peak locations to a struct
for figN = 1:numel(allFigFiles)
    close all
    if ~contains(allFigFiles(figN).name, 'PS-')
        % Skip any figures without 'PS-' in the filename
        fprintf("INFO:: Skipping %s (no -PS in filename)\n", allFigFiles(figN).name);
        continue
    end
    figHandle = openfig(fullfile(allFigFiles(figN).folder, allFigFiles(figN).name)); % 1x1 Figure
    bothAxes = figHandle.Children.Children; % 2 x 1 Axes (Number 1 is power spectra)
    powerSpectraAxes = bothAxes(1);
    powerSpectraLines = powerSpectraAxes.Children;
    %{
        5 x 1 Data:
            ConstantLine (0 dB y line)
            Line
            Line
            Line (peak) <- data tips
            Line (Signal)            
    %}
    pkLine = powerSpectraLines(4); % See block comment above
    figStruct(figN).figName = allFigFiles(figN).name; %#ok<*SAGROW>
    figStruct(figN).freqHzVsPowerdB= [pkLine.XData' pkLine.YData']; % nPeaks x 2 double ([frequency_Hz, power_dB])
end
close all
%% Check we can write each figures data to its' own sheet
if figN >= 255
    beep;
    fprintf("ERROR:: More than 255 figures worth of power spectra. Cannot write using sheet method. Alter code as needed\n");
    return
end
%% Write each figures data to its own sheet (limit of 255 sheets)
% Note there are other ways to export depending on what shape you want your
% excel to be.
[~, outExcelName, ~] = fileparts(figPath);
outExcelName = [outExcelName, '_powerSpectraPeaks.xlsx'];
fullOutExcel = fullfile(figPath, outExcelName);
if isfile(fullOutExcel)
    fprintf("WARNING:: Excel already exists, will overwrite\n");
end
for sheetN = 1:numel(figStruct)
    figureName = figStruct(sheetN).figName;  % Sheet name to use
    figureName = figureName(1:31); % Sheet names limited to 31 char
    peakFreq_Hz = figStruct(sheetN).freqHzVsPowerdB(:, 1); % Frequency (Hz)
    peakPower_dB = figStruct(sheetN).freqHzVsPowerdB(:, 2); % Power (dB)
    writetable(table(peakFreq_Hz), fullOutExcel, 'Sheet', figureName, 'Range', 'A1');
    writetable(table(peakPower_dB), fullOutExcel, 'Sheet', figureName, 'Range', 'B1');
end