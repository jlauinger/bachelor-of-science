%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% vary_mcs.m
%
% Test recognition quality for different modulation orders
%
% Required toolboxes:
%  - Communications System Toolbox
%  - WLAN System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for order = 0:7
    probe = struct(...
        'duration', 'FFFF', ...
        'scrambler', 1);

    T = evalc('different_mod_orders(probe, order);');
    lines = splitlines(T);
    disp([num2str(order) ':  ' char(lines(end-1))]);
end