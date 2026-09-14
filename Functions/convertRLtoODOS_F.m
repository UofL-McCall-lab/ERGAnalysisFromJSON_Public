function [eyeODOS] = convertRLtoODOS_F(eyeRL)
% Small helper function to convert 'R' 'L' .Wavelabel to OD/OS
% David Alston (david.alston@louisville.edu)
if isempty(eyeRL)
    eyeODOS = 'REF';
else
    switch eyeRL
        case 'R'
            eyeODOS = 'OD';
        case 'L'
            eyeODOS = 'OS';
        otherwise
            beep;
            eyeODOS = "ERR";
            fprintf("ERROR::Unhandled eye. Should be R, L, or empty\n");
    end
end
end