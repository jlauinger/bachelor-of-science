%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vary_mcs.m
%
% Test recognition quality for varying channel losses
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

timing = zeros(NUM_EXPERIMENTS, 8);
num_correct = zeros(NUM_EXPERIMENTS, 8);

probe = struct( ...
    'duration', 'FFFF', ...
    'scrambler', 1);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

for ex = 1:NUM_EXPERIMENTS
    ex_time = tic;
    for order = 0:7
        % Note: it is possible that both senders are the same MAC here
        senders = macs(ceil(rand(2,1).*size(macs,1)),:);
        tic;
        evalc('guesses = find_sender(probe, order, macs, senders);');
        timing(ex,order+1) = toc;
        num_correct(ex,order+1) = correct_guesses(guesses, senders);
    end
    fprintf(1, "INFO: done with experiment %d in %fs\n", ex, toc(ex_time));
end


figure(1);
bar(repmat(0:7, 3, 1)', ...
    [sum(num_correct(:,:)==0); sum(num_correct(:,:)==1); sum(num_correct(:,:)==2)]');
title(sprintf("Correct guesses for different MCS\n(out of %d addresses, after %d experiments)", NUM_ADDRESSES_TO_USE, NUM_EXPERIMENTS));
xlabel("MCS");
lim = ylim();
%ylim([-0.3 lim(2)+0.3]);
legend(['0 correct'; '1 correct'; '2 correct']);
saveas(gcf, sprintf('figures/vary_mcs-num_correct-%d_addresses.fig', NUM_ADDRESSES_TO_USE));

figure(2);
plot(repmat(0:7, NUM_EXPERIMENTS, 1)', timing');
title("Time spent on correlating all possible MACs for different MCS");
xlabel("MCS");
saveas(gcf, sprintf('figures/vary_mcs-timing-%d_addresses.fig', NUM_ADDRESSES_TO_USE));


csvwrite(sprintf('results/vary_mcs-num_correct-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
    num_correct);
csvwrite(sprintf('results/vary_mcs-timing-%d_addresses.csv', NUM_ADDRESSES_TO_USE), ...
    timing);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function n = correct_guesses(guesses, senders)
    n = max( ...
        strcmp(guesses(1,:), senders(1,:)) + strcmp(guesses(2,:), senders(2,:)), ...
        strcmp(guesses(2,:), senders(1,:)) + strcmp(guesses(1,:), senders(2,:)));
end
