% Showing how to export our structure to JSON if you want to use python etc
% to do analysis.
% David Alston dalston2428@gmail.com 01-2023 
clc
close all
clear
%% Load .mat file to export
[file, path] = uigetfile('*.mat', 'Select .mat to export to JSON');
if file == 0; return; end % User cancelled prompt
load(fullfile(path, file)); % loads struct called formattedMat
%% Encode mat as json format
disp('Converting data to json format. Please wait...');
jsonEncoded = jsonencode(formattedMat, 'PrettyPrint', true);
disp('Conversion finished.');
%% Ask user where to save excel file
splitFile = split(file, '.');
[outFile, outPath] = uiputfile([splitFile{1}, '.json']);
if outFile == 0; disp('Saving cancelled'); return; end % User cancelled prompt
fullOutPath = fullfile(outPath, outFile);
%% Write json file
fid = fopen(fullOutPath, 'w');
fprintf(fid, jsonEncoded);
fclose(fid);
fprintf('Conversion finished. File written to %s\n', fullOutPath);