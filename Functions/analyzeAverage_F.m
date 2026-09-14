function [minVal, maxVal, aWave, bWave, TTP, TTT] = analyzeAverage_F(searchWindows_ms, sampRateHz, flashAvg, flashType)
%{
% analyzeAverage_F
% PURPOSE: Get min/max/a-wave/b-wave/TTP/TTT from an average
%
% INPUTS:
%   - searchWindows_ms = Nx4 array for N typeNames. [minStart minEnd maxStart maxEnd].
%   - sampRateHz = Sampling rate in Hz
%   - flashAvg = Nx1 voltage (double)
%   - flashType = char of type ('Scotopic 0.01dB-15-1' for example)
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
% AUTHOR: David C Alston (david.alston@louisville.edu) 5-2024
%
% NOTES: Adapted from ERG gui matlab app to be used with new JSON method (11-2022)
%}
win = round((searchWindows_ms/1000) * sampRateHz); % ms -> indices
switch flashType
    case 'Scotopic 0.01dB-15-1'
        cWin = win(1, :); % [minStart minEnd maxStart maxEnd]
    case 'Scotopic 0.01dB-15-2'
        cWin = win(2, :);
    case 'Scotopic 0dB'
        cWin = win(3, :);
    case 'Scotopic 10dB'
        cWin = win(4, :);
    case 'Photopic 0dB'
        cWin = win(5, :);
    case 'Photopic 10dB'
        cWin = win(6, :);
    case 'Photopic Flicker' % Only first min/max for flicker
        cWin = win(7, :);
    otherwise
        beep;
        disp('analyzeAverage_F ERROR:: Unhandled flash type when calculating a/b-wave. Contact David Alston');
        minVal = [0 0];
        maxVal = [0 0];
        aWave = [0 0];
        bWave = [0 0];
        TTP = 0;
        TTT = 0;
        return
end
[minVal(2), minVal(1)] = min(flashAvg(cWin(1):cWin(2))); % Returns [magnitude, index]
[maxVal(2), maxVal(1)] = max(flashAvg(cWin(3):cWin(4)));
[tx, ~] = find(flashAvg == minVal(2));
[px, ~] = find(flashAvg == maxVal(2));
aWave = abs(minVal(2));
TTT = tx/2;
bWave = abs(maxVal(2)) + abs(minVal(2));
TTP = px/2;
end