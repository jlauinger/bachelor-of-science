%clear all; close all;

% relative correlation threshold to identify the LTF
LTF_CORR_THRESHOLD = 0.8;

% artificially introduced delay (zero samples)
DELAY = 742;


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
tx = [zeros(DELAY, 1); tx];

% correlate samples to find the LTF
[full_ltf_corr, full_ltf_lag] = xcorr(tx, ltf_symbol_t);
[full_stf_corr, full_stf_lag] = xcorr(tx, stf_symbol_t);

% remove correlation values for negative shifts
ltf_corr = full_ltf_corr(ceil(length(full_ltf_corr)/2):end);
stf_corr = full_stf_corr(ceil(length(full_stf_corr)/2):end);
ltf_lag = full_ltf_lag(ceil(length(full_ltf_lag)/2):end);
stf_lag = full_ltf_lag(ceil(length(full_stf_lag)/2):end);


% try to locate the packet start by finding the LTF peaks

% Find all correlation peaks
ltf_peaks = find(ltf_corr > LTF_CORR_THRESHOLD*max(ltf_corr));

% Select best candidate correlation peak as LTS-payload boundary
[LTF1, LTF2] = meshgrid(ltf_peaks, ltf_peaks);
[ltf_second_peak_index, y] = find(LTF2-LTF1 == length(ltf_symbol_t));

% calculate estimated indices
ind.payload = ltf_peaks(max(ltf_second_peak_index)) + 128; % add 128 samples for the symbol itself
ind.ltf = ind.payload - 320; % subtract LTF length
ind.stf = ind.ltf - 320; % subtract STF length


% plot LTF correlation
figure(1); clf; hold on;
title("LTF correlation and packet indices");
plot(ltf_lag, abs(ltf_corr), '.-b', 'LineWidth', 1);
myYlim = ylim();
myXlim = xlim();
line([myXlim(1) myXlim(2)], [LTF_CORR_THRESHOLD*abs(max(ltf_corr)) LTF_CORR_THRESHOLD*abs(max(ltf_corr))], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind.stf ind.stf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind.ltf ind.ltf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind.payload ind.payload], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([0, ind.payload+400, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "LTF correlation threshold", "Packet/STF start", "LTF start", "SIG start"]);

% plot STF correlation
figure(2); clf; hold on;
title("STF correlation and packet indices");
plot(stf_lag, abs(stf_corr), '.-b', 'LineWidth', 1);
myYlim = ylim();
line([ind.stf ind.stf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind.ltf ind.ltf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([0, ind.payload+400, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "Packet/STF start", "LTF start"]);

% plot time domain signal with indices
figure(3); clf; hold on;
title("Tx real waveform with estimated field indices");
plot(real(tx), 'k');
myYlim = ylim();
line([ind.stf ind.stf], [myYlim(1) myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind.ltf ind.ltf], [myYlim(1) myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind.payload ind.payload], [myYlim(1) myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
myAxis = axis();
axis([0, ind.payload+1000, myAxis(3), myAxis(4)])
legend(["Tx", "Packet/STF start", "LTF start", "SIG start"]);


% send some messages to the console
fprintf(1, "Identified packet start after %d samples.\n", ind.stf-1);
