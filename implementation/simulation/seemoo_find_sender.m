%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% seemoo_find_sender.m
%  Create 802.11g packet and try to recognize sender out of an address list
%  Uses Seemoo ieee_80211 implementation
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all; close all;

referenceSender = 'ABABABABAB43';
referenceDestination = 'CDCDCDCDCD43';

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'; '000000000000'];

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               1,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      40e6);        % Sampling rate of the signal

% create signal
tx_struct = seemoo_generate_signal(SIGNAL, referenceSender, 'CDCDCDCDCD43', 'EFEFEFEFEF44', 'ff');
tx_signal = tx_struct.samples.';
tx = tx_signal(1121:1440);

% create modulations of all known MAC addresses
corr = zeros(size(macs,1), length(tx));
for i = 1:size(macs,1)
    corr_struct = seemoo_generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000', 'ff');
    samples = corr_struct.samples.';
    corr(i,:) = samples(1121:1440);
end

% correlate samples to find the addresses
acor = zeros(size(macs,1), 2*length(tx)-1);
lag = zeros(size(macs,1), 2*length(tx)-1);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(real(tx), real(corr(i,:)));
end

% compute reference correlation
[reference_corr,~] = xcorr(real(tx), real(tx));
c1 = reference_corr(ceil(length(reference_corr)/2));

% plot correlation values and delays
plot(lag', acor');
legend(macs);

fprintf(1, "==> Aligned reference correlation: %f\n", c1);
for i=1:size(macs,1)
    c = acor(i,ceil(size(acor,2)/2));
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(abs(c)/abs(c1)));
end

[m,I] = max(acor(:,ceil(size(acor,2)/2))');

fprintf(1, "==> Matching probability\n");
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*abs(acor(i,ceil(size(acor,2)/2)))/m);
end
    
fprintf(1, "==> Best guess MAC address: %s\n", macs(I,:));


