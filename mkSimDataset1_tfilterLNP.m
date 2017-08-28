% script_makeSimulatedDataset_tfilter.m
%
% Generates a simulated dataset with a response of a simulated LNP neuron
% to a 1D (temporal) stimulus. LNP neuron generated has a set of three
% temporal filters, each of length 30 time bins. 
%
% Dataset created is required for tutorial script tutorial1_MID_tfilter.m 


% Initialize paths (and create 'simdata' folder if necessary)
initpaths;


%% 1. Make filters for LNP neuron

nkt = 30;  % number of time bins in filter

dtSim = .01; % bin size for representing time (here .01s => 100 Hz stimulus frame rate)
RefreshRate = 1/dtSim; % Refresh rate
tk = (-nkt+1:0)'; % vector of time indices (in units of stim frames)

% Make some stimulus filters for simulated neuron
filt1 = exp(-((tk+nkt/5)/(nkt/12)).^2)-.25*exp(-((tk+nkt/2)/(nkt/5)).^2); % biphasic filter
filt1 = filt1./norm(filt1);  %normalize to make a unit vector

filt2 = [filt1(2:end); 0];  % make 2nd filter (shift filter 1 by 2)
filt2 = filt2-filt1*(filt1'*filt2); % orthogonalize w.r.t. filter 1
filt2 = filt2./norm(filt2); 

filt3 = [filt2(2:end); 0];  % make 3rd filter (shift filter 2 by 1)
filt3 = filt3-[filt1 filt2]*([filt1 filt2]'*filt3); % orthogonalize w.r.t. filter 1 & 2
filt3 = filt3./norm(filt3); % normalize to make a unit vector

filts_true = [filt1 filt2 filt3];

% Plot these filters
plot(tk*dtSim, filts_true, 'o-');
title('filters for simulation');
xlabel('time before spike (s)'); ylabel('filter coefficient');
axis tight;


%% 2.  Simulate spike responses from LNP neuron

% Create stimulus 
slen = 20000;   % Stimulus length (make longer to see better recovery of true filters)
Stim = randn(slen,1); % 1D Gaussian white noise (temporal) stimulus
%Stim = conv2(Stim,normpdf(-3:3,0,1)','same'); % smooth stimulus


% Convolve stimulus with filters
f1 = sameconv(Stim,filt1);
f2 = sameconv(Stim,filt2);
f3 = sameconv(Stim,filt3);

% Compute output of nonlinearity
softrect = @(x)(log(1+exp(x))); % soft-rectification function
fnlin = @(x1,x2,x3)(softrect(40*x1 + 12*x2.^2 + 10*(x3).^2));
lam = fnlin(f1,f2,f3);

%  Simulate spike train
dtSim = 100; % in Hz
spikes = poissrnd(lam/RefreshRate); % generate spikes

% Report number of spikes and spike rate
nsp = sum(spikes); % number of spikes
fprintf('LNP simulation: %d time bins, %d spikes  (%.2f sp/s)\n', slen,nsp, nsp/slen*dtSim);


%% 3. Save the dataset

simdata1.Stim = Stim;
simdata1.spikes = spikes;
simdata1.filts_true = filts_true;
simdata1.label = 'simulated dataset of 3-filter LNP neuron to temporal white noise';

save('simdata/simdata1.mat', 'simdata1');