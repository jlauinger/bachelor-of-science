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
tx_psdu = generate_data_mac_frame('0F', 'ABABABABAB42', 'CDCDCDCDCD43', 'EFEFEFEFEF44', [255]);
tx_psdu = int8(tx_psdu');

% configure 802.11g
cfg = wlanNonHTConfig;
cfg.MCS = 1;  % BPSK, rate 1/2
cfg.PSDULength = length(tx_psdu/8);

% get sampling rate
fs = helperSampleRate(cfg);

% initialize scrambler to fixed value
% Note: this would have to be set to all possible values
scrambler = de2bi(1, 'left-msb');

% modulate packet
tx = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);

% Note: tx would now be correlated to a received real-world sample

t=1:length(tx);
plot(t, real(tx)');

% introduce very little AWGN
snr = 60;
rx = awgn(tx, snr);

% get samples offsets for different fields
indField = wlanFieldIndices(cfg);
indLLTF = indField.LLTF(1):indField.LLTF(2);
indData = indField.NonHTData(1):indField.NonHTData(2);

% demodulate long training fields
demodLLTF = wlanLLTFDemodulate(rx(indLLTF), cfg);

% estimate channel and noise
chEst = wlanLLTFChannelEstimate(demodLLTF, cfg);
noiseEst = 1e-6; % depending on SNR

% recover payload data
rx_psdu = wlanNonHTDataRecover(rx(indData,:), chEst, noiseEst, cfg);
% somehow rx_psdu gets replicated 8 times
rx_psdu = rx_psdu(1:length(tx_psdu));

% display bit error rate
ber = biterr(tx_psdu, rx_psdu);
disp(ber);
