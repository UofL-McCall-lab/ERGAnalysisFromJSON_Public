function [files] = getAllFiles_F(varargin)
% Return all files in folder plus all of its subfolders.
% Optional typeFilter as a cell vector. For example:
% typeFilter = [{'.csv'}; {'.png'}];
% David Alston (david.alston@louisville.edu)
inputPath = varargin{1};
files = dir(fullfile(inputPath, '**\*.*')); % Get list of files and folders in any subfolder
files = files(~[files.isdir]);        % Remove folders from list
if nargin == 1; return; end % If no filter specified
typeFilter = varargin{2};
keepVec = false(size(files));
for N = 1:numel(files) % Apply filter
    [~, ~, ext] = fileparts(files(N).name);
    for T = 1:numel(typeFilter)
        if strcmp(ext, typeFilter{T}); keepVec(N) = true; end
    end
end
files = files(keepVec);
end