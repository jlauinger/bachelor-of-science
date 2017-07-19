%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate_signal_pool.m
%
% Create signals to check against 
%
% Required toolboxes:
%  - Communications System Toolbox
%  - WLAN System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function reference = generate_signal_pool(macs, rate, destination, scrambler, fs)

    if (nargin < 5)
        fs = 20e6;
    end

    % Signal generation settings IEEE 802.11g OFDM
    SIGNAL = struct( ...
        'RATE',               rate,  ...                % Modulation order (0-7)
        'PAYLOAD',            randi([0 255], 1, 1));    % Custom payload data (1 byte)
    
    indices = helper_mac_sample_indices(rate, fs);
    
    % create modulations of all known MAC addresses
    reference = zeros(size(macs,1), length(indices));
    for i = 1:size(macs,1)
        signal_struct = generate_signal(SIGNAL, destination, macs(i,:), '000000000000', 'FFFF', scrambler, 0);
        samples = signal_struct.samples.';
        
        % interpolate the signal to increase the sampling rate if necessary
        %samples = resample(samples, fs / 20e6, 1);
       
        reference(i,:) = samples(indices);
    end
end

