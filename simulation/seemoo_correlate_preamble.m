clear all; close all;

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               2,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      40e6);        % Sampling rate of the signal

% create signal
SIGNAL = ieee_80211g_generate(SIGNAL);
tx = SIGNAL.samples;

% create a reference preamble
ieeeenc = ieee_80211_encoder();

stf_phase_shift = 0;
ltf_format = 'LTF';

[preamble, stf_t_pre, ltf_t_pre] = ...
    ieeeenc.create_preamble(stf_phase_shift, ltf_format);


% results

% introduce artificial delay, so that the packet does not begin right at
% the start
tx = [zeros(242, 1); tx];

% correlate samples to find the preamble
[acor, lag] = xcorr(real(tx), real(preamble));
[~, I] = max(acor);
delay = lag(I);

% plot correlation values (probability of the preamble starting at this
% frame) and show the estimated delay
disp(delay);
l = length(acor);
plot(lag(ceil(l/2):end), acor(ceil(l/2):end));

% try out complex correlation, similar to the one used in
% ieee_80211_encoder

% Complex cross correlation of Rx waveform with time-domain LTF
ltf_corr = abs(conv(conj(fliplr(preamble)), sign(tx)));

% Strip samples introduced by the convolution:
ltf_corr = ltf_corr(1 + (length(preamble) / 2) : end - (length(preamble) / 2));

figure(2);
plot(ltf_corr);

% Find all correlation peaks
ltf_peaks = find(ltf_corr > 0.3 * max(ltf_corr));

disp(ltf_peaks);
% Select best candidate correlation peak as LTF-payload boundary
[LTF1, LTF2] = meshgrid(ltf_peaks, ltf_peaks);
[ltf_second_peak_index, ltf_first_peak_index] = find(LTF2 - LTF1 == length(preamble));

disp(ltf_second_peak_index);