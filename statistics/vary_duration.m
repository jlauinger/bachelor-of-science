%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vary_duration.m
%
% Test recognition quality for different values of duration
%
% Required toolboxes:
%  - Communications System Toolbox
%  - WLAN System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Dataset to use
filename_macs = "data/mac-addresses-eduroam-20170516.dat";

% limit MAC addresses to check against to be faster
NUM_ADDRESSES_TO_USE = 64;

% number of experiments per MCS and scrambler
NUM_EXPERIMENTS = 1;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = zeros(8, 128, 3);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

for order = 0:7
    order_time = tic;
    for duration = 0:127 % only last 7 bits are important
        probe = struct( ...
            'duration', sprintf('%04X', duration), ...
            'scrambler', 1);
        probe_signals = generate_signal_pool(probe, order, macs);
        for ex = 1:NUM_EXPERIMENTS
            % Note: it is possible that both senders are the same MAC here
            senders = macs(ceil(rand(2,1).*size(macs,1)),:);
            % calculate
            guesses = find_sender(probe, order, macs, senders);
            nc = correct_guesses(guesses, senders);
            % now store the stuff :D
            results(order+1, duration+1, nc+1) = results(order+1, duration+1, nc+1) + 1;
        end
    end
    fprintf(1, "INFO: done with MCS %d in %fs\n", order, toc(order_time));
end

figure(1);
for order = 0:7
    subplot(3, 3, order+1);
    bar(reshape(results(order+1,:,:), 128, 3), 'stacked');
    title(sprintf("MCS %d", order));
    xlabel("duration field");
    ylabel("# experiments");
end
subplot(3,3,1);
legend("0 correct", "1 correct", "2 correct");


%csvwrite(sprintf('results/vary_scrambler-num_correct-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
%    num_correct);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function n = correct_guesses(guesses, senders)
    n = max( ...
        strcmp(guesses(1,:), senders(1,:)) + strcmp(guesses(2,:), senders(2,:)), ...
        strcmp(guesses(2,:), senders(1,:)) + strcmp(guesses(1,:), senders(2,:)));
end
