%{
% STEP3_selectRepeats.m
% PURPOSE: Find and select repeats in ERG waveform data. Reworked version
%   of older live script (new as of 08-2024)
%
% INPUTS: A single STEP2 .mat file (looks for "_step2Mat" in filename)
%
% OUTPUTS: A single STEP3 .mat file ready for further processing
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions).
%  
% AUTHOR: David C Alston (david.alston@louisville.edu) 2-2026
%
% NOTES:
%}
clc
close all
clear
%% Define per repeat colors to use. Code will throw error if not enough colors to choose from (more than 7 repeats by default)
perRepeatColors = {'r','b', 'm', 'k', 'g', 'y', 'c'}; % {red, blue, magenta, black, green, yellow, cyan}
%% Select and load file
typeNames = {'Scotopic 0.01dB-15-1', 'Scotopic 0.01dB-15-2', 'Scotopic 0dB', 'Scotopic 10dB', 'Photopic 0dB', 'Photopic 10dB', 'Photopic Flicker'};
[file, path] = uigetfile('*.mat', 'Select STEP2 .mat with ERG data');
if file == 0; return; end % User cancelled prompt
if ~contains(file, '_step2Mat')
    beep;
    fprintf('%s does not contain _step2Mat in filename. Did you select the correct mat? Closing...\n', file);
    return
