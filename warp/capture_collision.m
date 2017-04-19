%
% important resource:
% https://warpproject.org/trac/browser/ResearchApps/PHY/WARPLAB/WARPLab7/M_Code_Examples/wl_example_siso_ofdm_txrx.m
%
% very good explanation on how to send using WARPs

% Plan:
% - modulate 2 packets with different MAC
% - send them using RFA and RFB of node 0
% - receive with RFD of node 0
% - save IQ samples for correlation