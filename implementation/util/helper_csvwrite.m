%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% helper_csvwrite.m
%
% Like csvwrite, but writes a header line to include column titles.
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function helper_csvwrite(filename, header, A)
    fid = fopen(filename, 'w');
    fprintf(fid, '%s\n', header);
    fclose(fid);
    dlmwrite(filename, A, '-append');
end
