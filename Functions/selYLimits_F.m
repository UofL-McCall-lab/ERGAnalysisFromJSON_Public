function [yLimits, baselineW] = selYLimits_F(animalType, flashType)
%{
% selYLimits_F
% PURPOSE: Select plot Y limits based on animal type (Tg or Wt) and flash
% type (Photopic flicker, Scotopic 0 dB, etc)
%
% INPUTS:
%   - animalType = Char of animal type ('Tg' or 'Wt')
%   - flashType = Char of flash type. See plotNames control in orgIntoMat.m
%   script.
%
% OUTPUTS:
%   - yLimits = In the form [yMin yMax] (microvolts)
%   - baselineW = Baseline width in samples
%
% DEPENDENCIES: Basic MATLAB install (built/tested on R2021a but may work
% on earlier versions).
%
% AUTHOR: David C Alston (david.alston@louisville.edu) 1-2023
%
% NOTES: Adapted from ERG gui matlab app to be used with new JSON method (11-2022)
%}
if strcmpi(animalType, 'Tg')
    switch flashType
        case 'Scotopic 0.01dB-15-1'
            yLimits = [-40 90];
            baselineW = 20;
        case 'Scotopic 0.01dB-15-2'
            yLimits = [-20 40];
            baselineW = 20;
        case 'Scotopic 0dB'
            yLimits = [-100 250];
            baselineW = 20;
        case 'Scotopic 10dB'
            yLimits = [-100 300];
            baselineW = 20;
        case 'Photopic 0dB'
            yLimits = [-100 300];
            baselineW = 10;
        case 'Photopic 10dB'
            yLimits = [-100 300];
            baselineW = 10;
        case 'Photopic Flicker'
            yLimits = [-200 500];
            baselineW = 10;
        otherwise
            beep;
            disp('selYLimits_F ERROR:: Unhandled Tg flash type. Returning yLim = [-300 500] microvolts and baselineW = 10 samples');
            yLimits = [-300 500];
            baselineW = 10;
    end
else % Wt
    if strcmpi(animalType, 'Wt')
        switch flashType
            case 'Scotopic 0.01dB-15-1'
                yLimits = [-40 250];
                baselineW = 20;
            case 'Scotopic 0.01dB-15-2'
                yLimits = [-30 250];
                baselineW = 20;
            case 'Scotopic 0dB'
                yLimits = [-300 400];
                baselineW = 20;
            case 'Scotopic 10dB'
                yLimits = [-300 450];
                baselineW = 20;
            case 'Photopic 0dB'
                yLimits = [-100 400];
                baselineW = 10;
            case 'Photopic 10dB'
                yLimits = [-200 400];
                baselineW = 10;
            case 'Photopic Flicker'
                yLimits = [-300 500];
                baselineW = 10;
            otherwise
                beep;
                disp('selYLimits_F ERROR:: Unhandled Wt flash type. Returning yLim = [-300 500] microvolts and baselineW = 10 samples');
                yLimits = [-300 500];
                baselineW = 10;
        end
    end
end
end