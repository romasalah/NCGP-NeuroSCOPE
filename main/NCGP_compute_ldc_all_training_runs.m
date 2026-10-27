% Compute LDC from all usable training runs, with covariance estimated
% separately for each face pair from the matching training residuals.
% The searchlight vertices and held-out test pattern are unchanged.
function [dist, nfailed] = NCGP_compute_ldc_all_training_runs(train_betas, test_betas, train_residuals)

nfeatures = size(train_betas,1);
ncond = size(train_betas,2);
ntrain = size(train_betas,3);
dist = zeros(ncond);
nfailed = 0;

% Residual cell i must correspond to training beta run i.
valid_res = cellfun(@(r) ~isempty(r) && size(r,2)==nfeatures && ...
    all(isfinite(r(:))), train_residuals);
valid_res = valid_res(:).';

for c1 = 1:ncond-1
    for c2 = c1+1:ncond
        delta = reshape(double(train_betas(:,c1,:) - ...
            train_betas(:,c2,:)), nfeatures, ntrain);

        % Exclude invalid run-specific contrasts and their residuals.
        valid = all(isfinite(delta),1) & any(delta~=0,1) & valid_res;
        nfailed = nfailed + nnz(~valid);
        if ~any(valid)
            dist(c1,c2) = NaN;
            continue
        end

        R = double(vertcat(train_residuals{valid}));
        Sigma = Function_covdiag(R);

        if any(~isfinite(Sigma(:)))
            nfailed = nfailed + nnz(valid);
            dist(c1,c2) = NaN;
            continue
        end

        % Pseudoinverse handles zero-variance vertices without changing
        % the searchlight or deleting its rows.
        if rcond(Sigma) < 1e-12
            weights = pinv(Sigma) * delta(:,valid);
        else
            weights = Sigma \ delta(:,valid);
        end

        norms = sqrt(sum(weights.^2,1));
        good = isfinite(norms) & norms > 0;
        nfailed = nfailed + nnz(~good);
        test_delta = double(test_betas(:,c1) - test_betas(:,c2));

        if ~any(good) || any(~isfinite(test_delta))
            dist(c1,c2) = NaN;
            continue
        end

        weights = weights(:,good) ./ norms(good);
        dist(c1,c2) = mean(test_delta' * weights);
    end
end
end
