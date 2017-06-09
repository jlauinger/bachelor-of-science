%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find_sender.m
%
% For given parameters, guess and find MAC addresses out of a sample pool.
% Apply different channel effects before correlating.
%
% Required toolboxes:
%  - Communications System Toolbox
%  - WLAN System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function guesses = find_sender_after_channel(reference, macs, senders, rate, snr, model)

% clear all; close all;

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'RATE',               rate,  ...                % Modulation order (0-7)
    'PAYLOAD',            randi([0 255], 1, 1));    % Custom payload data (1 byte)

% configure packets to send
p1 = struct(...
    'sender', senders(1,:), ...
    'duration', 'ffff', ...
    'scrambler', 1);
p2 = struct(...
    'sender', senders(2,:), ...
    'duration', 'ffff', ...
    'scrambler', 1);
    
referenceDestination = macs(1,:);

% create signal
tx1_struct = generate_signal(SIGNAL, referenceDestination, p1.sender, 'EFEFEFEFEF44', p1.duration, p1.scrambler);
tx1_signal = tx1_struct.samples;
tx2_struct = generate_signal(SIGNAL, referenceDestination, p2.sender, 'EFEFEFEFEF44', p2.duration, p2.scrambler);
tx2_signal = tx2_struct.samples;

% if a TGn delay profile is specified, apply the channel
if (model ~= "None") 
    tgnchan = wlanTGnChannel( ...
        'SampleRate', 20e6, ...
        'LargeScaleFadingEffect', 'Pathloss and shadowing', ...
        'NumTransmitAntennas', 1, 'NumReceiveAntennas', 1, ...
        'DelayProfile', model);
    tx1_signal = tgnchan(tx1_signal);
    tx2_signal = tgnchan(tx2_signal);
end

% if a stdchan profile is specified, apply the channel
if (false)
    fs = 20e6;
    fd = 3;
    trms = 100e-9;
    profile = '802.11g';
    chan = stdchan(1/fs, fd, profile, trms);
    tx1_signal = filter(chan, tx1_signal);
    tx2_signal = filter(chan, tx2_signal);
end

% cut the part containing MACs
tx1_mac_t = tx1_signal(helper_mac_sample_indices(rate));
tx2_mac_t = tx2_signal(helper_mac_sample_indices(rate));

% apply AWGN
tx1_mac_t = awgn(tx1_mac_t, snr, 'measured');
tx2_mac_t = awgn(tx2_mac_t, snr, 'measured');

% oh no, there's a collision!!
tx = tx1_mac_t + tx2_mac_t;

% use a row vector from here
tx = tx';

% correlate samples to find the addresses
acor = zeros(size(macs,1), 2*length(tx)-1);
lag = zeros(size(macs,1), 2*length(tx)-1);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(tx, reference(i,:));
end
acor = abs(acor);

% find sample index (x-axis) with the spikes - can be a bit off due to
% channel effects
[~,max_idx] = find(acor==max(acor(:)));

[~,I] = sort(acor(:,max_idx), 'descend');
i1 = I(1); i2 = I(2);

guesses = [macs(i1,:); macs(i2,:)];

end
