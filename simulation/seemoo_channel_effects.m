%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% seemoo_channel_effects.m
%
% Required toolboxes:
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% clear all; close all;

referenceSender1 = 'ABABABABAB43';
referenceSender2 = 'EFEFEFEFEF44';
referenceDestination = 'CDCDCDCDCD43';

% list of known MAC addresses, could e.g. be obtained from kernel ARP cache
macs = ['000000000000'; 'ABABABABAB42'; 'ABABABABAB43'; 'CDCDCDCDCD43'; 'EFEFEFEFEF44'];

% Signal generation settings IEEE 802.11g OFDM
SIGNAL = struct( ...
    'MOD_TYPE',           '80211g', ... % Signal type (kind of modulation / standard)
    'TYPE',               'DATA', ...   % Data frame
    'PAYLOAD',            randi([0 255], 1, 104), ...  % Custom payload data
    'RATE',               1,  ...       % Modulation order (1-8)
    'SAMPLING_RATE',      40e6);        % Sampling rate of the signal

% create signal
tx1_struct = seemoo_generate_signal(SIGNAL, referenceSender1, referenceDestination, 'EFEFEFEFEF44');
tx1_signal = tx1_struct.samples';
tx2_struct = seemoo_generate_signal(SIGNAL, referenceSender2, referenceDestination, 'EFEFEFEFEF44');
tx2_signal = tx2_struct.samples';

% Configure a Rician channel object
ricChan = comm.RicianChannel( ...
    'SampleRate',              40e6, ...
    'PathDelays',              2e-6, ... % 2us delay on one path !! here be dragons
    'AveragePathGains',        -10, ... % dB
    'MaximumDopplerShift',     20, ... % Hz
    'RandomStream',            'mt19937ar with seed', ...
    'Seed',                    100, ...
    'PathGainsOutputPort',     true);
    %'Visualization',           'Impulse and frequency responses');
tx1_signal = ricChan(tx1_signal')';

rayChan = comm.RayleighChannel( ...
    'SampleRate',          40e6, ...
    'PathDelays',          2e-6, ... 2us delay on one path
    'AveragePathGains',    -10, ... % dB
    'MaximumDopplerShift', 20, ... % Hz
    'RandomStream',        'mt19937ar with seed', ...
    'Seed',                100, ...
    'PathGainsOutputPort', true);
tx2_signal = rayChan(tx2_signal')';

% apply channel effects
tx1_signal = awgn(tx1_signal, 25);
tx2_signal = awgn(tx2_signal, 25); % looks horrifying in the plot, but pretty much works up to such low SNR

% try and decode both packets using the library, to test if the channel
% was really too bad, maybe?
fprintf(1, "==> Trying to decode packets using standard decoder\n");
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
RX = struct('samples', tx1_signal');
results = ieee_80211g_decode(tx1_struct, RX, settings);
fprintf(1, "BER rx1: %f\n", results.ber.data_descrambled);
RX = struct('samples', tx2_signal');
results = ieee_80211g_decode(tx2_struct, RX, settings);
fprintf(1, "BER rx2: %f\n", results.ber.data_descrambled);

% cut the part containing MACs
tx1_mac_t = tx1_signal(1121:1440);
tx2_mac_t = tx2_signal(1121:1440);

% for visualization, decode the tx1 BPSK syms and display constellation
constDiag = comm.ConstellationDiagram( ...
    'Name', 'Received Signal After Rician Fading (tx1)', ...
    'ReferenceConstellation', [1 -1]);
demod1 = reshape(tx1_mac_t, 160, []);      % parallelize
demod1 = demod1(33:160,:);                        % remove CP
demod1 = fft(demod1, 128, 1);                     % FFT
demod1 = reshape(demod1, 1, []);                  % linerize
constDiag(demod1');

% oh no, there's a collision!!
tx = tx1_mac_t + tx2_mac_t;

% create modulations of all known MAC addresses
mac_reference_corr = zeros(size(macs,1), 320);
for i = 1:size(macs,1)
    corr_struct = seemoo_generate_signal(SIGNAL, macs(i,:), '000000000000', '000000000000');
    samples = corr_struct.samples';
    mac_reference_corr(i,:) = samples(1121:1440);
end

% correlate samples to find the addresses
acor = zeros(size(macs,1), 639);
lag = zeros(size(macs,1), 639);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(tx, mac_reference_corr(i,:));
end
acor = abs(acor);

% compute reference correlation
[auto_corr,~] = xcorr(tx);
c1 = abs(auto_corr(ceil(length(auto_corr)/2)));

% plot correlation values and delays
plot(lag', abs(acor'));
legend(macs);

% find sample index (x-axis) with the spikes - can be a bit off due to
% channel effects
[~,max_idx] = max(acor(1,:));
fprintf(1, "==> Using fine sample offset: %d\n", max_idx - ceil(size(acor,2)/2));

fprintf(1, "==> Aligned reference correlation: %f\n", c1);
for i=1:size(macs,1)
    c = acor(i,max_idx);
    fprintf(1, " * %s correlation: %f\n", macs(i,:), c);
    fprintf(1, "   %s ratio: %f dB\n", macs(i,:), 20*log10(c/c1));
end

[A,I] = sort(acor(:,max_idx), 'descend');
i1 = I(1); i2 = I(2);
m1 = acor(i1,max_idx); m2 = acor(i2,max_idx);

fprintf(1, "==> Matching probability\n");
for i=1:size(macs,1)
    fprintf(1, " * %s: %05.2f%%\n", macs(i,:), 100*acor(i,max_idx)/m1);
end
    
fprintf(1, "==> Guessed MAC addresses: %s and %s\n", macs(i1,:), macs(i2,:));
