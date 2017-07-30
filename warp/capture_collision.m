%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% capture_collision.m
%  Use 3 WARPs to capture a real-life collision
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% important resource:
% https://warpproject.org/trac/browser/ResearchApps/PHY/WARPLAB/WARPLab7/M_Code_Examples/wl_example_siso_ofdm_txrx.m
%
% very good explanation on how to send using WARPs


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

filename_macs = "data/mac-addresses-eduroam-20170516.dat";
NUM_ADDRESSES_TO_USE    = 30;          % limit simulation time

RATE                    = 0;           % MCS
MAX_TX_LEN              = 2^20;        % 2^20 =  1048576 --> Soft max TX / RX length for WARP v3 Java Transport (WARPLab 7.5.x)

LTF_CORR_THRESHOLD      = 0.8;         % threshold to detect LTF correlation peaks
PACKET_DELAY            = 0;           % software tx delay
CUTAWAY_LENGTH          = 150;         % for LTF correlation, cut away some noisy samples in the beginning

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

destination             = macs(1,:);
sender1                 = macs(4,:);
sender2                 = macs(5,:);

fprintf(1, "==> Using senders: %s and %s\n", sender1, sender2);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% setup WARP nodes

% Create a vector of node objects
nodes   = wl_initNodes(3);
node_tx1 = nodes(1);
node_tx2 = nodes(2);
node_rx = nodes(3);

% Create a UDP broadcast trigger and tell each node to be ready for it
eth_trig = wl_trigger_eth_udp_broadcast;
wl_triggerManagerCmd(nodes, 'add_ethernet_trigger', eth_trig);

% Read Trigger IDs into workspace
[T_IN_ETH_A, T_IN_ENERGY, T_IN_AGCDONE, T_IN_REG, T_IN_D0, T_IN_D1, T_IN_D2, T_IN_D3, T_IN_ETH_B] =  wl_getTriggerInputIDs(nodes(1));
[T_OUT_BASEBAND, T_OUT_AGC, T_OUT_D0, T_OUT_D1, T_OUT_D2, T_OUT_D3] = wl_getTriggerOutputIDs(nodes(1));

% For all nodes, we will allow Ethernet to trigger the buffer baseband and the AGC
wl_triggerManagerCmd(nodes, 'output_config_input_selection', [T_OUT_BASEBAND, T_OUT_AGC], [T_IN_ETH_A]);

% Set the trigger output delays.
nodes.wl_triggerManagerCmd('output_config_delay', T_OUT_BASEBAND, 0);
nodes.wl_triggerManagerCmd('output_config_delay', T_OUT_AGC, 3000); % 3000 ns delay before starting the AGC

% Get IDs for the interfaces on the boards. 
[RFA,RFB,RFC] = wl_getInterfaceIDs(nodes(1));

% Set up the interface for the experiment
wl_interfaceCmd(nodes, 'RF_ALL', 'tx_gains', 0, 2);
wl_interfaceCmd(node_tx1, RFA, 'tx_gains', 3, 30);
wl_interfaceCmd(nodes, 'RF_ALL', 'channel', 2.4, 11);

% AGC setup
wl_interfaceCmd(nodes, 'RF_ALL', 'rx_gain_mode', 'automatic');
wl_basebandCmd(nodes, 'agc_target', -10);

% Get parameters from the node
SAMP_FREQ    = wl_basebandCmd(nodes(1), 'tx_buff_clk_freq');
Ts           = 1/SAMP_FREQ;

% get tx length
maximum_buffer_len = wl_basebandCmd(node_tx1, RFA, 'tx_buff_max_num_samples');
txLength = min(MAX_TX_LEN, maximum_buffer_len);
rxLength = txLength;

% set up baseband
wl_basebandCmd(nodes, 'tx_delay', 0);
wl_basebandCmd(nodes, 'tx_length', txLength);
wl_basebandCmd(nodes, 'rx_length', rxLength);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% modulate packets to transmit

SIGNAL = struct( ...
    'RATE',               RATE,  ...                % Modulation order (0-7)
    'PAYLOAD',            randi([0 255], 1, 1));    % Custom payload data (1 byte)

tx1_struct = generate_signal(SIGNAL, destination, sender1, 'EFEFEFEFEF44', 'ffff', 1, 1);
tx1_signal = tx1_struct.samples;
tx2_struct = generate_signal(SIGNAL, destination, sender2, 'EFEFEFEFEF44', 'ffff', 1, 1);
tx2_signal = tx2_struct.samples;

