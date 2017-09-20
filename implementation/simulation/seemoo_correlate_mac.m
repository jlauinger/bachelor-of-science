% clear all; close all;

referenceMac = 'ABABABABAB42';
candidateMac = '000000000000';

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               1,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      40e6);        % Sampling rate of the signal

% create signals
tx_struct = seemoo_generate_signal(SIGNAL, referenceMac, 'CDCDCDCDCD43', 'EFEFEFEFEF44', 'ff');
corr1_struct = seemoo_generate_signal(SIGNAL, referenceMac, 'CDCDCDCDCD43', 'EFEFEFEFEF44', 'ff');
corr2_struct = seemoo_generate_signal(SIGNAL, candidateMac, 'CDCDCDCDCD43', 'EFEFEFEFEF44', 'ff');
tx_signal = tx_struct.samples.';
corr1_signal = corr1_struct.samples.';
corr2_signal = corr2_struct.samples.';

% Data Field starts after STF (8 us) + LTF (8 us) + SIG (4 us) = 
% 20 us @ 40 MHz = 800 samples
% MAC address is 6 Bytes with 6 Byte offset (2B SRV + 4B MAC beginning)
% BPSK and 48 SCs yield 48 bit = 6 Byte per OFDM symbol, but need to think
% about 1/2 encoding => 3 Byte per OFDM symbol
% Therefore addr1 is in the third and fourth OFDM symbol (8 us) in Data
% 8 us @ 40 MHz = 320 samples
tx = tx_signal(1121:1440);
corr1 = corr1_signal(1121:1440);
corr2 = corr2_signal(1121:1440);

% Note: the next OFDM symbol (1440:1600) is also different in time domain.
% This is because the Trellis convolutional encoder is stateful, hence due
% to the differing data in the last symbol, the next symbol will get
% encoded differently.

% results

% correlate samples to find the MAC addresses
[acor1, lag1] = xcorr(real(tx), real(corr1));
[acor2, lag2] = xcorr(real(tx), real(corr2));

% plot correlation values (probability of the preamble starting at this
% frame) and show the estimated delay
figure(1);
plot(lag1, acor1, '-b*', lag2, acor2, '-r*');
legend('reference', 'candidate');
title('cross correlation');

figure(2);
t = 1:320;
plot(t, real(corr1), 'b', t, real(corr2), 'r');
legend('reference', 'candidate');
title('MAC addr 1 (real)');

figure(3);
t = 1:length(tx_signal);
plot(t, real(corr1_signal), 'b', t, real(corr2_signal), 'r');
legend('reference', 'candidate');
title('Complete signal (real)');

l = length(acor1);
c1 = acor1(ceil(l/2));
c2 = acor2(ceil(l/2));

fprintf(1, "maximum reference correlation: %f (%s)\n", max(acor1), referenceMac);
fprintf(1, "maximum candidate correlation: %f (%s)\n", max(acor2), candidateMac);
fprintf(1, "aligned reference correlation: %f\n", c1);
fprintf(1, "aligned candidate correlation: %f\n", c2);
fprintf(1, "candidate correlation ratio: %f dB\n", 20*log10(abs(c2)/abs(c1)));

