function [thetaPosterior,Times,acprat] = ePDE_HMC(D,stepsize,nLeap)
% load data
load Data/ePDE
% hyperparameters
sigmay = 0.1; sigmatheta = 0.5;
NumOfIterations = 5000;
BurnIn = floor(0.2*NumOfIterations);
%BurnIn = 0;
%ColStart= floor(0.1*NumOfIterations);

%Trajectory =  2.4;
NumOfLeapFrogSteps = nLeap;
StepSize = stepsize;

Mass  = diag(ones(D,1)*1);
InvMass = sparse(inv(Mass));

% H_HMC = zeros((NumOfIterations-BurnIn)*NumOfLeapFrogSteps,1);
thetaSaved = zeros(NumOfIterations-BurnIn,D);



% Initialize
Startpoint = zeros(D,1);
CurrentTheta = Startpoint;
CurrentU = ePDE_U(y,CurrentTheta,PDE,sigmay,sigmatheta);
%Times = [0];

% Random numbers
% randn('state',2015);
% rand('twister',2015);

%% 
Proposed = 0;
Accepted = 0;
% %ARate = [];
% thetaSam = [CurrentTheta'];
% REM = [norm(CurrentTheta'-meanTrue)/norm(meanTrue)];
tic;


for IterationNum = 1:NumOfIterations
    if mod(IterationNum,100)==0
        disp([num2str(IterationNum) ' iterations completed.'])
        disp(Accepted/Proposed)
%         if IterationNum > BurnIn
%             ARate = [ARate Accepted/Proposed];
%         end
        Proposed = 0;
        Accepted = 0;
        drawnow;
    end
    
    ProposedMomentum = (randn(1,D)*chol(Mass))';
    CurrentMomentum = ProposedMomentum;
    
    Proposed = Proposed + 1;
    ProposedTheta = CurrentTheta;
    
    % Use random Leapfrog steps
    RandomLeapFrogSteps = randsample(NumOfLeapFrogSteps,1);
    % Perform leapfrog steps
    for StepNum = 1:RandomLeapFrogSteps
        % HMC
                ProposedMomentum = ProposedMomentum - StepSize/2 * ePDE_U(y,ProposedTheta,PDE,sigmay,sigmatheta,1);
                ProposedTheta = ProposedTheta + StepSize * (InvMass*ProposedMomentum);
                ProposedMomentum = ProposedMomentum - StepSize/2 * ePDE_U(y,ProposedTheta,PDE,sigmay,sigmatheta,1);
%         if IterationNum <= BurnIn
%             ProposedMomentum = ProposedMomentum - StepSize/2.*U(y,ProposedTheta,PDE,sigmay,sigmatheta,1);
%             ProposedTheta = ProposedTheta + StepSize.*((InvMass)*ProposedMomentum);
%             ProposedMomentum = ProposedMomentum - StepSize/2.*U(y,ProposedTheta,PDE,sigmay,sigmatheta,1);
%         else
%             
%             ProposedMomentum = ProposedMomentum - StepSize/2 * transpose(gradient(net,ProposedTheta'));
%             ProposedTheta = ProposedTheta + StepSize * (InvMass*ProposedMomentum);
%             ProposedMomentum = ProposedMomentum - StepSize/2 * transpose(gradient(net,ProposedTheta'));
%         end
            

%         ProposedMomentum = ProposedMomentum - StepSize/2 * transpose(gradient(net,ProposedTheta'));
%         ProposedTheta = ProposedTheta + StepSize * (InvMass*ProposedMomentum);
%         ProposedMomentum = ProposedMomentum - StepSize/2 * transpose(gradient(net,ProposedTheta'));

        

    end

    
    ProposedMomentum = - ProposedMomentum;
    % calculate potential
    ProposedU = ePDE_U(y,ProposedTheta,PDE,sigmay,sigmatheta);
    
    % calculate Hamiltonian function
    CurrentH = CurrentU + .5*CurrentMomentum'*(InvMass)*CurrentMomentum;
    ProposedH = ProposedU + .5*ProposedMomentum'*(InvMass)*ProposedMomentum;
    
    % calculate the ratio
    Ratio = -ProposedH + CurrentH;
    
    if isfinite(Ratio) && (Ratio > min([0,log(rand)]))
        CurrentTheta = ProposedTheta;
        CurrentU = ProposedU;
        Accepted = Accepted + 1;
    end

    
    % Save samples if required
    if IterationNum > BurnIn
        thetaSaved(IterationNum-BurnIn,:) = CurrentTheta;
%         thetaSam = [thetaSam; CurrentTheta'];
%         REM = [REM norm(mean(thetaSam,1)-meanTrue)/norm(meanTrue)];

    end
    
%     thetaSam = [thetaSam; CurrentTheta'];
%     REM = [REM norm(mean(thetaSam,1)-meanTrue)/norm(meanTrue)];
%     Times = [Times;toc];

    
    % Start timer after burn-in
    if IterationNum == BurnIn
        disp('Burn-in complete, now drawing samples.')
%         CurrentTheta = Startpoint;
%         CurrentU = ePDE_U(y,CurrentTheta,PDE,sigmay,sigmatheta);
%         thetaSam = [CurrentTheta'];
%         REM = [norm(CurrentTheta'-meanTrue)/norm(meanTrue)];

        tic;
    end
%             
end
Times = toc;

thetaPosterior = thetaSaved;
acprat = size(unique(thetaPosterior,'rows'),1)/(NumOfIterations-BurnIn);

CurTime = fix(clock);
save(['Results/Results_HMC_2dePDE_' num2str(nLeap) 'nLeap_' num2str(stepsize) 'stepsize_' num2str(CurTime) '.mat'], 'StepSize', 'NumOfLeapFrogSteps', 'acprat', 'thetaPosterior', 'Times')