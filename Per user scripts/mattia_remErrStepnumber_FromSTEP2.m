%{
% mattia_remErrStepnumberFromSTEP2.mat
% PURPOSE: Take a STEP2 mat containing a single protocol (created by
%   VAR_splitSTEP2MatOnProtocol), and remove error data. Then, correct
%   remaining data (.stepNumber, etc).
%
% INPUTS: A STEP2 .mat containing a single protocol (use
%   VAR_splitSTEP2MatOnProtocol)
%
% OUTPUTS: A new STEP2 .mat with corrected data
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions). 
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 8-2024
%
% NOTES:
%   - 
%}
clc
close all
clear
%% CONTROLS
stepNumToRemove = 1; % Remove all data with this stepnumber, then correct what is left
%%
[file, path] = uigetfile('*.mat');
if file == 0; return; end % User cancelled prompt
fullPath = fullfile(path, file);
fprintf('Loading %s\n', fullPath);
load(fullPath);
%%
fprintf('Removing data with .StepNumber == %i\n', stepNumToRemove);
toRemRows = find([formattedMat.StepNumber].' == stepNumToRemove);
correctedMat = formattedMat;
correctedMat(toRemRows, :) = [];
toCorrectRows = find([correctedMat.StepNumber].' > stepNumToRemove);
for corrRowN = 1:numel(toCorrectRows)
    correctedMat(toCorrectRows(corrRowN)).StepNumber = correctedMat(toCorrectRows(corrRowN)).StepNumber - 1;
end
%% Check that corrected data has correct number of flashes now
numFlashPerStepNum = [5 15 5 5 30 30 30]';
%{
Number of flashes for each stepnumber (normal as of 8-12-2024):
S1 = 5
S2 = 15
S3 = 5
S4 = 5
S5 = 30
S6 = 30
S7 = 30
%}
for rowN = 1:numel(correctedMat)
    expectedNFlash = numFlashPerStepNum(correctedMat(rowN).StepNumber);
    actualNFlash = size(correctedMat(rowN).indivFlash, 2);
    if actualNFlash ~= expectedNFlash
        beep;
        nFound
        fprintf("ERROR:: Expected %i flashes, found %i flashes for .StepNumber = %i. " + ...
            "See %i row in correctedMat\n", ...
            expectedNFlash, ...
            actualNFlash, ...
            correctedMat(rowN). ...
            StepNumber, rowN);
        return
    end
end
fprintf("Finished without error. Overwriting formattedMat in workspace and clearing other variables. " + ...
    "Save as a new STEP2 mat to continue\n");
formattedMat = correctedMat;
clearvars -except formattedMat;