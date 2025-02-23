function [I, t] = miMimoTrue(Hmat, typeModulation, typeSampling, nIterSignal, nIterNoise)
%
% MIMIMOTRUE Computes the mutual info of a MIMO channel with complex noise 
% finite-alphabet inputs, based on the computation from:
%  C. Xiao, Y. R. Zheng, and Z. Ding, "Globally optimal linear precoders
%  for finite alphabet signals over complex vector Gaussian channels," IEEE
%  Trans. Signal Process., vol. 59, no. 7, pp. 3301�3314, 2011.
%
%     Inputs:     mat Hmat = MIMO channel matrix
%                 str typeModulation = type of signal constellation
%                 str typeSampling = type of averaging over the signals: EXHAUSTIVE/RANDOMIZED
%                 scalar nIterSignal = number of iters for avg over signals
%                 scalar nIterNoise = number of iters for avg over noise
%     Outputs:    scalar I = mutual info between input and output
%                 scalar t = computation time
%
% Max Girnyk
% Stockholm, 2014-10-01
%
% =========================================================================
%
% This Matlab script produces results used in the following paper:
%
% M. A. Girnyk, "Deep-learning based linear precoding for MIMO channels 
% with finite-alphabet signaling," Physical Communication 48(2021) 101402
%
% Paper URL:          https://arxiv.org/abs/2111.03504
%
% Version:            1.0 (modified 2021-11-14)
%
% License:            This code is licensed under the Apache-2.0 license.
%                     If you use this code in any way for research that
%                     results in a publication, please cite the above paper
%
% =========================================================================

% Determine the sizes of the channel matrix
[N, M] = size(Hmat);

% Form the signal constellation
Sset  = modulationFiniteAlphabet(typeModulation);   % signal constellation
lSset = length(Sset);                               % size of the constellation

% Determine the size of the search
switch(typeSampling)
  case 'EXHAUSTIVE'
    % True averaging over all possible signal constellation points
    nSymbolVecs = lSset^M;
  case 'RANDOMIZED'
    % Averaging by random sampling of constellation points
    nSymbolVecs = nIterSignal;
end

timeBegin = cputime; % start clock

% Average over noise and signal and compute MI
% Loop over true signal (x0, giving y = H x0 + n) -------------------------
sumOverTrueSignal = 0;
for iTrueSymbolVec = 1:nSymbolVecs
  
  % Sample modulated symbols for averaging over signal vector
  switch(typeSampling)
    case 'EXHAUSTIVE'
      % Create a combination of symbols over antennas
      modIndex = convertDecToBin(iTrueSymbolVec-1, M, lSset).'; % on-the-fly loop over all combs of symbol vecs
    case 'RANDOMIZED'
      % Pick symbols randomly
      modIndex = randi([1, lSset], M, 1) - 1;        % random selection of symbol vecs
  end
  x0 = Sset(modIndex+1).'; % pick constellation point
  
  % Loop over noise (n) ---------------------------------------------------
  sumOverNoise = 0;
  for iIterNoise = 1:nIterNoise
    n = sqrt(1/2) * (randn(N,1) + 1j*randn(N,1));   % complex noise
    
    % Loop over signal (x) ------------------------------------------------
    sumOverSignal = 0;
    for iSymbolVec = 1:nSymbolVecs
      % Sample modulated symbols for averaging over signal vector
      switch(typeSampling)
        case 'EXHAUSTIVE'
          % Create a combination of symbols over antennas
          modIndex = convertDecToBin(iSymbolVec-1, M, lSset).';
        case 'RANDOMIZED'
          % Pick symbols randomly
          modIndex = randi([1, lSset], M, nIterSignal) - 1;
      end
      
      x = Sset(modIndex+1).'; % pick constellation point
      sumOverSignal = sumOverSignal + 1/pi^N*exp(-norm(Hmat*(x0-x)+n)^2)/nSymbolVecs;
    end % iSymbolVec = 1:nSymbolVecs
    
    sumOverNoise = sumOverNoise + log(sumOverSignal)/nIterNoise;
  end % iIterNoise = 1:nIterNoise
  
  sumOverTrueSignal = sumOverTrueSignal - sumOverNoise/nSymbolVecs;
end % iTrueSymbolVec = 1:nSymbolVecs

% Entropy of y for given x
entropyNoise = sumOverTrueSignal;

% Compute the normalized MI [bpcu/dim]
I = real(entropyNoise - N*(log(pi) + 1)) / M / log(2);   % -E_y ln E_x p(y|Hx) - E_y,x ln p(y|Hx)

timeEnd = cputime; % stop clock

% Comnpute time elapsed
t = (timeEnd - timeBegin)/60;

end