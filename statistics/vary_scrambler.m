%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vary_scrambler.m
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
NUM_ADDRESSES_TO_USE = 5;

% number of experiments (choose sender randomly each time)
NUM_EXPERIMENTS = 10;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

timing = zeros(8, 127);
num_correct = zeros(8, 127);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

for order = 0:7
    order_time = tic;
    for scrambler = 1:127
        % Note: it is possible that both senders are the same MAC here
        senders = macs(ceil(rand(2,1).*size(macs,1)),:);
        probe = struct( ...
            'duration', 'FFFF', ...
            'scrambler', scrambler);
        tic;
        evalc('guesses = find_sender(probe, order, macs, senders);');
        timing(order+1,scrambler) = toc;
        num_correct(order+1, scrambler) = correct_guesses(guesses, senders);
    end
    fprintf(1, "INFO: done with MCS %d in %fs\n", order, toc(order_time));
end


figure(1);
plot(repmat(1:127, 8, 1)', num_correct');
title(sprintf("Correct guesses for different MCS and Scrambler\n(out of %d addresses, after %d experiments)", NUM_ADDRESSES_TO_USE, NUM_EXPERIMENTS));
xlabel("Scrambler Init");
saveas(gcf, sprintf('figures/vary_scrambler-num_correct-%d_addresses.fig', NUM_ADDRESSES_TO_USE));

figure(2);
plot(repmat(1:127, 8, 1)', timing');
title("Time spent on correlating all possible MACs for different MCS and Scrambler");
xlabel("MCS");
saveas(gcf, sprintf('figures/vary_scrambler-timing-%d_addresses.fig', NUM_ADDRESSES_TO_USE));


csvwrite(sprintf('results/vary_scrambler-num_correct-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
    num_correct);
csvwrite(sprintf('results/vary_scrambler-timing-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
    timing);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function n = correct_guesses(guesses, senders)
    n = max( ...
        strcmp(guesses(1,:), senders(1,:)) + strcmp(guesses(2,:), senders(2,:)), ...
        strcmp(guesses(2,:), senders(1,:)) + strcmp(guesses(1,:), senders(2,:)));
end