% interpolate to get from 20 to 40 MHz sampling rate
tx1_signal = resample(tx1_signal, 40, 20);
tx2_signal = resample(tx2_signal, 40, 20);

% Scale the Tx vector to +/- 1
tx1_vec_air = tx1_signal ./ max(abs(tx1_signal));
tx2_vec_air = tx2_signal ./ max(abs(tx2_signal));

% Prepend some zeros to delay one of the transmissions
tx1_vec_air = [tx1_vec_air; zeros(PACKET_DELAY, 1)];
tx2_vec_air = [zeros(PACKET_DELAY, 1); tx2_vec_air];

TX_NUM_SAMPS = length(tx1_vec_air);
RX_NUM_SAMPS = TX_NUM_SAMPS;

wl_basebandCmd(nodes, 'tx_delay', 0);
wl_basebandCmd(nodes, 'tx_length', TX_NUM_SAMPS);   % Number of samples to send
wl_basebandCmd(nodes, 'rx_length', TX_NUM_SAMPS);   % Number of samples to receive


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WARPLab Tx/Rx

% Write the Tx waveforms to the Tx nodes
wl_basebandCmd(node_tx1, RFA, 'write_IQ', tx1_vec_air(:));
wl_basebandCmd(node_tx2, RFA, 'write_IQ', tx2_vec_air(:));

% Enable the Tx and Rx radios
wl_interfaceCmd(node_tx1, RFA, 'tx_en');
wl_interfaceCmd(node_tx2, RFA, 'tx_en');
wl_interfaceCmd(node_rx, RFA, 'rx_en');

% Enable the Tx and Rx buffers
wl_basebandCmd(node_tx1, RFA, 'tx_buff_en');
wl_basebandCmd(node_tx2, RFA, 'tx_buff_en');
wl_basebandCmd(node_rx, RFA, 'rx_buff_en');

% Trigger the Tx/Rx cycle at all nodes
eth_trig.send();

% Wait until the TX / RX is done
pause(1.2 * txLength * Ts);

% Retrieve the received waveform from the Rx node
rx_vec_air = wl_basebandCmd(node_rx, RFA, 'read_IQ', 0, RX_NUM_SAMPS);
rx_vec_air = rx_vec_air(:).';

% Disable the buffers and RF interfaces for TX / RX
wl_basebandCmd(nodes, 'RF_ALL', 'tx_rx_buff_dis');
wl_interfaceCmd(nodes, 'RF_ALL', 'tx_rx_dis');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% write away all the data

csvwrite(sprintf('results/wl-rx_capture-%s.csv', datetime('now','Format','yyyyMMdd-HHmm')), rx_vec_air);
csvwrite(sprintf('results/wl-tx1_samples-%s.csv', datetime('now','Format','yyyyMMdd-HHmm')), tx1_vec_air);
csvwrite(sprintf('results/wl-tx2_samples-%s.csv', datetime('now','Format','yyyyMMdd-HHmm')), tx2_vec_air);

fprintf(1, "==> Wrote tx1, tx2, and rx samples to disk.\n");


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% try and correlate the LTF

% remove first samples (too much noise)
rx_vec_air = rx_vec_air(CUTAWAY_LENGTH+1:end);

% =========== skip WARP entirely!!
% rx_vec_air = tx1_vec_air + tx2_vec_air;
% rx_vec_air = rx_vec_air(:).';
% ===========

rx_vec_air = resample(rx_vec_air, 20, 40);

% create a reference preamble
ieeeenc = ieee_80211_encoder();
stf_phase_shift = 0;
ltf_format = 'LTF'; % NonHT
[preamble, stf_t_pre, ltf_t_pre] = ...
    ieeeenc.create_preamble(stf_phase_shift, ltf_format);

% cut one individual symbol out of the sequences
ltf_symbol_t = ltf_t_pre(193:320);
ltf_symbol_t = resample(ltf_symbol_t, 20, 40);

% correlate samples to find the LTF
[full_ltf_corr, full_ltf_lag] = xcorr(rx_vec_air, ltf_symbol_t);

% remove correlation values for negative shifts
ltf_corr = full_ltf_corr(ceil(length(full_ltf_corr)/2):end);
ltf_lag = full_ltf_lag(ceil(length(full_ltf_lag)/2):end);

% try to locate the packet start by finding the LTF peaks
% Find all correlation peaks
ltf_peaks = find(abs(ltf_corr) > LTF_CORR_THRESHOLD*max(abs(ltf_corr)));

