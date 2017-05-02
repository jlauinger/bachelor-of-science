%clear all; close all;

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

ltf_symbol_t = ltf_t_pre(193:320);

% results

% introduce artificial delay, so that the packet does not begin right at
% the start

tx = [zeros(0, 1); tx];

% correlate samples to find the LTF
[acor, lag] = xcorr(tx, ltf_symbol_t);
[~, I] = max(acor);
delay = lag(I);

lts_corr = abs(conv(conj(fliplr(ltf_symbol_t)), sign(tx)));

% plot correlation values (probability of the preamble starting at this
% frame) and show the estimated delay
figure(1); clf; hold on;
disp(delay-320); % subtract STF length
l = length(acor);
plot(lag, abs(acor), 'g');
plot(lts_corr/35, 'b');
myAxis = axis();
axis([1, 2000, myAxis(3), myAxis(4)])
