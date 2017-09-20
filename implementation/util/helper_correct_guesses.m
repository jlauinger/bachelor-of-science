%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper_correct_guesses.m
%
% Count how many MAC addresses were guessed right.
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function n = helper_correct_guesses(guesses, senders)
    n = max( ...
        strcmp(guesses(1,:), senders(1,:)) + strcmp(guesses(2,:), senders(2,:)), ...
        strcmp(guesses(2,:), senders(1,:)) + strcmp(guesses(1,:), senders(2,:)));
end
