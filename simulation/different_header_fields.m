%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% different_header_fields.m
%
% Try and change the duration MAC header field and the scrambler
% initialization
%
% Required toolboxes:
%  - Communications System Toolbox
%  - WLAN System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function different_header_fields(probe)

% clear all; close all;

% configure packets to send
p1 = struct(...
    'sender', 'ABABABABAB43', ...
    'duration', 'ffff', ...
    'scrambler', 1);
p2 = struct(...
    'sender', 'EFEFEFEFEF44', ...
    'duration', 'ffff', ...
    'scrambler', 1);

% configure values under test
if (nargin < 1)
    probe = struct(...
        'duration', '0000', ...
        'scrambler', 1);
end
    
referenceDestination = 'CDCDCDCDCD43';

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['000000000000'; 'ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'];

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'RATE',               0,  ...                   % Modulation order (1-8)
    'PAYLOAD',            randi([0 255], 1, 104));  % Custom payload data

% create signal
tx1_struct = generate_signal(SIGNAL, p1.sender, referenceDestination, 'EFEFEFEFEF44', p1.duration, p1.scrambler);
tx1_signal = tx1_struct.samples';
tx2_struct = generate_signal(SIGNAL, p2.sender, referenceDestination, 'EFEFEFEFEF44', p2.duration, p2.scrambler);
tx2_signal = tx2_struct.samples';

% Configure a Rician channel object
ricChan = comm.RicianChannel( ...
    'SampleRate',              40e6, ...
    'PathDelays',              0.4e-6, ... % 0.4us delay on one path
    'AveragePathGains',        -10, ... % dB
    'MaximumDopplerShift',     20, ... % Hz
    'RandomStream',            'mt19937ar with seed', ...
    'Seed',                    100, ...
    'PathGainsOutputPort',     true);
tx1_signal = ricChan(tx1_signal')';
tx2_signal = ricChan(tx2_signal')';


% cut the part containing MACs
tx1_mac_t = tx1_signal(561:720);
tx2_mac_t = tx2_signal(561:720);

% oh no, there's a collision!!
tx = tx1_mac_t + tx2_mac_t;

% create modulations of all known MAC addresses
mac_reference_corr = zeros(size(macs,1), 160);
for i = 1:size(macs,1)
    corr_struct = generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000', probe.duration, probe.scrambler);
    samples = corr_struct.samples';
    mac_reference_corr(i,:) = samples(561:720);
end

% correlate samples to find the addresses
acor = zeros(size(macs,1), 319);
lag = zeros(size(macs,1), 319);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(tx, mac_reference_corr(i,:));
end
acor = abs(acor);

% compute reference correlation
[auto_corr,~] = xcorr(tx);
c1 = abs(auto_corr(ceil(length(auto_corr)/2)));

% plot correlation values and delays
plot(lag', abs(acor'));
legend(macs);

% find sample index (x-axis) with the spikes - can be a bit off due to
% channel effects
[~,max_idx] = find(acor==max(acor(:)));
fprintf(1, "==> Using fine sample offset: %d\n", max_idx - ceil(size(acor,2)/2));

fprintf(1, "==> Aligned reference correlation: %f\n", c1);
for i=1:size(macs,1)
    c = acor(i,max_idx);
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(c/c1));
end

[A,I] = sort(acor(:,max_idx), 'descend');
i1 = I(1); i2 = I(2);
m1 = acor(i1,max_idx); m2 = acor(i2,max_idx);

fprintf(1, "==> Matching probability\n");
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*acor(i,max_idx)/m1);
end
    
fprintf(1, "==> Guessed MAC addresses: %s and %s\n", macs(i1,:), macs(i2,:));

end