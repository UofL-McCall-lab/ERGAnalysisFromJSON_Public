%{
    Splits a STEP2 mat multiple STEP2 mat(one mat per unique animal (.Lastname))
    David Alston (david.alston@louisville.edu). 09-2024
%}
clc
close all
clear
%% Select/load STEP2 mat with CWAVENEW data
[file, path] = uigetfile('*.mat', 'Select STEP2 .mat to split on animal name');
if file == 0; return; end % User cancelled prompt
if ~contains(file, '_step2Mat')
    beep;
    fprintf('%s does not contain _step2Mat in filename. Did you select the correct mat? Closing...\n', file);
    return
end
load(fullfile(path, file)); % loads struct called formattedMat
originalMat = formattedMat; % Since other scripts expect the name 'formattedMat', save copy as originalMat so can overwrite formattedMat per protocol
%% Find unique animal names, then determine if .mat splitting needed
byRowAnimal = {originalMat.Lastname}.'; % N x 1 cells containing row by row protocol names
[groupIDVec, uniqueAnimals] = findgroups(byRowAnimal);
for groupN = 1:numel(uniqueAnimals) % Save each mat seperately in the same location as the input path. Append protocol name to mat?
    formattedMat = originalMat(groupIDVec == groupN);
    toAppendName = uniqueAnimals{groupN}; 
    toAppendName(toAppendName == ' ') = []; % Need to remove whitespace in name to append properly
    [~, newFilename, ~] = fileparts(file); % Second ouptut returns filename without extension
    newFilename = strcat(newFilename, '_', toAppendName, '.mat');
    fullOutSubset = fullfile(path, newFilename);
    if isfile(fullOutSubset) % If file already exists
        fprintf('WARNING:: %s already exists. Will overwrite\n', newFilename);
    else
        fprintf('Saving %s...\n', newFilename);
    end
    save(fullOutSubset, 'formattedMat');
end
fprintf('Finished splitting original mat data by animal. Clearing workspace...\n');
clear
fprintf('DONE\n');