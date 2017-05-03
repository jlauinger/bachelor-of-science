%clear all; close all;

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
ltf_format = 'LTF';

[preamble, stf_t_pre, ltf_t_pre] = ...
    ieeeenc.create_preamble(stf_phase_shift, ltf_format);

ltf_symbol_t = ltf_t_pre(193:320);
stf_symbol_t = stf_t_pre(1:32);

% results

% introduce artificial delay, so that the packet does not begin right at
% the start
% also insert two more copies of the STF to match wl_example_siso plots :)
tx = [tx(1:320); tx(1:320); tx];

% correlate samples to find the LTF
[acor, lag] = xcorr(tx, ltf_symbol_t);
[sts_acor, sts_lag] = xcorr(tx, stf_symbol_t);

lts_corr = abs(conv(conj(fliplr(ltf_symbol_t)), sign(tx)));
sts_corr = abs(conv(conj(fliplr(stf_symbol_t)), sign(tx)));

% remove samples introduced by convolution
lts_corr = lts_corr(length(ltf_symbol_t):end);
sts_corr = sts_corr(length(stf_symbol_t):end);

[~, I] = max(lts_corr);
delay = I;

disp(delay-320*3); % subtract STF length

% plot correlation values (probability of the preamble starting at this
% frame) and show the estimated delay
figure(1); clf; hold on;
title("LTF one-symbol correlation");
plot(lag, abs(acor)*25, 'g');
plot(lts_corr, '.-b', 'LineWidth', 1);
ylims = ylim();
line([960 960], [0 ylims(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([1280 1280], [0 ylims(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([0 0], [0 ylims(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([-200, 2000, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "abs(conv(conj(fliplr(.)),sign(.)))", "LTF start", "LTF end", "Packet start"]);

figure(2); clf; hold on;
title("STF one-symbol correlation");
plot(sts_lag, abs(sts_acor)*25, 'g');
plot(sts_corr, '.-b', 'LineWidth', 1);
ylims = ylim();
line([960 960], [0 ylims(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([0 0], [0 ylims(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([-200, 2000, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "abs(conv(conj(fliplr(.)),sign(.)))", "STF end", "Packet start"]);
