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

function indices = helper_mac_sample_indices(rate)
    switch rate
        case 0
            indices = 561:720;
        case 1
            indices = 481:640;
        case 2
            indices = 481:560;
        case 3
            indices = 401:560;
        case 4
            indices = 401:480;
        case 5
            indices = 401:480;
        case 6
            indices = 401:480;
        case 7
            indices = 401:480;
        otherwise
            indices = 561:720;
    end
end