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

% MCS to use
RATE = 0;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = zeros(127, 3);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

for scrambler = 1:127
    scrambler_time = tic;
    for ex = 1:NUM_EXPERIMENTS
        % Note: it is possible that both senders are the same MAC here
        senders = macs(ceil(rand(2,1).*size(macs,1)),:);
        probe = struct( ...
            'duration', 'FFFF', ...
            'scrambler', scrambler);
        evalc('guesses = find_sender(probe, RATE, macs, senders);');
        nc = correct_guesses(guesses, senders);
        results(scrambler, nc+1) = results(scrambler, nc+1) + 1;
    end
    fprintf(1, "INFO: done with Scrambler init %d in %fs\n", scrambler, toc(scrambler_time));
end


figure(1);
bar(results, 'stacked');
xlabel("Scrambler init");
ylabel("# experiments");
legend("0 correct", "1 correct", "2 correct");
title(sprintf("Scrambler init at MCS %d\n(out of %d addresses, for %d experiments)", RATE, NUM_ADDRESSES_TO_USE, NUM_EXPERIMENTS));
saveas(gcf, sprintf('figures/vary_scrambler-mcs_%d-%d_addresses-%d_experiments.fig', RATE, NUM_ADDRESSES_TO_USE, NUM_EXPERIMENTS));

%csvwrite(sprintf('results/vary_scrambler-num_correct-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
%    num_correct);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function n = correct_guesses(guesses, senders)
    n = max( ...
        strcmp(guesses(1,:), senders(1,:)) + strcmp(guesses(2,:), senders(2,:)), ...
        strcmp(guesses(2,:), senders(1,:)) + strcmp(guesses(1,:), senders(2,:)));
end
