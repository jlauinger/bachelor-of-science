%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% correlate-preamble.m
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

% configure 802.11g
%cfg = wlanNonHTConfig;
%cfg.MCS = 1;  % BPSK, rate 1/2
%indField = wlanFieldIndices(cfg);

% get sampling rate
%fs = helperSampleRate(cfg);

% initialize scrambler to fixed value
%scrambler = de2bi(1, 'left-msb');

% modulate packet
%tx = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);

% Mock: since I don't have the WLAN Toolbox, use sine for now
t = 0:0.1:10;
tx = sin(t);
preamble = sin(t);

% extract preamble
%indPreamble = indField.SLTF(1):indField.LLTF(2);
%preamble = tx(indPreamble);

% introduce artificial delay, so that the packet does not begin right at
% the start
tx = [zeros(1, 25), tx];

% correlate samples to find the preamble
[acor, lag] = xcorr(tx, preamble);
[~, I] = max(acor);
delay = lag(I);

% plot correlation values (probability of the preamble starting at this
% frame) and show the estimated delay
disp(delay);
plot(lag, acor);
