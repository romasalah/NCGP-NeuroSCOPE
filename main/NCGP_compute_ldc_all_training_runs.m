% LDC for one held-out run using every usable training run.
% One pooled residual covariance is shared by all 28 condition pairs.
% The searchlight vertices are not removed or reordered.
function [dist, nfailed] = NCGP_compute_ldc_all_training_runs(train_betas, test_betas, train_residuals)

[nfeatures, ncond, ntrain] = size(train_betas);
dist = zeros(ncond);
dist(triu(true(ncond),1)) = NaN;
nfailed = 0;

assert(isequal(size(test_betas), [nfeatures ncond]));
assert(iscell(train_residuals) && numel(train_residuals) == ntrain);

% Exclude incomplete runs from both beta and residual training data.
good = reshape(all(all(isfinite(train_betas),1),2) & ...
    all(any(train_betas ~= 0,1),2), 1, ntrain);
for r = 1:ntrain
    R = train_residuals{r};
    good(r) = good(r) && ~isempty(R) && size(R,2) == nfeatures && ...
        all(isfinite(R(:))) && any(any(R ~= 0));
end

% A run with an undefined face contrast is excluded from all pairs,
% so every pair uses the same training runs and covariance estimate.
for c1 = 1:ncond-1
    for c2 = c1+1:ncond
        delta = reshape(train_betas(:,c1,:) - train_betas(:,c2,:), ...
            nfeatures,ntrain);
        good = good & any(delta ~= 0,1);
    end
end

npairs = ncond*(ncond-1)/2;
nfailed = npairs * nnz(~good);
if ~any(good) || any(~isfinite(test_betas(:))) || ...
        any(all(test_betas == 0,1))
    return
end

% Each residual row is one time sample; columns remain the same vertices.
R = double(vertcat(train_residuals{good}));
[Sigma,~,sample] = Function_covdiag(R);

% When covariance is exactly diagonal, the shrinkage formula can give 0/0.
% The diagonal shrinkage target is the well-defined limiting estimate.
if any(~isfinite(Sigma(:))) && all(isfinite(sample(:)))
    diagonal = diag(diag(sample));
    if norm(sample-diagonal,'fro') <= 1e-12 * max(norm(sample,'fro'),eps)
        Sigma = diagonal;
    end
end
if any(~isfinite(Sigma(:))) || ~any(diag(Sigma) > 0)
    nfailed = nfailed + npairs*nnz(good);
    return
end

% Pseudoinverse handles zero-variance vertices without changing the
% dimensions or deleting vertices from the searchlight.
SigmaInv = pinv(Sigma);
if any(~isfinite(SigmaInv(:)))
    nfailed = nfailed + npairs*nnz(good);
    return
end

for c1 = 1:ncond-1
    for c2 = c1+1:ncond
        delta = reshape(double(train_betas(:,c1,good) - ...
            train_betas(:,c2,good)), nfeatures,[]);
        weights = SigmaInv * delta;
        lengths = sqrt(sum(weights.^2,1));
        usable = isfinite(lengths) & lengths > 0;
        nfailed = nfailed + nnz(~usable);
        if ~any(usable)
            continue
        end
        test_delta = double(test_betas(:,c1) - test_betas(:,c2));
        weights = weights(:,usable) ./ lengths(usable);
        dist(c1,c2) = mean(test_delta' * weights);
    end
end
end
