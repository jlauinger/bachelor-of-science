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

% MCS for this experiment
rate = 1;

for d = 0:128  % only last 7 bits matter
    probe = struct(...
        'duration', sprintf('%04X', d), ...
        'scrambler', 1);

    T = evalc('find_sender(probe, rate);');
    lines = splitlines(T);
    disp([sprintf('%04X', d) ':  ' char(lines(end-1))]);
end