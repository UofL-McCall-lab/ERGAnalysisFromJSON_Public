clc
close all
clear
addpath(genpath('Example data'));
%%
load('Olix (Baseline)_step4Mat'); % Change this to any .mat you have (at least STEP3 finished)
%% Find which rows in formattedMat have toUse == true
toUseVector = [formattedMat.toUse].';
%% Find all unique names, then which rows in formattedMat have which names
allLastNames = {formattedMat.Lastname}.';
uniqueLastNames = unique(allLastNames);
disp(uniqueLastNames); % Show unique names in command window
currLastNameVector = false([numel(allLastNames), numel(uniqueLastNames)]); % [numRowsInFormattedMat x numUniqueNames]. So each column is for each unique name
for uniqueNameNum = 1:numel(uniqueLastNames)
    currLastName = uniqueLastNames{uniqueNameNum};
    currLastNameVector(:, uniqueNameNum) = contains(allLastNames, currLastName);
end
%% Get all the data for unique name N where toUse == true
N = 2; % See uniqueLastNames in workspace
toGrabVector = toUseVector & currLastNameVector(:, N); % True where toUse == true, AND for the specific animal
grabbedData = formattedMat(toGrabVector);
%^ Look at grabbedData in workspace