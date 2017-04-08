%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% basic-transmission.m
%  Simulate a 802.11g transmission with an almost noop channel
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

% generate payload
tx_psdu = generate_mac_header('ABABAB42', 'CDCDCD43', 'EFEFEF44');

% configure 802.11g
cfg = wlanNonHTConfig;
cfg.MCS = 1;  % BPSK, rate 1/2

% get sampling rate
fs = helperSampleRate(cfg);

% initialize scrambler to fixed value
% Note: this would have to be set to all possible values
scrambler = de2bi(1, 'left-msb');

% modulate packet
tx = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);

% Note: tx would now be correlated to a received real-world sample

% introduce very little AWGN
snr = 60;
rx = awgn(tx, snr);

% get samples offsets for different fields
indField = wlanFieldIndices(cfg);
indLLTF = indField.LLTF(1):indField.LLTF(2);
indData = indField.LSTF(1):indField.LSIG(2);

% demodulate long training fields
demodLLTF = wlanLLTFDemodulate(rx(indLLTF), cfg);

% estimate channel and noise
chEst = wlanNonHTChannelEstimate(demodLLTF, cfg);
noiseEst = 1e-6; % depending on SNR

% recover payload data
rx_psdu = wlanNonHTDataRecover(rx(indData,:), chEst, noiseEst, cfg);

% display bit error rate
ber = biterr(rx_psdu, tx_psdu);
disp(ber);
