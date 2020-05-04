function [lowRankMat, sparseMat] = RPCA(mixedSignal,  tolerance, lambda)

% set tracker variables/inter-params
decisionMaker = 10;
Rho = 3/2;


% pre-allocate output matrices for efficiency
[freqBins, timeFrames] = size(mixedSignal);
lowRankMat = zeros( freqBins, timeFrames);
sparseMat = zeros( freqBins, timeFrames);

% calculate 4 norms, mu, and muLimit
frobNorm = norm(mixedSignal, 'fro');
infinityNorm = norm( reshape(mixedSignal,[1,freqBins*timeFrames]),...
                    inf) / lambda;
twoNorm = lansvd(mixedSignal, 1, 'L');
dualNorm = max(twoNorm, infinityNorm);
mixedSigCpy = mixedSignal / dualNorm;
Mu = 5/4/twoNorm;
muInv=1/Mu;
muLimit = 1e10*Mu; % cap mu parameter so it does not increase without bound
lDivMu = lambda/Mu;


% finite iterations or convergence according to loss estimate
for iter=1:1e4


    % update sparse matrix estimation
    estSP =  mixedSignal - lowRankMat + muInv * mixedSigCpy;
    sparseMat = max(estSP - lDivMu, 0);
    sparseMat = sparseMat+min(estSP + lDivMu, 0);

    % decide which version of SVD to use based on decison factor
    if (choosvd(timeFrames, decisionMaker) == 1)
        [U, sigma, V]=lansvd(muInv * mixedSigCpy + mixedSignal - sparseMat, decisionMaker, 'L');
    else
        [U, sigma, V]=svd(muInv * mixedSigCpy + mixedSignal - sparseMat, 'econ');
    end

    % singular values are on the diagonal
    diagofS = diag(sigma);
    numCSV = length(find(diagofS > muInv)); % find singV > 1/Mu
    singVRange=1:numCSV;

    % calculate current trial of the low rank estimation
    lowRankMat = U(:, singVRange) * diag(diagofS(singVRange) - muInv) * V(:, singVRange)';    

    % update objective and current working copy of mixed signal
    Obj = mixedSignal - lowRankMat - sparseMat;
    mixedSigCpy = Mu * Obj + mixedSigCpy;

    % update decision factor for next iteration
    if(decisionMaker <= numCSV)
        decisionMaker=min(timeFrames,round(0.05*timeFrames)+numCSV);
    else
        decisionMaker=min(timeFrames, numCSV+1);
    end

    Mu = min(muLimit, Mu * Rho);
    muInv=1/Mu;
    lDivMu = lambda/Mu;
    
    % loss estimate for termination condition
    if((norm(Obj, 'fro') / frobNorm) < tolerance)
        break;
    end    

end
