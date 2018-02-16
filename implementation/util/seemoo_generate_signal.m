function SIGNAL = seemoo_generate_signal(SIGNAL, addr1, addr2, addr3, duration)

    % ieee_80211g_generate Generate an IEEE 802.11g compliant frame.
    % SIGNAL = ieee_80211g_generate (SIGNAL) generates an IEEE 802.11g
    % compliant frame according to the parameters in the SIGNAL structure and
    % stores the resulting waveform as samples in the SIGNAL structure.
    %
    % The following parameters are expected:
    % SIGNAL: a structure with fields
    %           - TYPE: frame type and subtype ('DATA')
    %           - PAYLOAD: custom payload data
    %           - RATE: Modulation rate (1-8)
    %           - SAMPLING_RATE: The targeted sampling rate of the signal
    %
    % The SIGNAL structure is amended by the following fields:
    %           - samples
    %           - encoded_bit_vector
    %           - symbols_tx_mat
    %           - trail_pad

    x8 = @(x) uint8(hex2dec(reshape(x,2,[])')');

    % Perform argument checks:
    if (strcmp(SIGNAL.TYPE, 'DATA') == 0)
        error('IEEE80211g_GENERATE:Argument', ...
              'The frame type %s is not supported!\n', SIGNAL.TYPE);
    end

    psdu = generate_data_mac_frame(duration, addr1, addr2, addr3, SIGNAL.PAYLOAD);
    SIGNAL.mac_data = psdu;

    ieeeenc = ieee_80211_encoder();
    ieeeenc.set_rate(SIGNAL.RATE);

    stf_phase_shift = 0;
    ltf_format = 'LTF';
    data_mapped_plus = [];
    dirty_constellation_symbols = [];
    cp_replacement = [];

    [time_domain_signal_struct, encoded_bit_vector, symbols_tx_mat] = ...
    ieeeenc.create_standard_frame(psdu, ...
                                  stf_phase_shift, ...
                                  ltf_format, ...
                                  data_mapped_plus, ...
                                  dirty_constellation_symbols, ...
                                  cp_replacement);
    SIGNAL.samples = time_domain_signal_struct.tx_signal(:);
    SIGNAL.encoded_bit_vector = encoded_bit_vector;
    SIGNAL.symbols_tx_mat = symbols_tx_mat;
    SIGNAL.trail_pad = 1e-6; % zero-padding at the end of transmission
end
