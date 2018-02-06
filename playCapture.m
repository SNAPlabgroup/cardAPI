function data = playCapture(buffdata, card, Nreps, throwAway, attA,...
    attB, delayComp)
% USAGE:
%    data = playCapture(buffdata, card, Nreps, attA, attB, delayComp);
%
% INPUTS:
%    buffdata - Input data (channels(two) x samples)
%    card - AD card structure from initializeCard()
%    Nreps - Number of repetitions of the stimulus
%    throwAway - Number of beginning trials to throw away
%    [attA] - Analog attenuation to use on channel #1 (dB, default = 45)
%    [attB] - Analog attenuation to use on channel #2 (dB, default = attA)
%    [delayComp] - Whether to compensate for AD delay (default = 1)
%
% OUTPUTS:
%    data - Capured data (Nreps x samples) acquired synchronously with
%    input data being played out
%
% -------------------------
% Copyright Hari Bharadwaj. All rights reserved.
% hbharadwaj@purdue.edu
% -------------------------

if ~exist('attA', 'var')
    attA = 45;
end

if ~exist('attB', 'var')
    attB = attA;
end

if ~exist('delayComp', 'var')
    delayComp = 1;
end

pol = -1;  % Electric to acoustic polarity
if delayComp
    delay = card.ADdelay;
else
    delay = 0;
end

bufferSize = size(buffdata, 2);
data = zeros(Nreps, bufferSize);
resplength = bufferSize + delay;

if(resplength > 4e6)
    error('Sound too large for buffer size!');
elseif(resplength > 1e6)
    warning('Sound too large. Buffer may overflow!');
end

invoke(card.RZ, 'SetTagVal', 'attA', attA);
invoke(card.RZ, 'SetTagVal', 'attB', attB);

playrecTrigger = 1;

% Check for clipping and load to buffer
if(any(abs(buffdata(1, :)) > 1) || any(abs(buffdata(1, :)) > 1))
    error('What did you do!? Sound is clipping!! Cannot Continue!!\n');
end


invoke(card.RZ, 'SetTagVal', 'nsamps', resplength);


invoke(card.RZ, 'WriteTagVEX', 'datainL', 0, 'F32', pol*buffdata(1, :));
invoke(card.RZ, 'WriteTagVEX', 'datainR', 0, 'F32', pol*buffdata(2, :));

pause(1.0);
pausedur = resplength/(8.0 * card.Fs); % 1/8th of stim duration
for k = 1:(Nreps + throwAway)
    invoke(card.RZ, 'SoftTrg', playrecTrigger);
    currindex = invoke(card.RZ, 'GetTagVal', 'indexin');
    while(currindex < resplength)
        currindex=invoke(card.RZ, 'GetTagVal', 'indexin');
    end
    
    temp = invoke(card.RZ, 'ReadTagVex', 'dataout', 0, resplength,...
        'F32','F64',1);
    if (k > throwAway)
        data((k-throwAway), :) = temp((delay + 1):end);
    end
    % Get ready for next trial
    invoke(card.RZ, 'SoftTrg', 8); % Stop and clear "OAE" buffer
    pause(pausedur);
end