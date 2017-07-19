%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% seemoo_delayed_collision.m
%
% Required toolboxes:
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all; close all;

% parameters
referenceSender1 = 'ABABABABAB43';
referenceSender2 = 'EFEFEFEFEF44';
referenceDestination = 'CDCDCDCDCD43';
DELAYED_SAMPLES = 42;
PREAMBLE_CORR_RATIO_THRESHOLD = 0.5;
LTF_CORR_THRESHOLD = 0.8;

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'];

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               1,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      40e6);        % Sampling rate of the signal

% create signal
tx1_struct = seemoo_generate_signal(SIGNAL, referenceSender1, referenceDestination, 'EFEFEFEFEF44', 'ff');
tx1_signal = tx1_struct.samples.';
tx2_struct = seemoo_generate_signal(SIGNAL, referenceSender2, referenceDestination, 'EFEFEFEFEF44', 'ff');
tx2_signal = tx2_struct.samples.';

% introduce some delay
tx1 = [tx1_signal zeros(1, DELAYED_SAMPLES)];
tx2 = [zeros(1, DELAYED_SAMPLES) tx2_signal];

% oh no, there's a collision!!
tx = tx1 + tx2;

% create modulations of all known MAC addresses and a preamble
ref_mac_samples = zeros(size(macs,1), 320);
for i = 1:size(macs,1)
    corr_struct = seemoo_generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000', 'ff');
    samples = corr_struct.samples.';
    ref_mac_samples(i,:) = samples(1121:1440);
end
corr_struct = seemoo_generate_signal(SIGNAL, '000000000000', '000000000000', '000000000000', 'ff');
samples = corr_struct.samples.';
ltf_symbol_t = samples(513:640);

% correlate preamble to find packet starts
[full_ltf_corr, full_ltf_lag] = xcorr(tx, ltf_symbol_t);

% remove correlation values for negative shifts
ltf_corr = full_ltf_corr(ceil(length(full_ltf_corr)/2):end);
ltf_lag = full_ltf_lag(ceil(length(full_ltf_lag)/2):end);


% try to locate the packet start by finding the LTF peaks

% Find all correlation peaks
ltf_peaks = find(ltf_corr > LTF_CORR_THRESHOLD*max(ltf_corr));

% Select best candidate correlation peak as LTS-payload boundary
[LTF1, LTF2] = meshgrid(ltf_peaks, ltf_peaks);
[ltf_second_peak_index, y] = find(LTF2-LTF1 == length(ltf_symbol_t));

% calculate estimated indices
% Note: using max and min only works because, here, I trust that there
% are exactly two packets involved in the collision.
ind2.sig = ltf_peaks(max(ltf_second_peak_index)) + 128; % add 128 samples for the symbol itself
ind2.ltf = ind2.sig - 320; % subtract LTF length
ind2.stf = ind2.ltf - 320; % subtract STF length
ind2.payload = ind2.sig + 160; % add 4us SIG field
ind1.sig = ltf_peaks(min(ltf_second_peak_index)) + 128; % add 128 samples for the symbol itself
ind1.ltf = ind1.sig - 320; % subtract LTF length
ind1.stf = ind1.ltf - 320; % subtract STF length
ind1.payload = ind1.sig + 160; % add 4us SIG field

% plot LTF correlation
figure(1); clf; hold on;
title("LTF correlation and packet indices");
plot(ltf_lag, abs(ltf_corr), '.-b', 'LineWidth', 1);
myYlim = ylim();
myXlim = xlim();
line([myXlim(1) myXlim(2)], [LTF_CORR_THRESHOLD*abs(max(ltf_corr)) LTF_CORR_THRESHOLD*abs(max(ltf_corr))], 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2);
line([ind1.stf ind1.stf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind1.ltf ind1.ltf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind1.sig ind1.sig], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind1.payload ind1.payload], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
p=patch(ind1.payload+[320 640 640 320], [0 0 myYlim(2) myYlim(2)], 'r');
set(p,'FaceAlpha',0.2);
line([ind2.stf ind2.stf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind2.ltf ind2.ltf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind2.sig ind2.sig], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind2.payload ind2.payload], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
p=patch(ind2.payload+[320 640 640 320], [0 0 myYlim(2) myYlim(2)], 'g');
set(p,'FaceAlpha',0.2);
myAxis = axis();
axis([-30, ind2.payload+800, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "LTF correlation threshold", ...
    "1. Packet/STF start", "1. LTF start", "1. SIG start", "1. DATA start", "1. MAC interval", ...
    "2. Packet/STF start", "2. LTF start", "2. SIG start", "2. DATA start", "2. MAC interval"]);

% throw the estimated delay to the console
fprintf(1, "==> Identified delayed packet. Sample offset: %i\n", ind2.stf-ind1.stf);

% cut out the part containing the MAC addresses of both samples
tx_mac_samples = tx(ind1.payload+320+1:ind2.payload+320+320);

% correlate samples to find the addresses
corr = zeros(size(macs,1), size(tx_mac_samples,2)*2-1);
lag = zeros(size(macs,1), size(tx_mac_samples,2)*2-1);
for i = 1:size(macs,1)
    [corr(i,:), lag(i,:)] = xcorr(tx_mac_samples, ref_mac_samples(i,:));
end

% compute reference correlation
[reference_corr,~] = xcorr(tx_mac_samples);
c_ref = abs(reference_corr(ceil(length(reference_corr)/2)));
fprintf(1, "==> Aligned reference correlation: %f\n", c_ref);

% plot correlation values and delays
figure(2); clf;
hold on;
plot(lag', abs(corr'));
legend(macs);
title("MAC address correlation");

% calculate correlations for first packet
fprintf(1, "==> Correlations for first packet start (after %i samples)\n", ind1.stf-1);
for i=1:size(macs,1)
    c = abs(corr(i,ceil(size(corr,2)/2)));
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(abs(c)/abs(c_ref)));
end

% calculate correlations for second packet
fprintf(1, "==> Correlations for second packet start (after %i samples)\n", ind2.stf-1);
for i=1:size(macs,1)
    c = abs(corr(i,ceil(size(corr,2)/2+(ind2.stf-ind1.stf))));
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(abs(c)/abs(c_ref)));
end

% calculate matching probabilities for first packet
[mag1, mac1] = max(abs(corr(:,ceil(size(corr,2)/2))));
fprintf(1, "==> Matching probabilities for first packet (after %i samples)\n", ind1.stf-1);
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*abs(corr(i,ceil(size(corr,2)/2)))/mag1);
end

% calculate matching probabilities for second packet. f the offsets are
% the same, we must use the second likeliest here
[~,I] = sort(abs(corr(:,ceil(size(corr,2)/2+(ind2.stf-ind1.stf)))), 'descend');
mac2_1 = I(1); mac2_2 = I(2);
mag2_1 = abs(corr(mac2_1,ceil(size(corr,2)/2+(ind2.stf-ind1.stf)))); mag2_2 = abs(corr(mac2_2,ceil(size(corr,2)/2+(ind2.stf-ind1.stf))));
fprintf(1, "==> Matching probabilities for second packet (after %i samples)\n", ind2.stf-1);
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*abs(corr(i,ceil(size(corr,2)/2+(ind2.stf-ind1.stf))))/mag2_1);
end
% check if there is any offset and adjust accordingly
if (ind1.stf == ind2.stf)
    mac2 = mac2_2;
else
    mac2 = mac2_1;
end
    
fprintf(1, "==> Guessed MAC addresses: %s and %s\n", macs(mac1,:), macs(mac2,:));
