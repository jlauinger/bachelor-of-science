function SIGNAL = generate_signal(SIGNAL, addr1, addr2, addr3, duration, scrambler)

    % The following parameters are expected:
    % SIGNAL: a structure with fields
    %           - PAYLOAD: custom payload data
    %           - RATE: Modulation rate (1-8)
    %
    % The SIGNAL structure is amended by the following fields:
    %           - samples
    %           - fs: The targeted sampling rate of the signal
    %           - ind: field indices

    % generate payload
    tx_psdu = generate_data_mac_frame(duration, addr1, addr2, addr3, SIGNAL.PAYLOAD);
    tx_psdu = int8(tx_psdu');

    % configure 802.11g
    cfg = wlanNonHTConfig;
    cfg.MCS = SIGNAL.RATE;
    cfg.PSDULength = length(tx_psdu/8);

    % get sampling rate
    SIGNAL.fs = helperSampleRate(cfg);
    
    % modulate packet
    SIGNAL.samples = wlanWaveformGenerator(tx_psdu, cfg, 'ScramblerInitialization', scrambler);
    
    % calculate field indices (in samples)
    SIGNAL.ind = wlanFieldIndices(cfg);

end