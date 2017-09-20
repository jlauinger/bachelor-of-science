%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper_mac_sample_indices.m
%
% For a given MCS, return the samples that should contain the MAC address
%
% Required toolboxes:
%  - Communications System Toolbox
%  - WLAN System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function indices = helper_mac_sample_indices(rate, fs)

    if (nargin < 2)
        fs = 20e6;
    end

    factor = fs/20e6;

    if (factor == 1)
        switch rate
            case 0
                indices = 721:880;
            case 1
                indices = 561:720;
            case 2
                indices = 561:640;
            case 3
                indices = 481:560;
            case 4
                indices = 481:560;
            case 5
                indices = 401:480;
            case 6
                indices = 401:480;
            case 7
                indices = 401:480;
            otherwise
                indices = 721:880;
        end
        % Note: since we use wlanNonHTData, there is no preamble -> skip
        % samples
        indices = indices-400;
    elseif (factor == 2)
        switch rate
            case 0
                indices = 1441:1760;
            case 1
                indices = 1121:1440;
            case 2
                indices = 1121:1280;
            case 3
                indices = 961:1121;
            case 4
                indices = 961:1121;
            case 5
                indices = 801:960;
            case 6
                indices = 801:960;
            case 7
                indices = 801:960;
            otherwise
                indices = 1441:1760;
        end
        % Note: since we use wlanNonHTData, there is no preamble -> skip
        % samples
        indices = indices-800;
    end
end
