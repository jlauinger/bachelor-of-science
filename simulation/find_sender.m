%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% find_sender.m
%  Create 802.11g packet and try to recognize sender out of an address list
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['0123456789AB'; 'CDEF01234567'; 'CCCCCCCCCCC1'; 'ABABABABAB42'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'];

% generate payload
tx_psdu = generate_mac_header('ABABABABAB42', 'CDCDCDCDCD43', 'EFEFEFEFEF44');

% configure 802.11g
cfg = wlanNonHTConfig;
cfg.MCS = 1;  % BPSK, rate 1/2
indField = wlanFieldIndices(cfg);

% get sampling rate
fs = helperSampleRate(cfg);

% initialize scrambler to fixed value
scrambler = de2bi(1, 'left-msb');

% modulate packet
tx = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);

% extract data field, containing the MAC addresses
% NOTE: this is where fine tuning to get the corrects samples that
% represent the MAC address needs to be done
indData = indField.NonHTData(1):indField.NonHTData(2);
data = tx(indData);

% create modulations of all known MAC addresses
corr = zeros(size(macs,1), 10000); % change to actual sample length (try it out)
for i = 0:size(macs,1)
    corr_psdu = generate_mac_header(macs(i,:), '000000000000', '000000000000');
    corr(i,:) = wlanWaveformGenerator(corr_psdu, cfg, 'ScramblerInitialization', scrambler);
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
