%{
% VAR_powerSpectraVsAvg_BATCH.m
%
% PURPOSE: Generate and save two plot figures:
%       - The average + SEM flash waveform (identical method to
%           STEP4_excludeAndAverage.mlx). No flash exclusion.
%       - The average + SEM power spectra.
%           -- Calculated per raw flash, then averaged
%
% INPUTS: A STEP2 (or later) .mat file
%
% OUTPUTS: One .fig file per valid row in formattedMat. Placed into
%       "Figures" folder within main code folder.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions). Also: 
%       - meanPowerSpectraFromIndivFlashes_F.m
%       - selYLimits_F.m
%       - The signal processing toolbox
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 7-2025
%
% NOTES:
%   - The power spectra is calculated from the raw flashes (no baseline
%       correction, smoothing, etc).
%
%   - This will overwrite any figure with the same name that already 
%       exists.
%}
clc
close all
clear
addpath(genpath('Functions'));
%% CONTROLS
stepNumToUse = 7; % Only export flashes of this type (see typeNames below)
smoothMethod = "sgolay"; % See method input to smoothdata() Matlab function. 'sgolay' is default for us (best results from testing)
smoothWindow = 10; % In indices (10 means use a window with width = 10 entries)
sgolayDegree = 2; % 1 can work better for scotopic 0.01 db-15-1 (2 is default)
powerFreqLimitsHz = [0 90]; % Limit the frequencies where the power spectra is calculated (in Hz). [0 90] is default
%% Define constants
typeNames = {'Scotopic 0.01dB-15-1', 'Scotopic 0.01dB-15-2', 'Scotopic 0dB', 'Scotopic 10dB', 'Photopic 0dB', 'Photopic 10dB', 'Photopic Flicker'};
plotColors = {[0 0 0] [1 0 0] [0 1 0] [0 0 1] [0 0.5 0.5]}; % Same as original ERG gui
repColors = repmat(plotColors, 1, 6); % 6 repeats max (5 colors *6 = 30 flashes, which is the max)
subplotNames = {'1->5', '6->10', '11->15', '16->20', '21->25', '26->30'};
flashNames = {'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12', 'f13', 'f14', 'f15' ...
    'f16', 'f17', 'f18', 'f19', 'f20', 'f21', 'f22', 'f23', 'f24', 'f25', 'f26', 'f27', 'f28', 'f29', 'f30'};
