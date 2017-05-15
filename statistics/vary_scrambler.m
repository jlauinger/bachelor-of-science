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


for s = 1:127
    probe = struct(...
        'duration', 'FFFF', ...
        'scrambler', s);

    T = evalc('find_sender(probe, 0);');
    lines = splitlines(T);
    disp([num2str(s) ':  ' char(lines(end-1))]);
end