end
load(fullfile(path, file)); % loads struct called formattedMat
% Find any protocols with "calibrate" in protocol name. Set .toUse to false
% with .remReason (Aug 8th 2024)
calibrateIdx = find(contains({formattedMat.Longprotocol}.', 'calibrat', 'IgnoreCase', true));
if ~isempty(calibrateIdx); fprintf('WARNING:: Found %i rows containing calibrat. Setting .toUse to false to skip these\n', numel(calibrateIdx)); end
for cN = 1:numel(calibrateIdx)
    formattedMat(calibrateIdx(cN)).toUse = false; %#ok<SAGROW>
    formattedMat(calibrateIdx(cN)).remReason = 'CONTAINSCALIBRATINSTEP3'; %#ok<SAGROW>
end
yAxLabel = strcat('Amplitude (', char(181), 'V)'); % char(181) is μ
%% Find stepNumberOffset (if min .StepNumber is > 1, then use an offset)
stepNumberOffset = min([formattedMat.StepNumber]) - 1;
if stepNumberOffset > 0
    fprintf('WARNING:: Minimum .StepNumber is > 1 (was %i). Will use %i as offset to pick from typeNames\n', stepNumberOffset + 1, stepNumberOffset);
else
    fprintf('INFO:: No offset in .StepNumber needed (minimum .StepNumber was 1)\n');
end
%% Find groups
startGroups = find([formattedMat.groupStartSearch].'); % Start of groups
startGroupsDiff = diff(startGroups);
startGroupsDiff(startGroupsDiff == 1) = []; % 8-8-2024 bugfix. In case extra "CALIBRATE" data rows etc
rowsPerRepeat = min(startGroupsDiff);
startGroups(:, 2) = [diff(startGroups(:, 1)); rowsPerRepeat];
startGroups(end, 2) = numel(formattedMat) - startGroups(end, 1) + 1; % 9-24-24 bugfix. When group goes to last row, need to recalculate the final diff
numUserSelRepeats = 0; % To count number of times user had to select
%% Do duplicate removal based on groups (single .mat)
for N = 1:size(startGroups, 1)
    if startGroups(N, 2) == rowsPerRepeat; continue; end % No repeats, skip to next (looking for diff ~= rowsPerRepeat. Means there are repeats)
    %% Grab all groups plus repeats for this set
    startIdx = startGroups(N, 1);
    endIdx = startIdx + startGroups(N, 2) - 1;    
    subsetMat = formattedMat(startIdx:endIdx); % Contains all repeats plus original group
    toUseSubset = [subsetMat.toUse].';
    toUseRows = startIdx:endIdx;  % Skip over any that have toUse = false
    toUseRows(~toUseSubset) = []; % Row numbers from formattedMat that have toUse = true
    %% Check if repeats identical. If so, auto select first group and remove later ones. Then continue to next row.
    oC = 0;
    eC = 0;
    for checkN = 1:numel(toUseRows) % This is a dumb way of doing this but it works
        if mod(checkN, 2) ~= 0 % if odd 
            oC = oC+1;
            oddIdx(oC) = toUseRows(checkN); %#ok<SAGROW> 
        else % If even
            eC = eC+1;
            evenIdx(eC) = toUseRows(checkN); %#ok<SAGROW> 
        end
    end
    oddCheckStruct = formattedMat(oddIdx);
    evenCheckStruct = formattedMat(evenIdx);
    oddEqCheck = isequal(oddCheckStruct(:).Data);
    evenEqCheck = isequal(evenCheckStruct(:).Data);
    if oddEqCheck && evenEqCheck % All groups identical. Pick first pair, notify user, then skip to next set       
        toRemRowsID = toUseRows(3:end);
        fprintf('All groups identical for current set. Using first group. Setting toUse = false for rows: %s\n', num2str(toRemRowsID));
        for remN = 1:numel(toRemRowsID)
            formattedMat(toRemRowsID(remN)).toUse = false; %#ok<SAGROW> 
            formattedMat(toRemRowsID(remN)).remReason = 'IDENTICALGROUPS'; %#ok<SAGROW> 
        end
        continue
    end
    %% Generate plots of paired repeats and ask user to select one
    numUserSelRepeats = numUserSelRepeats + 1;
    typeName = typeNames{formattedMat(toUseRows(1)).StepNumber-stepNumberOffset};
    animalName = formattedMat(toUseRows(1)).Lastname;
    numPlots = numel(toUseRows)/2; % Each plot contains 2 subplots (an R plot and an L plot). 1 row x 2 col plots
    if numPlots > numel(perRepeatColors)
        beep;
        fprintf('ERROR:: More repeats than available line colors (see perRepeatColors). Add more colors to perRepeatColors, then re-run this script. Closing...\n');
        return
    end    
    maxYLim = 0;
    minYLim = 0;
    for plotN = 1:numPlots % Find the min/max Y limit to use in the upcoming tiled plot
        endIdx = plotN*2; % Idx in toUseRows
        startIdx = endIdx-1;
        endN = toUseRows(endIdx);
        startN = toUseRows(startIdx);
        currMax = max([max(formattedMat(startN).avgFlash), max(formattedMat(endN).avgFlash)]); % Max y value across R/L
        currMin = min([min(formattedMat(startN).avgFlash), min(formattedMat(endN).avgFlash)]); % min y value across R/L
        if currMax > maxYLim; maxYLim = currMax; end
        if currMin < minYLim; minYLim = currMin; end
    end
    close all
    mainTiled = tiledlayout(numPlots, 2);
    for plotN = 1:numPlots
        endIdx = plotN*2; % Idx in toUseRows
        startIdx = endIdx-1;
        endN = toUseRows(endIdx);
        startN = toUseRows(startIdx);

        nexttile; % R plot
        Tmsec = 1000*([1:formattedMat(startN).Sampleswave]/formattedMat(startN).Samplerate)'; %#ok<NBRAK1>
        plot(Tmsec, formattedMat(startN).avgFlash, perRepeatColors{plotN});
        title([formattedMat(startN).Wavelabel, num2str(plotN), '_RowN=', num2str(startN)], 'Interpreter', 'none', 'Color', perRepeatColors{plotN});
        xlabel('ms');
        ylabel(num2str(plotN), 'FontSize', 14, 'FontWeight', 'bold', 'Rotation', 0, 'Color', perRepeatColors{plotN});
        xlim([0, max(Tmsec)]);
        ylim([minYLim, maxYLim]);
        grid on

        nexttile; % L plot
        Tmsec = 1000*([1:formattedMat(endN).Sampleswave]/formattedMat(endN).Samplerate)'; %#ok<NBRAK1>
        plot(Tmsec, formattedMat(endN).avgFlash, perRepeatColors{plotN});
        title([formattedMat(endN).Wavelabel, num2str(plotN), '_RowN=', num2str(endN)], 'Interpreter', 'none', 'Color', perRepeatColors{plotN});
        xlabel('ms');
        xlim([0, max(Tmsec)]);
        ylim([minYLim, maxYLim]);
        grid on
    end
    sgtitle(['REPEAT', num2str(numUserSelRepeats), '-', animalName, '. ', typeName], ...
        'interpreter', 'none');
    fprintf('REPEAT%i\n', numUserSelRepeats)
    mainTiled.Parent.WindowStyle = 'modal'; % So always displays on top.
    mainTiled.Parent.WindowState = 'maximized'; % Force maximize. 
    promptDlg = strcat('REPEAT', num2str(numUserSelRepeats), '-Select repeat');
    [selRep, validSelection] = listdlg('ListString', string(1:numPlots), 'PromptString', promptDlg, 'SelectionMode', 'single');
    %^ Does prevent user interacting with plot (zoom etc). Might not be an
    %issue with maximized WindowState
    close all
    if ~validSelection % User hit cancel instead of OK
        fprintf("INFO:: Cancel selected. Closing program...\n");
        return
    end
    %% Using user input, set the repeats not selected toUse as false and populate remReason
    startIdxKeep = (selRep*2)-1;
    endIdxKeep = startIdxKeep+1;
    toKeepRows = toUseRows(startIdxKeep:endIdxKeep);
    toRemRows = toUseRows(~ismember(toUseRows, toKeepRows)');
    fprintf('   Selected repeat %i (rows %i and %i)\n', selRep, toKeepRows(1), toKeepRows(2));
    fprintf('   Setting .toUse = false for rows %s\n', num2str(toRemRows));
    for remN = 1:numel(toRemRows)
        formattedMat(toRemRows(remN)).toUse = false; %#ok<SAGROW> 
        formattedMat(toRemRows(remN)).remReason = 'USERREMOVED'; %#ok<SAGROW> 
    end
    fprintf('\n');
end
if numUserSelRepeats == 0
    disp('INFO:: No repeats found that required your input. Saving to _step3Mat...');
end
clearvars -except formattedMat file
splitFile = split(file, '_');
outFile = replace(file, ['_' splitFile{end}], '_step3Mat.mat');
[outFile, outPath] = uiputfile(outFile);
if outFile == 0 % User cancelled prompt
    disp('WARNING:: File selection cancelled. No _step3Mat was created.');
    return;
end 
save(fullfile(outPath, outFile), "formattedMat");
fprintf('Finished removing repeats. See formattedMat in the workspace (look at StepNumber, toUse, and remReason to confirm choices).\n');
fprintf('.mat file saved to %s\n', fullfile(outPath, outFile));