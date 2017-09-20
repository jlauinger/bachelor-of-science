%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper_choose_senders.m
%
% Choose two different MAC addresses out of a pool, by random.
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function senders = helper_choose_senders(macs)
    indices = ceil(rand(2,1).*size(macs,1));
    while(indices(1) == indices(2))
        indices = ceil(rand(2,1).*size(macs,1));
    end
    senders = macs(indices,:);
end