% As I trust here that there are exactly two packets, I cluster the peaks
% into 4 means to get rid of very close values
if (length(ltf_peaks) > 4)
    [~, C] = kmeans(ltf_peaks', 4);
    uniq_ltf_peaks = sort(floor(C))';
else
    uniq_ltf_peaks = ltf_peaks;
end

% Select best candidate correlation peak as LTS-payload boundary
[LTF1, LTF2] = meshgrid(uniq_ltf_peaks, uniq_ltf_peaks);
[ltf_second_peak_index, y] = find(iswithin(LTF2-LTF1, length(ltf_symbol_t)/1.2, length(ltf_symbol_t)*1.2));

% calculate estimated indices
% Note: using max and min only works because, here, I trust that there
% are exactly two packets involved in the collision.
ind2.sig = uniq_ltf_peaks(max(ltf_second_peak_index)) + 64; % add 64 samples for the symbol itself
ind2.ltf = ind2.sig - 160; % subtract LTF length
ind2.stf = ind2.ltf - 160; % subtract STF length
ind2.payload = ind2.sig + 80; % add 4us SIG field
ind1.sig = uniq_ltf_peaks(min(ltf_second_peak_index)) + 64; % add 64 samples for the symbol itself
ind1.ltf = ind1.sig - 160; % subtract LTF length
ind1.stf = ind1.ltf - 160; % subtract STF length
ind1.payload = ind1.sig + 80; % add 4us SIG field

% plot LTF correlation
figure(1); clf; hold on;
title("LTF correlation and packet indices (real-world data)");
plot(ltf_lag, abs(ltf_corr), '.-b', 'LineWidth', 1);
myYlim = ylim();
myXlim = xlim();
line([myXlim(1) myXlim(2)], [LTF_CORR_THRESHOLD*abs(max(ltf_corr)) LTF_CORR_THRESHOLD*abs(max(ltf_corr))], 'LineStyle', '--', 'Color', 'k', 'LineWidth', 2);
line([ind1.stf ind1.stf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind1.ltf ind1.ltf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind1.sig ind1.sig], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
line([ind1.payload ind1.payload], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'r', 'LineWidth', 2);
p=patch(ind1.payload+[160 320 320 160], [0 0 myYlim(2) myYlim(2)], 'r');
set(p,'FaceAlpha',0.2);
line([ind2.stf ind2.stf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind2.ltf ind2.ltf], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind2.sig ind2.sig], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
line([ind2.payload ind2.payload], [0 myYlim(2)], 'LineStyle', '--', 'Color', 'g', 'LineWidth', 2);
p=patch(ind2.payload+[320 480 480 320], [0 0 myYlim(2) myYlim(2)], 'g');
set(p,'FaceAlpha',0.2);
myAxis = axis();
axis([-10, ind2.payload+600, myAxis(3), myAxis(4)])
legend(["abs(xcorr(.,.))", "LTF correlation threshold", ...
    "1. Packet/STF start", "1. LTF start", "1. SIG start", "1. DATA start", "1. MAC interval", ...
    "2. Packet/STF start", "2. LTF start", "2. SIG start", "2. DATA start", "2. MAC interval"]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% try to correlate and guess MACs

reference_signals = generate_signal_pool(macs, RATE, macs(1,:), 1, 20e6);

% cut out the part containing the MAC addresses of both samples
rx_offset = ind1.stf + CUTAWAY_LENGTH - 1;
indices = helper_mac_sample_indices(RATE, 20e6);
start = ind1.payload+indices(1)+rx_offset-1; stop = ind2.payload+indices(end)+rx_offset-1;
rx_to_corr = rx_vec_air(start:stop);

% correlate samples to find the addresses
corr = zeros(size(macs,1), size(rx_to_corr,2)*2-1);
lag = zeros(size(macs,1), size(rx_to_corr,2)*2-1);
for i = 1:size(macs,1)
    [corr(i,:), lag(i,:)] = xcorr(rx_to_corr, reference_signals(i,:));
end
corr = abs(corr);

[~,max_idx] = find(corr==max(corr(:)));

[~,I] = sort(corr(:,max_idx), 'descend');
i1 = I(1); i2 = I(2);
guesses = [macs(i1,:); macs(i2,:)];

fprintf(1, "==> Guessed MAC addresses: %s and %s\n", guesses(1,:), guesses(2,:));
fprintf(1, "==> Senders were: %s and %s\n", sender1, sender2);
fprintf(1, "==> Correct guesses: %d\n", helper_correct_guesses(guesses, [sender1; sender2]));