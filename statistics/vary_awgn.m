%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vary_mcs.m
%
% Test recognition quality for decreasing AWGN SNR
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

% choose a MCS
RATE = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = zeros(8, 26);

probe = struct( ...
    'duration', 'FFFF', ...
    'scrambler', 1);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

for order = 0:7
    mcs_time = tic;
    for snr = 50:-2:0
        % Note: it is possible that both senders are the same MAC here
        senders = macs(ceil(rand(2,1).*size(macs,1)),:);
        channel = struct(...
            'snr', snr, ...
            'use_tgg', 0);
        evalc('guesses = find_sender_after_channel(probe, order, macs, senders, channel);');
        nc = correct_guesses(guesses, senders);
        if (nc == 2)
            results(order+1, 26-snr/2) = results(order+1, 26-snr/2) + 1;
        end
    end
    fprintf(1, "INFO: done with MCS %d in %fs\n", ex, toc(mcs_time));
end

figure(1);
plot(results);
title(sprintf("Correct guesses for varying AWGN at Rate %d\n(out of %d addresses, after %d experiments)", RATE, NUM_ADDRESSES_TO_USE, NUM_EXPERIMENTS));
xlabel("SNR (dB)");
legend(['MCS 0'; 'MCS 1'; 'MCS 2'; 'MCS 3'; 'MCS 4'; 'MCS 5'; 'MCS 6'; 'MCS 7']);
saveas(gcf, sprintf('figures/vary_awgn-rate_%d-%d_addresses-%d_experiments.fig', RATE, NUM_ADDRESSES_TO_USE, NUM_EXPERIMENTS));

%csvwrite(sprintf('results/vary_mcs-num_correct-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
%    num_correct);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function n = correct_guesses(guesses, senders)
    n = max( ...
        strcmp(guesses(1,:), senders(1,:)) + strcmp(guesses(2,:), senders(2,:)), ...
        strcmp(guesses(2,:), senders(1,:)) + strcmp(guesses(1,:), senders(2,:)));
end
