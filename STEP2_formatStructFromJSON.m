%{
% formatStructFromJSON.m
% PURPOSE: Convert .JSON with ERG data into a standard struct format inside
%   a .mat file. Step 2 in the manual.
%
% INPUTS: A .JSON file containing ERG data.
%
% OUTPUTS: A .mat file containing a struct with data from that .JSON.
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2021a but may work
% on earlier versions). 
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 2-2023
%
% NOTES:
%}
clc
close all
clear
%% Open data from JSON file and convert to mat, then convert waveform data from strings to doubles
[file, path] = uigetfile('*.json');
if file == 0; return; end
fname = fullfile(path, file);
fid = fopen(fname); 
try
    raw = fread(fid, inf); 
    str = char(raw'); 
catch %#ok<CTCH>
    beep;
    disp('ERROR:: File read error. Closing opened file...');
    close(fid);
    return
end
fclose(fid);
fprintf("Converting JSON to .mat struct. Please wait...\n");
val = jsondecode(str);
formattedMat = val.PatientInformation;
for N = 1:numel(formattedMat); formattedMat(N).Data = str2num(formattedMat(N).Data); end %#ok<ST2NM> 
clearvars val str raw
%% Identify repeats (group of rowsPerRepeat with same StepNumber as group before it). 
% Also, set toUse = false for any middle data (where .Wavelabel == [], not 'R' or 'L')
justS = [formattedMat.StepNumber].'; % .MultiData is number of flashes I think (some types have same number of flashes so not unique)
repC = 0;
formattedMat(1).groupStartSearch = true;
formattedMat(1).toUse = true;   % Some set false later in repeat selection
formattedMat(1).remReason = ''; % Reason this row removed (user selected other, repeats are identical, etc)
for N = 2:numel(justS) 
    formattedMat(N).toUse = true;
    formattedMat(N).remReason = '';
    if justS(N) ~= justS(N-1) % If StepNumber changes, this is the start of a new group
        formattedMat(N).groupStartSearch = true;
    else
        formattedMat(N).groupStartSearch = false;
    end
    if isempty(formattedMat(N).Wavelabel) % True if is == [] (not 'R' or 'L')
        formattedMat(N).toUse = false;
        formattedMat(N).remReason = 'AUTOCLEARMID';
    end
end
%% Add new variables for split + averaged for all (including repeats)
for N = 1:numel(formattedMat)
    if numel(formattedMat(N).Data) == formattedMat(N).Sampleswave % Only a single flash (512 x 1, etc)
        formattedMat(N).indivFlash(:, 1) = formattedMat(N).Data;
        formattedMat(N).avgFlash = mean(formattedMat(N).indivFlash, 2);
        fprintf('Only single flash for row %i\n', N);
    else
        for nF = 1:formattedMat(N).Numbertoaverage
            endIdx = nF*formattedMat(N).Sampleswave; % Should always be nF*512
            startIdx = endIdx - formattedMat(N).Sampleswave + 1;
            formattedMat(N).indivFlash(:, nF) = formattedMat(N).Data(startIdx:endIdx);
        end
    end
    formattedMat(N).avgFlash = mean(formattedMat(N).indivFlash, 2);
end
fprintf('Conversion finished.\n');
%% Save formattedMat structure inside a .mat file
splitFile = split(file, '.');
[outFile, outPath] = uiputfile([splitFile{1}, '_step2Mat.mat']);
if outFile == 0; return; end % User cancelled prompt
fprintf('Writing .mat to file. Please wait...\n');
save(fullfile(outPath, outFile), "formattedMat");
fprintf('Done. .mat file saved to %s\n', fullfile(outPath, outFile));