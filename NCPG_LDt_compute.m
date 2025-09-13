% Overall goal: Calcuulates linear discriminant t-value. First calculates difference
% in training runs then multiply it by the inverse of the variance-covariance matrix.
% Then normalize the distance by the square root of the sum of square.
% Multiply the normalized distance by the difference in test runs.
function LDtmat=NCPG_LDt_compute(betasbycond_train, betasbycond_test, residuals_train)
%% Start Calculation
LDtmat=[];
% check  A Walther et al. 2016 https://www.diedrichsenlab.org/pubs/Walther_Neuroimage_2016.pdf for more about LDC/LDt options
[sigma,~,~] = Function_covdiag(residuals_train); % Function_covdiag is from the RSA toolbox
inverted_sigma=inv(sigma);
% Section: for-block starts
for b1= 1:size(betasbycond_train,2)
% Section: for-block starts
    for b2= (b1+1):size(betasbycond_train,2)
        train_cond1=betasbycond_train(:,b1);
        train_cond2=betasbycond_train(:,b2);
        test_cond1=betasbycond_test(:,b1);
        test_cond2=betasbycond_test(:,b2);
        %%% LDC based on Johan Carlin's code:
        %%% http://www.johancarlin.com/pilab-tutorial-2-linear-discriminant-contrast.html
        % Faces
        Distance_train=(train_cond1-train_cond2);
        D2 = Distance_train' * inverted_sigma;
        Normalized_distance = D2/sqrt(sum(D2.^2));
        distance_in_test=(test_cond1-test_cond2);
        LDtmat(b1,b2) =  distance_in_test'* Normalized_distance';
    end
end
LDtmat(size(betasbycond_train,2),:) = 0;