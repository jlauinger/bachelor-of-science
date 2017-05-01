%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% seemoo_fractional_delays.m
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
frac_delay_1 = 0.5;
frac_delay_2 = 0.75;

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'; '000000000000'];

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               1,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      20e6);        % Sampling rate of the signal

% create signal
tx1_struct = seemoo_generate_signal(SIGNAL, referenceSender1, referenceDestination, 'EFEFEFEFEF44');
tx1_signal = tx1_struct.samples';
tx1 = tx1_signal(960:1280);
tx2_struct = seemoo_generate_signal(SIGNAL, referenceSender2, referenceDestination, 'EFEFEFEFEF44');
tx2_signal = tx2_struct.samples';
tx2 = tx2_signal(960:1280);

% now the sender has an out-of-sync clock
d1 = fdesign.fracdelay(frac_delay_1, 1);
Hd1 = design(d1, 'lagrange', 'filterstructure', 'farrowfd');
tx1 = filter(Hd1, tx1);
d2 = fdesign.fracdelay(frac_delay_2, 1);
Hd2 = design(d2, 'lagrange', 'filterstructure', 'farrowfd');
tx2 = filter(Hd2, tx2);

% introduce some attenuation for one of the senders
%tx2 = 0.7*tx2;

% oh no, there's a collision!!
tx = tx1 + tx2;

% create modulations of all known MAC addresses
corr = zeros(size(macs,1), 321);
for i = 1:size(macs,1)
    corr_struct = seemoo_generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000');
    samples = corr_struct.samples';
    corr(i,:) = samples(960:1280);
end

% correlate samples to find the addresses
acor = zeros(size(macs,1), 641);
lag = zeros(size(macs,1), 641);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(tx, corr(i,:));
end

% compute reference correlation
[reference_corr,~] = xcorr(tx, tx);
c1 = reference_corr(ceil(length(reference_corr)/2));

% plot correlation values and delays
plot(lag', abs(acor'));
legend(macs);

fprintf(1, "==> Aligned reference correlation: %f\n", c1);
for i=1:size(macs,1)
    c = acor(i,ceil(size(acor,2)/2));
    fprintf(1, " * %s correlation: %f + %fi  (%f)\n", macs(i,:), real(c), imag(c), abs(c));
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(abs(c)/abs(c1)));
end

[A,I] = sort(acor(:,ceil(size(acor,2)/2)), 'descend');
i1 = I(1); i2 = I(2);
m1 = acor(i1,ceil(size(acor,2)/2)); m2 = acor(i2,ceil(size(acor,2)/2));

fprintf(1, "==> Matching probability\n");
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*abs(acor(i,ceil(size(acor,2)/2)))/m1);
end
    
fprintf(1, "==> Guessed MAC addresses: %s and %s\n", macs(i1,:), macs(i2,:));