maxFlashes = 30;   % Maximum flashes for a single type. Default 30.
yAxLabel = strcat('Amplitude (', char(181), 'V)');
xAxLabel = 'Time (ms)';
% Define search windows for min/max (used in TTT and TTP calculations)
% As [minStart minEnd maxStart maxEnd] in milliseconds
% Note, the order here should match the order of typeNames above (so
% if typeNames{1} was 'Scotopic 0.01dB-15-1', searchWindows_ms(1, :) should
% be the search windows for 'Scotopic 0.01dB-15-1'.
searchWindows_ms(1, :) = [10 40 40 150]; % 'Scotopic 0.01dB-15-1'
searchWindows_ms(2, :) = [10 40 40 150]; % 'Scotopic 0.01dB-15-2'
searchWindows_ms(3, :) = [1 40 30 150];  % 'Scotopic 0dB'
searchWindows_ms(4, :) = [1 40 30 150];  % 'Scotopic 10dB'
searchWindows_ms(5, :) = [5 30 15 120];  % 'Photopic 0dB'
searchWindows_ms(6, :) = [5 30 15 120];  % 'Photopic 10dB'
searchWindows_ms(7, :) = [5 30 15 120];  % 'Photopic Flicker'
%% Check selected .StepNumber is valid
if (stepNumToUse > numel(typeNames)) || (stepNumToUse < 0)
    beep;
    fprintf('ERROR:: Invalid selected stepNumToUse. See typeNames (1 = use the 1st entry in typeNames). Closing...\n');
    return
else
    fprintf('INFO:: Filtering to only %s (.StepNumber = %i)\n', typeNames{stepNumToUse}, stepNumToUse);
end
%% Load the .mat file
[file, path] = uigetfile('*.mat', 'Select STEP2 or later .mat with ERG data');
if file == 0; return; end % User cancelled prompt
load(fullfile(path, file)); % loads struct called formattedMat
%% Filter formattedMat down to just the selected .StepNumber
validSN = unique([formattedMat.StepNumber].');
if ~ismember(stepNumToUse, validSN)
    beep;
    fprintf("ERROR:: Selected .StepNumber not found in .mat. Valid values for this mat:\n");
    disp(validSN);
    return
end
formattedMat([formattedMat.StepNumber].' ~= stepNumToUse) = [];
%% LOOP START - Check this rowN is valid to use (R, L, or reference)
for rowN = 1:numel(formattedMat)
    emptyRem = isempty(formattedMat(rowN).remReason); 
    autoMid = strcmp(formattedMat(rowN).remReason, 'AUTOCLEARMID');
    if ~(emptyRem || autoMid)
        fprintf('WARNING:: Selected row (%i) is not valid for power spectrum analysis. Skipping\n', rowN);
        continue
    else
        fprintf('INFO:: Plotting from rowN = %i\n', rowN);
    end
    %% Calculate the average + SEM waveform (copy pasted code from STEP4_VAR_generateAllAvg.mlx)
    cWav = formattedMat(rowN).Data; % Raw waveform data without exclusion or averaging
    sampPerWave = formattedMat(rowN).Sampleswave; % Integer, usually 512
    nFlash = size(cWav, 1) / sampPerWave; % Integer, ex 5
    stepN = formattedMat(rowN).StepNumber; % Integer from 1 to 7 corresponding with type name
    cAnimal = formattedMat(rowN).Lastname;
    sampHz = formattedMat(rowN).Samplerate; % In Hz
    cEye = formattedMat(rowN).Wavelabel; % 'R', 'L', or []
    if isempty(cEye)
        cEye = 'REF';
    else
        switch cEye
            case 'R'
                cEye = 'OD';
            case 'L'
                cEye = 'OS';
            otherwise
                beep;
                fprintf("ERROR::Unhandled eye (.Wavelabel). Should be R, L, or empty. Closing...\n");
                return
        end
    end
    cRowName = [cAnimal, '-', cEye, '-', typeNames{stepN}, ' (', num2str(nFlash), ' flashes)'];
    cRowName(cRowName == '/') = '_';
    cRowName(cRowName == '\') = '_';
    if contains(cAnimal, 'tg', 'IgnoreCase', true)
        cType = 'Tg';
    else
        cType = 'Wt';
    end
    [yLimits, baselineW] = selYLimits_F(cType, typeNames{stepN});
    Tmsec = 1000*([1:sampPerWave]/sampHz)'; %#ok<NBRAK>
    cFlashRaw = zeros(sampPerWave, nFlash);
    cFlashSmooth = cFlashRaw; % For storing final smoothed flash data
    cFlashFinal = cFlashRaw; % For storing final smoothed + baseline corrected flash data
    for P = 1:nFlash % Get each flash, then smooth + baseline correct them (before exclusion)
        endIdx = P*sampPerWave;
        startIdx = endIdx - sampPerWave + 1;
        cFlashRaw(:, P) = cWav(startIdx:endIdx);
        cFlashSmooth(:, P) = smoothdata(cFlashRaw(:, P), ...
            smoothMethod, ...
            smoothWindow, ...
            'Degree', sgolayDegree); % Smooth flash using chosen method
        baseline(:, P) = mean(cFlashSmooth(1:baselineW, P));  %#ok<SAGROW> % Calculate baseline from smoothed flash data
        cFlashFinal(:, P) = cFlashSmooth(:, P) - baseline(:, P);
    end
    avg = mean(cFlashFinal, 2, 'omitnan'); %'omitnan' handles flash exlcusion (excluded flashes set to NaN)
    avg = avg - avg(1); % Center at 0
    denSem = sqrt((length(cFlashFinal)/sampPerWave)); % Denominator for sem
    sem =  std(cFlashFinal, 0, 2, 'omitnan') / denSem;
    %% Calculate the power spectra from the raw individual flashes
    [meanPowerdB, ~, semPowerdB, ~, powerFreqsHz] = meanPowerSpectraFromIndivFlashes_F( ...
        formattedMat(rowN).indivFlash, ...
        powerFreqLimitsHz, ...
        formattedMat(rowN).Samplerate);
    %% Generate the plot
    figure;
    avgTiledObj = tiledlayout(1, 2);
    cAxes = nexttile(avgTiledObj);
    ylim(cAxes, yLimits);
    hold(cAxes, 'on');
    plot(cAxes, Tmsec, avg, '-r', 'LineWidth', 3);          % avg
    plot(cAxes, Tmsec, avg+sem, '--r');                     % sem top line
    plot(cAxes, Tmsec, avg-sem, '--r');                     % sem bottom line
    yline(cAxes, 0, '--k', 'LineWidth', 2);                 % Dashed black line at 0 volts
    xlabel(cAxes, xAxLabel);
    ylabel(cAxes, yAxLabel);
    title(cAxes, 'Baseline corrected + smoothed + averaged flash');
    hold(cAxes, 'off');
    
    cAxes = nexttile;
    hold(cAxes, 'on');
    findpeaks(meanPowerdB, powerFreqsHz);
    plot(cAxes, powerFreqsHz, meanPowerdB + semPowerdB, '--r');
    plot(cAxes, powerFreqsHz, meanPowerdB - semPowerdB, '--r');
    title(cAxes, 'Power spectra mean + sem (calc per raw flash)');
    yline(cAxes, 0, '--k', 'LineWidth', 2);                 % Dashed black line at 0 dB
    xlabel(cAxes, 'Frequency (Hz)');
    ylabel(cAxes, 'Power (dB)');
    hold(cAxes, 'on');
    sgtitle([cRowName, '-noExclusion'], 'Interpreter', 'none');
    %% Save to .fig files (Figures folder)
    outAvgFigName = ['Figures\PS-', cRowName, '.fig'];
    if isfile(outAvgFigName)
        fprintf('^^^^^^WARNING:: Overwriting figure for %s\n', outAvgFigName);
    else
        fprintf('^^^^^^Saved average waveform figure to file = %s\n', outAvgFigName);
    end
    set(gcf, 'Visible', 'on');
    cFig = gcf;
    cFig.WindowState = 'maximized';
    saveas(gcf, outAvgFigName);
    close all
end