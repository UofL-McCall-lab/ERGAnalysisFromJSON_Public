function [meanPowerdB, stdPowerdB, semPowerdB, nFlash, powerFreqsHz] = meanPowerSpectraFromIndivFlashes_F(indivFlash, freqRangeHz, sampleRateHz)
%{
% meanPowerSpectraFromIndivFlashes_F
%
% PURPOSE: Calculate the power spectra per flash, then average those
%   together into a single power spectra. Also calculates the SEM.
%
% INPUTS:
%   - indivFlash = Same format as formattedMat(rowN).indivFlash.
%       -- Usually 512 x nFlash double array.
%       -- Works with single flash
%   - freqRangeHz = As [minFreq maxFreq]. For X limits on power spectra.
%       -- For example, [0 90] for 30Hz photopic flicker.
%   - sampleRateHz = Single integer. Usually 2000 for McCall data.
%
% OUTPUTS:
%   - meanPowerdB, stdPowerdB, semPowerdB = Usually N x 1 double as
%       returned by pspectrum() function.
%       -- N = 4096 for frequency limits of [0 90] at 2000 Hz samp rate
%   - nFlash = Integer number of flashes used.
%   - powerFreqsHz = Same size as meanPowerdB etc. Frequencies for those power
%       values (in Hz).
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2023b but may work
%   on earlier versions). Also, the signal processing toolbox (for the
%   pspectrum() and pow2db() functions).
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 3-2025
%
% NOTES:
%}
nFlash = size(indivFlash, 2);
[~, powerFreqsHz] = pspectrum(indivFlash(:, 1), sampleRateHz, 'FrequencyLimits', freqRangeHz);
for flashN = 1:nFlash
    [p, ~] = pspectrum(indivFlash(:, flashN), sampleRateHz, 'FrequencyLimits', freqRangeHz);
    perFlashPower_dB(:, flashN) = pow2db(p); %#ok<AGROW>
end
meanPowerdB = mean(perFlashPower_dB, 2);
stdPowerdB = std(perFlashPower_dB, 0, 2);
semPowerdB = stdPowerdB / sqrt(nFlash);
end