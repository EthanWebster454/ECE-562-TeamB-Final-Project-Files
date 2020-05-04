function outParams=rpca_ss(inputParams,mixedAudio,instrOnlyTrack,vocalsOnlyTrack)

    % parameters
    outputname = inputParams.outfilename;
    nFFT = inputParams.nFFT;
    windowSize = inputParams.windowSize;
    Fs = inputParams.fs;
    lambda = inputParams.lambda;
    overlapAmt = windowSize/4;
    tolerance = inputParams.tolerance;

    % spectrogram
    R = (2/3) * stft(mixedAudio,nFFT,windowSize,overlapAmt)';
    phase = angle(R);

    % run RPCA method               
    [audioMagSpect, vocalMagSpect] = RPCA(abs(R), tolerance, lambda/sqrt(max(size(R))));
    
    % restore phase information to estimated magnitude spectrograms
    instEstSpect = audioMagSpect.*exp(1i.*phase);
    vocalEstSpect = vocalMagSpect.*exp(1i.*phase);

    % resynthesize the estimated signal components using IFFT
    vocalsEst = istft(vocalEstSpect', nFFT ,windowSize, overlapAmt);   
    musicEst = istft(instEstSpect', nFFT ,windowSize, overlapAmt);
    
    % divide by max to normalize
    musicEst = musicEst/max(abs(musicEst));
    vocalsEst = vocalsEst/max(abs(vocalsEst));
    
    % original vocals-only and instrumentals-only tracks
    if length(vocalsOnlyTrack) == length(vocalsEst) == length(instrOnlyTrack)
        originalTracks = [instrOnlyTrack , vocalsOnlyTrack]';
    else
        minLength=min([length(vocalsOnlyTrack), length(vocalsEst), length(instrOnlyTrack)] );
        vocalsEst = vocalsEst(1:minLength);
        originalTracks = [instrOnlyTrack(1:minLength) , vocalsOnlyTrack(1:minLength)]';
    end

    % calculate performance metrics: SDR, SIR, and SAR
    [s_target,e_interf,e_noise] = bss_decomp_gain( vocalsEst, 2, originalTracks);
    [outParams.SDR,outParams.SIR,outParams.SAR] = bss_crit(s_target,e_interf,e_noise);
  
    % save estimated split tracks back to disk
    audiowrite(outputname+'_vocalsEst.flac',vocalsEst,Fs);
    audiowrite(outputname+'_musicEst.flac',musicEst,Fs);
