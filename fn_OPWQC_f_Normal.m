function [f,F] = fn_OPWQC_f_Normal(c,mu, sigma)

if 0 % get file name, say hello
    [~, thisFileName, ~] = fileparts(mfilename('fullpath'));
    fprintf('\n   vvv  from %s:  vvvvvv',...
        thisFileName)
end

if 1 % derived inputs
    T = length(c);
    
end
if 1 % initialize output variables
    f = NaN(1,T);
    F = NaN(1,T);
end

if 1 % f
    f = normpdf(c,mu,sigma);
    f=f./sum(f);
end

for c1_iter = 1:T
    F(c1_iter) = sum(f(1:c1_iter));
end


if 0 % final report
    fprintf('\n   ^^^ %s is done ^^^^^^', thisFileName)
end

end