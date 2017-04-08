%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correlate-mac.m
%  Create 802.11g packet and try to correlate the MAC address on sample
%  level
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

% generate payload
tx_psdu = generate_mac_header('ABABABABAB42', 'CDCDCDCDCD43', 'EFEFEFEFEF44');
corr_psdu_1 = generate_mac_header('ABABABABAB42', 'CDCDCDCDCD43', 'EFEFEFEFEF44');
corr_psdu_2 = generate_mac_header('0123456789AB', 'CDEF01234567', 'EFEFEFEFEF44');

% configure 802.11g
cfg = wlanNonHTConfig;
cfg.MCS = 1;  % BPSK, rate 1/2
indField = wlanFieldIndices(cfg);

% get sampling rate
fs = helperSampleRate(cfg);

% initialize scrambler to fixed value
scrambler = de2bi(1, 'left-msb');

% modulate packets
tx = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);
corr_1 = wlanWaveformGenerator(corr_psdu_1, cfg, 'ScramblerInitialization', scrambler);
corr_2 = wlanWaveformGenerator(corr_psdu_2, cfg, 'ScramblerInitialization', scrambler);

% extract data field, containing the MAC addresses
indData = indField.NonHTData(1):indField.NonHTData(2);
data = tx(indData);

% correlate samples to find the addresses
[acor_1, lag_1] = xcorr(tx, corr_1);
[~, I_1] = max(acor_1);
delay_1 = lag(I_1);
[acor_2, lag_2] = xcorr(tx, corr_2);
[~, I_2] = max(acor_2);
delay_2 = lag(I_2);

% plot correlation values and delays
disp(["Correct MAC delay: ", num2str(delay_1)]);
disp(["Different MAC delay: ", num2str(delay_2)]);
plot(lag_1, acor_1, 'b', lag_2, acor_2, 'r');
legend('Correct MAC', 'Different MAC');
