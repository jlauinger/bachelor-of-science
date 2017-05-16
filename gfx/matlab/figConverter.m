%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figConverter.m
% Convert all fig-Files in fig/ to tikz and store results in tikz/
%
% Required toolboxes: none
%
% Dependencies:
%  - https://github.com/matlab2tikz/matlab2tikz
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

addpath matlab2tikz

% get available figure files
files = dir('fig/*.fig');

for ind = 1:length(files)
    % trim filename
    filename = files(ind).name(1:end-4);

    % load figure
    openfig(sprintf('fig/%s.fig', filename));

    % export tikz
    matlab2tikz(sprintf('tikz/%s.tikz', filename), ...
        'width', '\figurewidth', ...
        'height', '\figureheight', ...
        'extraAxisOptions', 'clip mode=individual,transpose legend,legend columns=2,legend style={at={(0,1)},anchor=north west,draw=black,fill=white,legend cell align=left}', ...
        'extraTikzpictureOptions', 'font=\footnotesize', ...
        'checkForUpdates', false);
    
    % close figure
    close
end