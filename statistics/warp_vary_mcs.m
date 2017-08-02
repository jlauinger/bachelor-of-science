%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% warp_vary_mcs.m
%
% Test recognition quality for different modulation orders on WARP SDRs
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

% number of experiments (choose sender randomly each time)
NUM_EXPERIMENTS = 10;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = zeros(6, 3);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

for rate = 0:5
    rate_time = tic;
    reference_signals = generate_signal_pool(macs, rate, macs(1,:), 1, 20e6);
    for ex = 1:NUM_EXPERIMENTS
        senders = helper_choose_senders(macs);
        % calculate
        guesses = warp_find_sender(reference_signals, macs, senders, rate);
        nc = helper_correct_guesses(guesses, senders);
        % now store the stuff :D
        results(rate+1, nc+1) = results(rate+1, nc+1) + 1;
    end
    fprintf(1, "INFO: done with MCS %d in %fs\n", rate, toc(rate_time));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% configure plot
figure(1);
bar(results, 'stacked');
title(sprintf("Correct guesses for varying MCS", rate));
xlabel("MCS");
ylabel("# experiments");
legend("0 correct", "1 correct", "2 correct", 'location', 'northwest');

% save figure
saveas(gcf, ...
    sprintf('figures/vary_mcs-%s-num_correct-%d_addresses-%d_experiments.fig', ...
    datetime('now','Format','yyyyMMdd-HHmm'), ...
    NUM_ADDRESSES_TO_USE, ...
    NUM_EXPERIMENTS));

% save data
helper_csvwrite(sprintf('results/vary_mcs-%s-num_correct-%d_addresses-%d_experiments.csv', ...
    datetime('now','Format','yyyyMMdd-HHmm'), ...
    NUM_ADDRESSES_TO_USE, ...
    NUM_EXPERIMENTS), ...
    "0 correct,1 correct,2 correct", ...
    results);