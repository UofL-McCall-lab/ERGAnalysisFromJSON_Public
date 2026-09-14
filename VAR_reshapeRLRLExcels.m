%{
% VAR_reshapeRLRLExcels.m
% PURPOSE: Take a folder of excel files and reorder all columns so that it
%   is all R then all L (instead of RLRL).
%
% INPUTS: A folder containing excel files.
%
% OUTPUTS: One new excel file per file that had to be reshaped with _RLCorr
%   appended to the filename.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions). 
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 9-2024
%
% NOTES:
%   - Don't use this script if you have the .mat data already. Start with
%       the .mat data and re-export, or write a new script that loads the .mat.
%       Doing any filtering/reshaping will be a lot easier starting from
%       the .mat.
%
%   - Makes some assumptions about where animal name are (see the
%       ismissing(currSheet{1, 4}) check.
%       
%   - Be sure to check the logic this uses if your data is 
%       unusual or messy.
%}
clc
close all
clear
%% Select folder and grab all .xlsx files found
xlsPath = uigetdir('', 'Select folder containing .xlsx files to reorganize');
if xlsPath == 0; return; end % User cancelled prompt
allXlsx = dir(fullfile(xlsPath, '*.xlsx')); % Find all .xlsx files only
fprintf('INFO:: Found %i .xlsx files to check\n', numel(allXlsx));
%% Start reshaping loop
for xlsxN = 1:numel(allXlsx)
    currFullpath = fullfile(allXlsx(xlsxN).folder, allXlsx(xlsxN).name);
    [~, oldName, ~] = fileparts(allXlsx(xlsxN).name);
    newName = [oldName, '_RLCorr.xlsx'];
    newFullpath = fullfile(allXlsx(xlsxN).folder, newName);
    sheetNames = sheetnames(currFullpath);
    fprintf('INFO:: Found %i sheets in file %s\n', numel(sheetNames), allXlsx(xlsxN).name);
    for sheetN = 1:numel(sheetNames)
        currSheet = readcell(currFullpath, 'Sheet', sheetN); 
        %% First, need to find row containing R or L since its variable
        RLRow = -1;
        for RLCheck = 1:5 % Since R/L row isn't always in the same place due to spaces, extra data, etc
            cEntry = currSheet{RLCheck, 1};
            if ismissing(cEntry); continue; end
            if numel(cEntry) > 1; continue; end % Skip extra junk like 'litter 74 Tg + WT hDHA'
            if contains(cEntry, ["R", "L"], 'IgnoreCase', true)
                RLRow = RLCheck;
                break;
            end
        end
        if RLRow == -1
            beep;
            fprintf("ERROR:: Could not find row containing R or L in sheet %s in file %s. Check your excel. Closing...\n", ...
                sheetNames(sheetN), ...
                allXlsx(xlsxN).name);
            return
        end
        %% Replace any lowercase r or l with R or L (so it sorts correctly)
        for colN = 1:size(currSheet, 2)
            RLString = currSheet{RLRow, colN};
            if strcmp(RLString, 'r')
                currSheet{RLRow, colN} = 'R';
            end
            if strcmp(RLString, 'l')
                currSheet{RLRow, colN} = 'L';
            end
        end
        %% Find the row containing the animal number (to keep animal numbers together when sorting RL)
        if ismissing(currSheet{1, 4}) % In case of extra junk like 'litter 74 Tg + WT hDHA'
            animalNumRow = 2;
        else
            animalNumRow = 1; % Should always be 1
        end
        %% Lastly transpose, sort, then transpose again to get all R then all L
        sortedCells = (sortrows(currSheet', RLRow, 'descend'))'; % descend for R then L
        sortedCells = (sortrows(sortedCells', animalNumRow, 'descend'))'; % To group animals together as well
        fprintf("   Writing reordered sheet %i of %i...\n", sheetN, numel(sheetNames))
        writetable(cell2table(sortedCells), newFullpath, 'Sheet', sheetNames(sheetN), 'WriteVariableNames', false, 'WriteMode', 'overwritesheet');
    end
end