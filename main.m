%% OPWQC (Lopomo Persico Villa): Border LP
%% reset + hello
% reset, initialize paths
close all; clc; clear all;
% Paths:ampl and cplex
amplPath = 'C:\AMPL\';
cplexPath = 'C:\Program Files\IBM\ILOG\CPLEX_Studio129\cplex\bin\x64_win64\';
desktopFolder = 'C:\Users\forke\OneDrive\Desktop\MatlabWorkOPW\';

S = 7; T = 60;
cL = 0; cH = 1;

%Using illustrative example, change as you wish
c=linspace(cL,cH,T);
v= 4*c-2*c.^2;
f=1/T*ones(1,T);
f=f/sum(f);
F=cumsum(f);

w = nan(1,length(c));
for i=1:length(c)
    if i==1
        w(i)=v(i)-c(i);
    else
        w(i)=v(i)-c(i)-(c(i)-c(i-1))*F(i-1)/f(i);
    end
end


% call maxBuyerSurplus
aaOPWQC_LP_Border

fprintf('\nfrom Cplex: ')
thresholdCost = c(T);
thresholdType = T;
for t = T-1 : -1 : 1
    if Q(t)-Q(t+1)>1e-8
        thresholdCost = c(t);
        thresholdType = t;
    end
end
plot(c,Q)
fprintf('\n  thresholdCost = %g, thresholdType = %g (T = %g)\n', thresholdCost, thresholdType, T)

fprintf('\n\nAll done.\n')



