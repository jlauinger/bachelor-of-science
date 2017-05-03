clear all; close all;

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               1,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      40e6);        % Sampling rate of the signal

% create signal
SIGNAL = ieee_80211g_generate(SIGNAL);
tx = SIGNAL.samples;

% create a reference preamble
ieeeenc = ieee_80211_encoder();
stf_phase_shift = 0;
ltf_format = 'LTF'; % NonHT
[preamble, stf_t_pre, ltf_t_pre] = ...
    ieeeenc.create_preamble(stf_phase_shift, ltf_format);

% cut one individual symbol out of the sequences
ltf_symbol_t = ltf_t_pre(193:320);
stf_symbol_t = stf_t_pre(1:32);

% introduce artificial delay, so that the packet does not begin right at
% the start
% also insert two more copies of the STF to match wl_example_siso plots :)
tx = [zeros(0, 1); tx(1:320); tx(1:320); tx];

% correlate samples to find the LTF
[full_ltf_corr, full_ltf_lag] = xcorr(tx, ltf_symbol_t);
[full_stf_corr, full_stf_lag] = xcorr(tx, stf_symbol_t);

% remove correlation values for negative shifts
ltf_corr = full_ltf_corr(ceil(length(full_ltf_corr)/2):end);
stf_corr = full_stf_corr(ceil(length(full_stf_corr)/2):end);
ltf_lag = full_ltf_lag(ceil(length(full_ltf_lag)/2):end);
stf_lag = full_ltf_lag(ceil(length(full_stf_lag)/2):end);

%[~, I] = max(ltf_corr);
%delay = I;
%disp(delay-320*3); % subtract STF length

% plot correlation values (probability of the preamble starting at this
% frame) and show the estimated delay
figure(1); clf; hold on;
title("LTF one-symbol correlation");
plot(ltf_lag, abs(ltf_corr), '.-b', 'LineWidth', 1);
myYlim = ylim();
line([960 960], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([1280 1280], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([0 0], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([-50, 2000, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "LTF start", "LTF end", "Packet start"]);

figure(2); clf; hold on;
title("STF one-symbol correlation");
plot(stf_lag, abs(stf_corr), '.-b', 'LineWidth', 1);
myYlim = ylim();
line([960 960], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([0 0], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([-50, 2000, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "STF end", "Packet start"]);
