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
NUM_ADDRESSES_TO_USE    = 64;          % limit simulation time

RATE                    = 0;           % MCS
MAX_TX_LEN              = 2^15;        % 2^20 =  1048576 --> Soft max TX / RX length for WARP v3 Java Transport (WARPLab 7.5.x)

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

destination             = macs(1,:);
sender1                 = macs(2,:);
sender2                 = macs(3,:);

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
[RFA,RFB] = wl_getInterfaceIDs(nodes(1));

% Set up the interface for the experiment
wl_interfaceCmd(nodes, 'RF_ALL', 'tx_gains', 3, 30);
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

tx1_struct = generate_signal(SIGNAL, destination, sender1, 'EFEFEFEFEF44', 'FF', 1);
tx1_signal = tx1_struct.samples;
tx2_struct = generate_signal(SIGNAL, destination, sender2, 'EFEFEFEFEF44', 'FF', 1);
tx2_signal = tx2_struct.samples;

% Scale the Tx vector to +/- 1
tx1_vec_air = tx1_signal ./ max(abs(tx1_signal));
tx2_vec_air = tx2_signal ./ max(abs(tx2_signal));

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
%pause(1.2 * txLength * Ts);

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
% try to correlate and guess MACs

reference_signals = generate_signal_pool(macs, RATE, 'ABCDEF012345', 1);

indices = helper_mac_sample_indices(RATE);
rx_to_corr = rx_vec_air(indices);

% correlate samples to find the addresses
acor = zeros(size(macs,1), 2*length(rx_to_corr)-1);
lag = zeros(size(macs,1), 2*length(rx_to_corr)-1);
for i = 1:size(macs,1)
    [acor(i,:), lag(i,:)] = xcorr(rx_to_corr, reference_signals(i,:));
end
acor = abs(acor);

% find sample index (x-axis) with the spikes - can be a bit off due to
% channel effects
[~,max_idx] = find(acor==max(acor(:)));

[~,I] = sort(acor(:,max_idx), 'descend');
i1 = I(1); i2 = I(2);

fprintf(1, "==> Guessed MAC addresses: %s and %s\n", macs(i1,:), macs(i2,:));

guesses = [macs(i1,:); macs(i2,:)];
