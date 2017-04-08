%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find_sender.m
%  Create 802.11g packet and try to recognize sender out of an address
%  list, while also varying the scrambler initialization sequence
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['0123456789AB'; 'ABABABABAB42'];

% list of scrambler initializations to try
% NOTE: for now, do not try all initializations to reduce the size of the
% resulting correlations plot (macs * scrambler_inits). Try this out later.
scrambler_inits = (37:47)';

% generate payload
tx_psdu = generate_mac_header('ABABABABAB42', 'CDCDCDCDCD43', 'EFEFEFEFEF44');

% configure 802.11g
cfg = wlanNonHTConfig;
cfg.MCS = 1;  % BPSK, rate 1/2
indField = wlanFieldIndices(cfg);

% get sampling rate
fs = helperSampleRate(cfg);

% initialize scrambler for sender to fixed value, use 42 here
scrambler = de2bi(42, 'left-msb');

% modulate packet
tx = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);

% extract data field, containing the MAC addresses
% NOTE: this is where fine tuning to get the corrects samples that
% represent the MAC address needs to be done
indData = indField.NonHTData(1):indField.NonHTData(2);
data = tx(indData);

% create modulations of all known MAC addresses
corr = zeros(size(macs,1)*length(scrambler_inits), 10000); % change to actual sample length (try it out)
for i = 0:size(scrambler_inits,1):size(macs,1)*size(scrambler_inits,1)
    corr_psdu = generate_mac_header(macs(i,:), '000000000000', '000000000000');
    corr(i:i+size(scrambler_inits,1),:) = wlanWaveformGenerator(corr_psdu, cfg, ...
        'ScramblerInitialization', scrambler_inits, ...
        'NumPackets', size(scrambler_inits,1));
end

% correlate samples to find the addresses
acor = zeros(size(macs,1), 10000); % change to actual sample length (try it out)
lag = zeros(size(macs,1), 10000); % change to actual sample length (try it out)
for i = 0:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(data, corr(i,:));
end

% plot correlation values and delays
plot(lag', acor');
legend(macs);
