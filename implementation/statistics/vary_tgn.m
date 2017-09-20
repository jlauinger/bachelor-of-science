%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vary_mcs.m
%
% Test recognition quality for different standard channel models
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
NUM_EXPERIMENTS = 1000;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

results = zeros(8, 3, 3);

file = fopen(filename_macs);
out = textscan(file, "%s");
macs = cell2mat(out{1});
macs = macs(:, [1:2 4:5 7:8 10:11 13:14 16:17]);
macs = macs(1:NUM_ADDRESSES_TO_USE, :);

models = ["Model-B"; "Model-D"; "Model-E"];

for rate = 0:7
    rate_time = tic;
    reference_signals = generate_signal_pool(macs, rate, 'ABCDEF012345', 1);
    for model = 1:3
        for ex = 1:NUM_EXPERIMENTS
            senders = helper_choose_senders(macs);
            % calculate
            guesses = find_sender_after_channel(reference_signals, macs, senders, rate, 15, models(model,:), 0);
            nc = helper_correct_guesses(guesses, senders);
            % now store the stuff :D
            results(rate+1, model, nc+1) = results(rate+1, model, nc+1) + 1;
        end
    end
    fprintf(1, "INFO: done with MCS %d in %fs\n", rate, toc(rate_time));
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for rate = 0:7
    % configure plot
    figure(rate+1);
    bar(reshape(results(rate+1,:,:), 3, 3), 'stacked');
    title(sprintf("MCS %d", rate));
    xlabel("TGn Channel Model");
    ylabel("# experiments");
    set(gca,'XTickLabel',{'Model-B', 'Model-D', 'Model-E'})
    legend("0 correct", "1 correct", "2 correct");
    
    % save figure
    saveas(gcf, ...
        sprintf('figures/vary_tgn-%s-num_correct-%d_addresses-%d_experiments-mcs_%d.fig', ...
        datetime('now','Format','yyyyMMdd-HHmm'), ...
        NUM_ADDRESSES_TO_USE, ...
        NUM_EXPERIMENTS, ...
        rate));
    
    % save data
    helper_csvwrite(sprintf('results/vary_tgn-%s-num_correct-%d_addresses-%d_experiments-mcs_%d.csv', ...
        datetime('now','Format','yyyyMMdd-HHmm'), ...
        NUM_ADDRESSES_TO_USE, ...
        NUM_EXPERIMENTS, ...
        rate), ...
        "0 correct,1 correct,2 correct", ...
        reshape(results(rate+1,:,:), 3, 3));
end