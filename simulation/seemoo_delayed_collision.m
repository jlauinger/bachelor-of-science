%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% seemoo_delayed_collision.m
%
% Required toolboxes:
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all; close all;

referenceSender1 = 'ABABABABAB43';
referenceSender2 = 'EFEFEFEFEF44';
referenceDestination = 'CDCDCDCDCD43';
delayed_samples = 400;
preamble_corr_ratio_threshold = 0.5;

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'];

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               2,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      20e6);        % Sampling rate of the signal

% create signal
tx1_struct = seemoo_generate_signal(SIGNAL, referenceSender1, referenceDestination, 'EFEFEFEFEF44');
tx1_signal = tx1_struct.samples';
tx2_struct = seemoo_generate_signal(SIGNAL, referenceSender2, referenceDestination, 'EFEFEFEFEF44');
tx2_signal = tx2_struct.samples';

% introduce some delay
tx1 = [tx1_signal zeros(1, delayed_samples)];
tx2 = [zeros(1, delayed_samples) tx2_signal];

% apply channel effects
tx1 = awgn(tx1, 18);
tx2 = awgn(tx2, 20);

% oh no, there's a collision!!
tx = tx1 + tx2;

% create modulations of all known MAC addresses and a preamble
ref_mac_samples = zeros(size(macs,1), 320);
for i = 1:size(macs,1)
    corr_struct = seemoo_generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000');
    samples = corr_struct.samples';
    % skip STF(8us),LTF(8us),SIG(4us),
    % {SRV(16b),MAC-start(32b)}*2(enc)=>96b=>96 QAM-syms =>1.8462 OFDM-syms
    % (52 subcarrier used). ==> start after 24us @ 40 MHz = 960 samples
    % MAC address is 48b = 48 QAM-syms = 0.9231 OFDM-syms => we need OFDM
    % symbol 2 and 3 => 8us @ 40 MHz = 320 samples
    ref_mac_samples(i,:) = samples(961:1280);
end
corr_struct = seemoo_generate_signal(SIGNAL, '000000000000', '000000000000', '000000000000');
samples = corr_struct.samples';
% STF+LTF => 16us @ 40MHz = 640 samples
ref_preamble_samples = samples(1:640);

% correlate preamble to find packet starts
[acor_preamble, lag_preamble] = xcorr(tx, ref_preamble_samples);

% plot correlation values and delays
figure(1);
plot(lag_preamble', abs(acor_preamble'));
title("Preamble correlation");

% find three largest spikes => the first two are probably the packets
[~,I] = sort(abs(acor_preamble), 'descend');
i1 = I(1); i2 = I(2); i3 = I(3);
mag1 = abs(acor_preamble(i1)); m2 = abs(acor_preamble(i2)); m3 = abs(acor_preamble(i3));

% compare difference in magnitude between 1/2 and 1/3
d1 = abs(abs(mag1) - abs(m2));
d2 = abs(abs(mag1) - abs(m3));
ratio = d1/d2;

% the higher the ratio, the more likely to have a delay of 0 samples
% therefore check with a threshold
if (ratio > preamble_corr_ratio_threshold)
    % assume there was no delay
    i2 = i1;
end

% remove the correlation offset (negative sliding window) to get the 
% starting samples in tx
i1 = i1 - floor(length(acor_preamble)/2) - 1;
i2 = i2 - floor(length(acor_preamble)/2) - 1;
offsets = sort([i1 i2]);
fprintf(1, "==> Identified delayed packet. Sample offset: %i\n", offsets(2)-offsets(1));

% cut out the part containing the MAC addresses of both samples
tx_mac_samples = tx(961+offsets(1):1280+offsets(2));

% correlate samples to find the addresses
acor = zeros(size(macs,1), size(tx_mac_samples,2)*2-1);
lag = zeros(size(macs,1), size(tx_mac_samples,2)*2-1);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(tx_mac_samples, ref_mac_samples(i,:));
end

% compute reference correlation
[reference_corr,~] = xcorr(tx_mac_samples, tx_mac_samples);
c_ref = abs(reference_corr(ceil(length(reference_corr)/2)));
fprintf(1, "==> Aligned reference correlation: %f\n", c_ref);

% plot correlation values and delays
figure(2);
hold on;
plot(lag', abs(acor'));
lim = ylim();
%plot([i1 i1], [lim(1) lim(2)]);
%plot([i2 i2], [lim(1) lim(2)]);
legend(macs);
title("MAC address correlation");

% calculate correlations for first packet
fprintf(1, "==> Correlations for first packet start (after %i samples)\n", offsets(1));
for i=1:size(macs,1)
    c = abs(acor(i,ceil(size(acor,2)/2+offsets(1))));
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(abs(c)/abs(c_ref)));
end

% calculate correlations for second packet
fprintf(1, "==> Correlations for second packet start (after %i samples)\n", offsets(2));
for i=1:size(macs,1)
    c = abs(acor(i,ceil(size(acor,2)/2+offsets(2))));
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(abs(c)/abs(c_ref)));
end

% calculate matching probabilities for first packet
[mag1, mac1] = max(abs(acor(:,ceil(size(acor,2)/2+offsets(1)))));
fprintf(1, "==> Matching probabilities for first packet (after %i samples)\n", offsets(1));
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*abs(acor(i,ceil(size(acor,2)/2+offsets(1))))/mag1);
end

% calculate matching probabilities for second packet. f the offsets are
% the same, we must use the second likeliest here
[~,I] = sort(abs(acor(:,ceil(size(acor,2)/2+offsets(2)))), 'descend');
mac2_1 = I(1); mac2_2 = I(2);
mag2_1 = abs(acor(mac2_1,ceil(size(acor,2)/2+offsets(2)))); mag2_2 = abs(acor(mac2_2,ceil(size(acor,2)/2+offsets(2))));
fprintf(1, "==> Matching probabilities for second packet (after %i samples)\n", offsets(2));
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*abs(acor(i,ceil(size(acor,2)/2+offsets(2))))/mag2_1);
end
% check if there is any offset and adjust accordingly
if (offsets(1) == offsets(2))
    mac2 = mac2_2;
else
    mac2 = mac2_1;
end
    
fprintf(1, "==> Guessed MAC addresses: %s and %s\n", macs(mac1,:), macs(mac2,:));
