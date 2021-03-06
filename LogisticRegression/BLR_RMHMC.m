function [betaPosterior,Times,acprat] = BLR_RMHMC(stepsize,nLeap,data)
% load data
load (['Data/' data]);

NumOfIterations = 5000;
BurnIn = floor(0.2*NumOfIterations);

NumOfLeapFrogSteps = nLeap;

NumOfNewtonSteps = 5;
alpha = 100;
StepSize = stepsize;
D = size(X,2);


betaSaved = zeros(NumOfIterations-BurnIn,D);

Startpoint = zeros(D,1);
CurrentBeta = Startpoint;
CurrentU = U(y,X,CurrentBeta,alpha);
% Pre-allocate memory for partial derivatives
for d = 1:D
    GDeriv{d} = zeros(D);
end

Proposed = 0;
Accepted = 0;

for IterationNum = 1:NumOfIterations
    if mod(IterationNum,100) == 0
        disp([num2str(IterationNum) ' iterations completed.'])
        disp(Accepted/Proposed)

        Proposed = 0;
        Accepted = 0;
        drawnow
            
    end
    
    ProposedBeta = CurrentBeta;
    
    % pre-leapfrog calculation
    % Calculate G
    G     = BLR_Met(X,ProposedBeta,alpha);
    CholG = chol(G);
    InvG  = inv(G);
    % Calculate the partial derivatives dG/dw
    GDeriv = BLR_Met(X,ProposedBeta,alpha,1);
    for d = 1:D
        InvGdG{d}      = InvG*GDeriv{d};
        TraceInvGdG(d) = trace(InvGdG{d});
    end
    % terms other than quadratic one
    dphi = U(y,X,ProposedBeta,alpha,1) + 0.5*TraceInvGdG';
    
    % propose momentum
    CurrentMomentum = (randn(1,D)*CholG)';
    ProposedMomentum = CurrentMomentum;
    
    % Calculate current H value
    CurrentLogDet = sum(log(diag(CholG)));
    CurrentH  = CurrentU + CurrentLogDet + (CurrentMomentum'*InvG*CurrentMomentum)/2;
 
    Proposed = Proposed + 1;
    
    % Perform leapfrog steps
    for StepNum = 1:NumOfLeapFrogSteps
        %%%%%%%%%%%%%%%%%%%
        % Update momentum %
        %%%%%%%%%%%%%%%%%%%
        % Multiple fixed point iteration
        PM = ProposedMomentum;
        for FixedIter = 1:NumOfNewtonSteps
            %MomentumHist(FixedIter,:) = PM;
            
            InvGMomentum = InvG*PM;
            for d = 1:D
                dQuadTerm(d)  = 0.5*(PM'*InvGdG{d}*InvGMomentum);
            end
            
            PM = ProposedMomentum + (StepSize/2)*(-dphi + dQuadTerm');
        end
        ProposedMomentum = PM;
        
        %%%%%%%%%%%%%%%%%%%%%%%
        % Update w parameters %
        %%%%%%%%%%%%%%%%%%%%%%%
        %%% Multiple Fixed Point Iteration %%%
        FixedInvGMomentum  = G\ProposedMomentum;
        
        PB = ProposedBeta;
        for FixedIter = 1:NumOfNewtonSteps
            %wHist(FixedIter,:) = PB;
            
            InvGMomentum = BLR_Met(X,PB,alpha)\ProposedMomentum;
            PB = ProposedBeta + (StepSize/2)*(FixedInvGMomentum + InvGMomentum);
        end
        ProposedBeta = PB;
        
        % Update G based on new parameters
        G = BLR_Met(X,ProposedBeta,alpha);
        InvG = inv(G);
        % Update the partial derivatives dG/dw
        GDeriv = BLR_Met(X,ProposedBeta,alpha,1);
        for d = 1:D
            InvGdG{d}      = InvG*GDeriv{d};
            TraceInvGdG(d) = trace(InvGdG{d});
        end
        % terms other than quadratic one
        dphi = U(y,X,ProposedBeta,alpha,1) + 0.5*TraceInvGdG';
        %%%%%%%%%%%%%%%%%%%
        % Update momentum %
        %%%%%%%%%%%%%%%%%%%
        InvGMomentum = InvG*ProposedMomentum;
        for d = 1:D
            dQuadTerm(d) = 0.5*(ProposedMomentum'*InvGdG{d}*InvGMomentum);
        end
        ProposedMomentum = ProposedMomentum + (StepSize/2)*(-dphi + dQuadTerm');
    end
       
        
    ProposedMomentum = -ProposedMomentum;
        
    % Calculate Potential
    ProposedU = U(y,X,ProposedBeta,alpha);
        
    % Calculate H value
    ProposedLogDet = sum(log(diag(chol(G))));
    ProposedH = ProposedU + ProposedLogDet + (ProposedMomentum'*InvG*ProposedMomentum)/2; 
    % Accept according to ratio
    Ratio = -ProposedH + CurrentH;
               
    if (isfinite(Ratio) && (Ratio > min([0,log(rand)])))
        CurrentBeta = ProposedBeta;
        CurrentU = ProposedU;
        Accepted = Accepted + 1;
        
    end

        
    % Save samples if required
    if IterationNum > BurnIn
        betaSaved(IterationNum-BurnIn,:) = CurrentBeta;
    end

    
    % Start timer after burn-in
    if IterationNum == BurnIn
        disp('Burn-in complete, now drawing samples.')
       tic;
    end
end
Times = toc;

betaPosterior = betaSaved;
acprat = size(unique(betaPosterior,'rows'),1)/(NumOfIterations-BurnIn);

CurTime = fix(clock);
save(['Results/Results_RMHMC_BLR_' data  '_' num2str(NumOfLeapFrogSteps) 'nLeap_' num2str(CurTime) '.mat'], 'StepSize', 'NumOfLeapFrogSteps', 'acprat', 'betaPosterior', 'Times')
end



function U = U(y, X, CurrentBeta,alpha,varargin)
if size(CurrentBeta,2)~=1
    CurrentBeta = CurrentBeta';
end
flag = 0;
if nargin > 4
    flag = varargin{1};
end

if flag == 0
    U = sum(log(1+exp(X*CurrentBeta))) - y' * (X*CurrentBeta) + 1/2/alpha*sum(CurrentBeta.^2);
else
    U = X' *(exp(X*CurrentBeta)./(1+exp(X*CurrentBeta)) - y) + CurrentBeta/alpha;
end
        
end
