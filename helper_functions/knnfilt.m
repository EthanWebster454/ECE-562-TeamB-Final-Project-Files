function outParams=knnfilt(inParams,mixedAudio,instrOnly,vocalsOnly)
    
    % extract parameters from input struct
    lambda = inParams.lambda; % tuning parameter
    nFFT = inParams.nFFT;     % number of FFT points
    Fs= inParams.fs;          % sampling rate (Hz)
    p = inParams.p;           % number of nearest neighbors
    windowSize = inParams.windowsize; % size of FFT window
    outputname = inParams.outfilename;% file names to write to
    
    overlapSize = windowSize/4; % overlap for FFT
    
    R = (2/3) * stft(mixedAudio, nFFT ,windowSize, overlapSize);
    
    % find k nearest neighbors in spectrogram
    X = abs(R);
    
    [N,M] = size(X);
    D=zeros(N,N);
    Y=zeros(N,M);
    
    % Euclidean distance metric (Eq 1)
    for k = 1:N
        for l = 1:N
            D(k,l) = sum((X(k,:)-X(l,:)).^2);  
        end
    end
    
    % matrix D
    [~,si] = sort(D,1);
    
    % Yk = M(P) (Eq 2)
    for sortI = 1:N
        Y(sortI,:) = median(X(si(2:p,sortI),:),1);
    end
    
    % Y_{f,k} = min(X_{f,k}, Y_{f,k}) (Eq 3)
    for f = 1:N
        for k = 1:M
            if(Y(f,k)>X(f,k))
                Y(f,k)=X(f,k);
            end
        end
    end
    
    % Gaussian RBF kernel (Eq 4)
    W = exp(-((X-Y).^2)./(2*lambda^2));
    
    % background music spectrogram (Eq 5)
    B = W .* R;
    
    % vocal spectrogram (Eq 6)
    V = (1-W).*R;
    
    % Inverse Short-time Fast Fourier Transform
    musicEst = istft(B, nFFT, windowSize, overlapSize);%,'Window',hamming(windowSize),'OverlapLength',...
                   %overlapSize,'FFTLength',nFFT);
    vocalsEst = istft(V, nFFT, windowSize, overlapSize);
    
    % divide by max to normalize
    musicEst = musicEst/max(abs(musicEst));
    vocalsEst = vocalsEst/max(abs(vocalsEst));
    
    % original vocals-only and instrumentals-only tracks
    if length(vocalsOnly) == length(vocalsEst) == length(instrOnly)
        originalTracks = [instrOnly , vocalsOnly]';
    else
        minLength=min([length(vocalsOnly), length(vocalsEst), length(instrOnly)] );
        vocalsEst = vocalsEst(1:minLength);
        originalTracks = [instrOnly(1:minLength) , vocalsOnly(1:minLength)]';
    end

    % calculate performance metrics: SDR, SIR, and SAR
    [s_target,e_interf,e_noise] = bss_decomp_gain( vocalsEst, 2, originalTracks);
    [outParams.SDR,outParams.SIR,outParams.SAR] = bss_crit(s_target,e_interf,e_noise);
 
    % write tracks to file
    audiowrite(outputname+'_vocalsEst.flac',vocalsEst,Fs);
    audiowrite(outputname+'_musicEst.flac',musicEst,Fs);