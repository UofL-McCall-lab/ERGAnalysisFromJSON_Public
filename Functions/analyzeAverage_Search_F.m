function [minVal, maxVal, aWave, bWave, TTP, TTT] = analyzeAverage_Search_F(searchWindow_ms, sampRateHz, flashAvg)
%{
% analyzeAverage_Search_F
% PURPOSE: Get min/max/a-wave/b-wave/TTP/TTT from an average (With input for custom search windows)
%
% INPUTS:
%   - searchWindow_ms = As [minStart minEnd maxStart maxEnd] in
%       milliseconds. For nazarul, one of two sets of windows (one for scotopic,
%       one for photopic). See STEP4_VAR_generateAllAvg_Nazarul.mlx
%   - sampRateHz = Sampling rate in Hz
%   - flashAvg = Nx1 voltage (double)
%
% OUTPUTS:
%   - minVal = Returned as [minX minY]
%   - maxVal = Returned as [maxX maxY]
%   - aWave = Returned as amplitude only
%   - bWave = Returned as amplitude only
%   - TTT = Time to trough in milliseconds
%   - TTP = Time to peak in milliseconds
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2024a but may work
% on earlier versions).
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 6-2024
%
% NOTES: Adapted from ERG gui matlab app to be used with new JSON method (11-2022)
%}
cWin = round((searchWindow_ms/1000) * sampRateHz); % ms -> indices
[minVal(2), minVal(1)] = min(flashAvg(cWin(1):cWin(2))); % Returns [magnitude, index]
[maxVal(2), maxVal(1)] = max(flashAvg(cWin(3):cWin(4)));
[tx, ~] = find(flashAvg == minVal(2));
[px, ~] = find(flashAvg == maxVal(2));
aWave = abs(minVal(2));
TTT = tx/2;
bWave = abs(maxVal(2)) + abs(minVal(2));
TTP = px/2;
end