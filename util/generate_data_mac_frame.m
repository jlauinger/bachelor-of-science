%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% generate_mac_header.m
%  Create a MAC frame, return PSDU
%
% Required toolboxes:
%  - WLAN System Toolbox
%  - Communications System Toolbox
%
% Author: Johannes Lauinger <jlauinger@seemoo.de>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function psdu = generate_data_mac_frame(duration, addr1, addr2, addr3)

  x8 = @(x) uint8(hex2dec(reshape(x,2,[])')');

  % from ieee_80211g_generate
  clear mac_header llc_header mac_frame;
  %                                                   VER TYP SUBTYPE  % check bit order!!
  mac_header.frame_control_1 = x8('20');     % bi2de([0 0 1 0 0 0 0 0], 'left-msb'); % data frame
  mac_header.frame_control_2 = x8('00');     % bi2de([0 0 0 0 0 0 0 0], 'left-msb'); % ToDS,FromDS 0
  mac_header.duration = x8(duration);        % duration in us, not octets!
  mac_header.address_1 = x8(addr1);
  mac_header.address_2 = x8(addr2);
  mac_header.address_3 = x8(addr3);
  mac_header.sequence_control = x8('0000'); 
  % addr4, QoS and HT not present in this frame type

  llc_header.dsap = x8('aa');                % SNAP used
  llc_header.ssap = x8('aa');                % SNAP used
  llc_header.control_field = x8('03');       % U-format PDU (unnumbered format)
  llc_header.org_type = x8('000000');        % Use EtherType
  llc_header.type = x8('0800');              % IPv4

  mac_frame.mac_header = struct2array(mac_header);
  mac_frame.llc_header = struct2array(llc_header);
  mac_frame.data = x8('ff');                % just some data, does not matter
  mac_frame.fcs = x8(ieee_80211_fcs(struct2array(mac_frame)));

  psdu = reshape(logical(de2bi(struct2array(mac_frame),8,'left-msb')'),1,[]);
end
