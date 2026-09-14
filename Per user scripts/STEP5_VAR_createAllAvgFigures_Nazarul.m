% Script to export all average figures from a STEP4 mat (Nazarul version)
clc
close all
clear
addpath(genpath('Functions'));
if ~isfolder('Figures'); mkdir('Figures'); end % Since github won't commit empty folders
addpath('Figures');
%% Open STEP4 mat and load data
[file, path] = uigetfile('*.mat');
if file == 0; return; end
matFullPath = fullfile(path, file);
load(matFullPath); % As formattedMat struct in workspace
%% Check that .avgStats exists (needed to generate plots)
if ~isfield(formattedMat, 'avgStats')
    beep;
    disp('ERROR:: .avgStats does not exist in this .mat file. Did you select the correct STEP4 mat? Closing...');
    return
end
%% Initialize typeNames (Nazarul data) and x/y axes labels
typeNames = {'Scotopic -40 dB', ... % StepNumber 1
            'Scotopic -34 dB', ...  % StepNumber 2
            'Scotopic -28 dB', ...  % StepNumber 3
            'Scotopic -22 dB', ...  % StepNumber 4
            'Scotopic -16 dB', ...  % StepNumber 5
            'Scotopic -10 dB', ...  % StepNumber 6 
            'Scotopic -4 dB', ...   % StepNumber 7
            'Scotopic 2 dB', ...    % StepNumber 8
            'Scotopic 8 dB', ...    % StepNumber 9
            'Scotopic 10 dB', ...   % StepNumber 10
            'Photopic -12 dB', ...  % StepNumber 11
            'Photopic -8 dB', ...   % StepNumber 12
            'Photopic -4 dB', ...   % StepNumber 13
            'Photopic 0 dB', ...    % StepNumber 14
            'Photopic 4 dB', ...    % StepNumber 15
            'Photopic 8 dB', ...    % StepNumber 16
            'Photopic 10 dB', ...   % StepNumber 17                                  
            };
yAxLabel = strcat('Amplitude (', char(181), 'V)');
xAxLabel = 'Time (ms)';
%% Find stepNumberOffset (if min .StepNumber is > 1, then use an offset)
stepNumberOffset = min([formattedMat.StepNumber]) - 1;
if stepNumberOffset > 0
    fprintf('WARNING:: Minimum .StepNumber is > 1 (was %i). Will use %i as offset to pick from typeNames\n', stepNumberOffset + 1, stepNumberOffset);
else
    fprintf('INFO:: No offset in .StepNumber needed (minimum .StepNumber was 1)\n');
end
%% Loop over all plottable .avg stats and save to the 'Figures' folder
for rowN = 1:numel(formattedMat)
    %% Skip toUse = false entries  
    if ~formattedMat(rowN).toUse; continue; end  
    %% Grab avg stats from struct
    avg = formattedMat(rowN).avgStats.finalAverage;
    TTT = formattedMat(rowN).avgStats.TTT;
    TTP = formattedMat(rowN).avgStats.TTP;
    minVal = formattedMat(rowN).avgStats.minVal;
    maxVal = formattedMat(rowN).avgStats.maxVal;
    aWave = formattedMat(rowN).avgStats.aWave;
    bWave = formattedMat(rowN).avgStats.bWave;
    %% Create other info for plots
    sampPerWave = formattedMat(rowN).Sampleswave; % Integer, usually 512
    nFlash = formattedMat(rowN).Numberaveraged; % DCA DEV - Taken from different place for Nazarul data (.Numberaveraged)
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
    stepN = formattedMat(rowN).StepNumber - stepNumberOffset; % Integer from 1 to 7 corresponding with type name
    cAnimal = formattedMat(rowN).Lastname;
    sampHz = formattedMat(rowN).Samplerate; % In Hz
    Tmsec = 1000*([1:sampPerWave]/sampHz)'; %#ok<NBRAK>
    cRowName = [cAnimal, '-', cEye, '-', typeNames{stepN}, ' (', num2str(nFlash), ' flashes)'];
    cRowName(cRowName == '/') = '_';
    cRowName(cRowName == '\') = '_';
    %% Built avg plot
    TTTplotX = TTT-10:TTT+10;
    TTTplotY = TTTplotX;
    TTTplotY(1:end) = minVal(2);
    TTPplotX = TTP-10:TTP+10;
    TTPplotY = TTPplotX;
    TTPplotY(1:end) = maxVal(2);
    figure;
    avgTiledObj = tiledlayout(1, 1);
    cAxes = nexttile(avgTiledObj); % getERGpeakamps.m uses default Y axes, so leave as default
    hold(cAxes, 'on');
    plot(cAxes, Tmsec, avg, '-r', 'LineWidth', 3);          % avg (no SEM for nazarul data since only have avg flash, not indiv)
    plot(cAxes, TTTplotX, TTTplotY, '--r', 'LineWidth', 3); % trough horiz line
    plot(cAxes, TTPplotX, TTPplotY, '--r', 'LineWidth', 3); % peak horiz line
    yline(cAxes, 0, '--k', 'LineWidth', 2);                 % Dashed black line at 0 volts
    %% Add text to plot
    %% Build text for a/bWave
    TTPTxt = ['TTP = ' num2str(TTP) ' ms'];
    TTTTxt = ['TTT = ' num2str(TTT) ' ms'];
    aWaveTxt = ['a-wave = ' num2str(aWave, '%.1f') ' ' char(181) 'V']; % Confirmed %.1f rounds
    bWaveTxt = ['b-wave = ' num2str(bWave, '%.1f') ' ' char(181) 'V']; 
    %% aWave/TTT text
    text(cAxes, 0.15, 0.21, aWaveTxt, 'Units', 'normalized', 'FontSize', 16, 'Color', 'r');
    text(cAxes, 0.15, 0.18, TTTTxt, 'Units', 'normalized', 'FontSize', 16, 'Color', 'r');
    %% bWave/TTP text
    text(cAxes, 0.4, 0.95, bWaveTxt, 'Units', 'normalized', 'FontSize', 16, 'Color', 'r');
    text(cAxes, 0.4, 0.92, TTPTxt, 'Units', 'normalized', 'FontSize', 16, 'Color', 'r');
    hold(cAxes, 'off');
    xlabel(xAxLabel);
    ylabel(yAxLabel);  
    title(['AVG-', cRowName], 'Interpreter', 'none');
    xlim([0, max(Tmsec)]);
    outAvgFigName = ['Figures\AVG-', cRowName, '.fig'];
    if isfile(outAvgFigName)
        fprintf('^^^^^^WARNING:: Overwriting average figure for %s\n', outAvgFigName);
    else
        fprintf('^^^^^^Saved average waveform figure to file = %s\n', outAvgFigName);
    end
    set(gcf, 'Visible', 'on');
    cFig = gcf;
    cFig.WindowState = 'maximized';
    saveas(gcf, outAvgFigName);
    close all
end
disp('Done');