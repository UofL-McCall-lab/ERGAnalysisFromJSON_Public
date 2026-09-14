%{ 
% VAR_powerSpectraAnalysis.m
% PURPOSE: Calculate some stats on the power spectra of just photopic flicker 
%   (assumes this is .StepNumber = 7).
%
% INPUTS: A STEP4 mat.
%
% OUTPUTS: A STEP4 mat with power spectra stats calculated for all valid 
%   photopic flicker entries. All other data removed from mat.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2023b but may work
%   on earlier versions). Also, the signal processing toolbox (for the
%   pspectrum() and pow2db() functions).
%  
% AUTHOR: David C Alston/Mattia Di Paolo 5-2025
%
% NOTES:
%   - Does not do any data or figure export. See VAR_powerSpectraExport.m
%
%   - Calculates the power spectra for each raw flash, then finds the 
%       mean and SEM power spectra.
%       -- Takes into account flash exclusion from STEP4 (i.e if excluding
%           flashes 2, 4, and 5 in flicker the N for SEM will be 27 not 30).
%
%   - The created .mat will only have data for Photopic Flicker. All other
%       data is cleared.
%}
clc
close all
clear
addpath(genpath('Functions'));
%% CONTROLS
powerSpectraArea_peakWindowHz = [28 33]; % Frequency range to find the area under as [startHz endHz]. Also, where to search for the maximum power peak
%% Load .mat with waveform data (STEP4 required)
[file, path] = uigetfile('*.mat');
if file == 0; return; end % User cancelled prompt
load(fullfile(path, file)); % N x 1 struct called formattedMat
typeNames = {'Scotopic 0.01dB-15-1', 'Scotopic 0.01dB-15-2', 'Scotopic 0dB', 'Scotopic 10dB', 'Photopic 0dB', 'Photopic 10dB', 'Photopic Flicker'};
%% Remove rows that are not photopic flicker (.StepNumber 7)
formattedMat([formattedMat.StepNumber].' ~= 7) = [];
%% Remove rows that do not have .avgFlash data (autoclearmid, userremoved, etc)
emptyAvgFlash = cellfun(@isempty, {formattedMat.avgStats}.');
formattedMat(emptyAvgFlash) = [];
%% If after filtering there is no data left, stop
if isempty(formattedMat)
    beep;
    fprintf("ERROR::After filtering, there is no data left to perform power analysis on. Check your input mat and filters. Closing...\n");
    return
end
%% For all remaining data, perform power spectra (PS) analysis (with flash exclusion)
for rowN = 1:numel(formattedMat)
    %close all
    toUseFlashes = formattedMat(rowN).indivFlash;
    toUseFlashes(:, formattedMat(rowN).excludedFlashes) = []; % Remove any excluded flashes
    [meanPowerdB, ~, semPowerdB, nFlash, powerFreqsHz] = meanPowerSpectraFromIndivFlashes_F( ...
        toUseFlashes, ... 
        [0 90], ...
        formattedMat(rowN).Samplerate);
    PSAreaWindowIdx = find(powerFreqsHz>=powerSpectraArea_peakWindowHz(1) & powerFreqsHz<powerSpectraArea_peakWindowHz(2));
    [PSamp, aampi] = max(meanPowerdB(PSAreaWindowIdx));
    PSWindowAreadB = trapz(powerFreqsHz(PSAreaWindowIdx), meanPowerdB(PSAreaWindowIdx)); % Giving X vals returns area in terms of dB
    PSpeakHz = powerFreqsHz(PSAreaWindowIdx(aampi));
    % Stats calculated within chosen frequency window:
    formattedMat(rowN).powerSpectraStats.peakWindow_Hz = powerSpectraArea_peakWindowHz;
    formattedMat(rowN).powerSpectraStats.peakWindow_Idx  = PSAreaWindowIdx;
    formattedMat(rowN).powerSpectraStats.peakWindow_maxdB = PSamp;
    formattedMat(rowN).powerSpectraStats.peakWindow_maxFreqHz = PSpeakHz;
    formattedMat(rowN).powerSpectraStats.peakWindow_areadB = PSWindowAreadB;
    % Overall mean + sem power spectra:
    formattedMat(rowN).powerSpectraStats.meanPowerdB = meanPowerdB;
    formattedMat(rowN).powerSpectraStats.meanPowerNFlash = nFlash;
    formattedMat(rowN).powerSpectraStats.semPowerdB = semPowerdB;
    formattedMat(rowN).powerSpectraStats.powerFreqsHz = powerFreqsHz; 
end
%% Now save the new formatted mat
splitFile = split(file, '_');
outFile = replace(file, ['_' splitFile{end}], '_PhotopicFlicker_PS.mat');
[outFile, outPath] = uiputfile(outFile);
if outFile == 0 % User cancelled prompt
    disp('WARNING:: File selection cancelled. No _PhotopicFlicker_PS .mat was created.');
    return;
end
save(fullfile(outPath, outFile), "formattedMat");
fprintf('Power spectra formattedMat saved to %s\n', fullfile(outPath, outFile));