%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% seemoo_equalization.m
%
% Try and find channel effects by preamble correlation, and equalize those
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

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'];

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
tx2_struct = seemoo_generate_signal(SIGNAL, referenceSender2, referenceDestination, 'EFEFEFEFEF44');
tx2_signal = tx2_struct.samples';
tx2 = tx2_signal(1120:1440);

% Configure a Rician channel object
ricChan = comm.RicianChannel( ...
    'SampleRate',              40e6, ...
    'PathDelays',              100e-9, ... % 0.1ns delay on one path !! here be dragons
    'AveragePathGains',        -2, ... % dB
    'MaximumDopplerShift',     20, ... % Hz
    'RandomStream',            'mt19937ar with seed', ...
    'Seed',                    100, ...
    'PathGainsOutputPort',     true);
    %'Visualization',           'Impulse and frequency responses');
tx1_signal = ricChan(tx1_signal')';

rayChan = comm.RayleighChannel( ...
    'SampleRate',          40e6, ...
    'PathDelays',          100e-9, ... 0.25ns delay on one path
    'AveragePathGains',    -2, ... % dB
    'MaximumDopplerShift', 20, ... % Hz
    'RandomStream',        'mt19937ar with seed', ...
    'Seed',                100, ...
    'PathGainsOutputPort', true);
tx2 = rayChan(tx2')';

% apply channel effects
tx1_signal = awgn(tx1_signal, 40);
tx2 = awgn(tx2, 40); % looks horrifying in the plot, but pretty much works up to such low SNR

% IEEE 802.11g decoder settings
settings.receiver.correct_coarse_cfo = true;
settings.receiver.use_fixed_stf_position_for_cfo_correction = true;
settings.receiver.shift_by_detected_position = true;
settings.receiver.fixed_position_shift = 0;
settings.receiver.enable_plotting = false;
settings.receiver.use_ideal_signal_field = true;
settings.receiver.sync_threshold = 0.8;
settings.receiver.sync_search = 'off';
settings.receiver.sync_search_threshold = 1.0;
settings.channel_model.time_shift = 0;
RX = struct(...
    'samples', tx1_signal');
results = ieee_80211g_decode(tx1_struct, RX, settings);
fprintf(1, "BER: %f", results.ber.data_descrambled);

tx1 = tx1_signal(1120:1440);

% for visualization, decode the tx1 BPSK syms and display constellation
constDiag = comm.ConstellationDiagram( ...
    'Name', 'Received Signal After Rician Fading (tx1)', ...
    'ReferenceConstellation', [1 -1]);
demod1 = reshape(tx1(2:end), 160, []);      % parallelize
demod1 = demod1(33:160,:);           % remove CP
demod1 = fft(demod1, 128, 1);        % FFT
demod1 = reshape(demod1, 1, []);    % linerize
constDiag(demod1');

% oh no, there's a collision!!
tx = tx1 + tx2;

% create modulations of all known MAC addresses
corr = zeros(size(macs,1), 321);
for i = 1:size(macs,1)
    corr_struct = seemoo_generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000');
    samples = corr_struct.samples';
    corr(i,:) = samples(1120:1440);
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
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
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
