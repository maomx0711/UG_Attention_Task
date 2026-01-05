%% Sequential Dependency Models for Ultimatum Game (UG) Task
% 
% This script implements mathematical models to verify hypotheses about 
% sequential dependency effects in the Ultimatum Game:
%
% Hypothesis 1: Decisions depend only on the current amount (Threshold Model)
% Hypothesis 2: Decisions depend on both previous and current amounts 
%               (Linear Model/Bayesian Model)
% Hypothesis 2+: RL reward-punishment framework with Bayesian updating
% Hypothesis 3: Decisions depend on current/previous amounts AND previous 
%               decisions (HMM)
%
% Models implemented:
% 1. Threshold Model - Simple logistic regression on current offer
% 2. Linear Model with History - Logistic regression with previous trial info
% 3. Bayesian Decision Model - Adaptive threshold based on prior beliefs
% 4. RL-Bayesian Model - Reward-punishment with Bayesian updating
% 5. Hidden Markov Model (HMM) - State-based decision model
%
% Author: Sequential Dependency Analysis
% Date: 2026-01-05

clear all;
clc;

%% Configuration
% Data folder path - modify this to your data location
data_folder = './data';  % Change to your data folder
pattern = '*UGi_*_1.mat';

% Model fitting options
options = struct();
options.n_restarts = 5;        % Number of random restarts for optimization
options.max_iter = 1000;       % Maximum iterations
options.verbose = true;        % Print progress

%% Load Data
% Try to find data files
if exist(data_folder, 'dir')
    fileList = dir(fullfile(data_folder, pattern));
else
    % Use simulated data for demonstration
    fprintf('Data folder not found. Using simulated data for demonstration.\n');
    fileList = [];
end

if isempty(fileList)
    % Generate simulated data
    fprintf('\n=== Generating Simulated Data ===\n');
    [offers, decisions] = simulate_ug_data(200, 'H2', 42);
    fprintf('Generated %d trials with %.1f%% acceptance rate\n', ...
        length(offers), 100*mean(decisions));
else
    % Load actual data
    fprintf('Found %d data files\n', length(fileList));
    % Load first subject for demonstration
    data = load(fullfile(data_folder, fileList(1).name));
    result = data.result;
    % Note: MATLAB uses 1-indexed arrays (row 7 for offers, row 4 for decisions)
    % This differs from Python which uses 0-indexed arrays (index 6 and 3)
    offers = result(7, :);      % Discount rate (offer proportion) - MATLAB row 7
    decisions = result(4, :);   % Accept (1) or Reject (0) - MATLAB row 4
    
    % Filter valid trials
    valid_idx = offers >= 0 & offers <= 1;
    offers = offers(valid_idx);
    decisions = decisions(valid_idx);
end

%% ========================================================================
% Model 1: Threshold Model (Hypothesis 1)
% ========================================================================
fprintf('\n=== Fitting Threshold Model (H1) ===\n');

% Model: P(accept) = sigmoid(beta0 + beta1 * offer)
[params_threshold, nll_threshold, aic_threshold, bic_threshold] = ...
    fit_threshold_model(offers, decisions, options);

fprintf('Parameters: beta0 = %.3f, beta1 = %.3f\n', params_threshold(1), params_threshold(2));
fprintf('Threshold (50%% accept): %.3f\n', -params_threshold(1)/params_threshold(2));
fprintf('Log-likelihood: %.2f\n', -nll_threshold);
fprintf('AIC: %.2f, BIC: %.2f\n', aic_threshold, bic_threshold);

%% ========================================================================
% Model 2: Linear History Model (Hypothesis 2)
% ========================================================================
fprintf('\n=== Fitting Linear History Model (H2) ===\n');

% Model: P(accept) = sigmoid(beta0 + beta1*offer_t + beta2*offer_{t-1} + beta3*diff)
prev_offers = [offers(1), offers(1:end-1)];

[params_linear, nll_linear, aic_linear, bic_linear] = ...
    fit_linear_history_model(offers(2:end), prev_offers(2:end), decisions(2:end), options);

fprintf('Parameters:\n');
fprintf('  beta0 (intercept): %.3f\n', params_linear(1));
fprintf('  beta1 (current offer): %.3f\n', params_linear(2));
fprintf('  beta2 (previous offer): %.3f\n', params_linear(3));
fprintf('  beta3 (contrast): %.3f\n', params_linear(4));
fprintf('Log-likelihood: %.2f\n', -nll_linear);
fprintf('AIC: %.2f, BIC: %.2f\n', aic_linear, bic_linear);

%% ========================================================================
% Model 3: Bayesian Decision Model (Hypothesis 2)
% ========================================================================
fprintf('\n=== Fitting Bayesian Decision Model (H2) ===\n');

% Model with adaptive expectations
[params_bayes, nll_bayes, aic_bayes, bic_bayes, learning_rate] = ...
    fit_bayesian_model(offers, decisions, options);

fprintf('Parameters:\n');
fprintf('  beta0 (baseline): %.3f\n', params_bayes(1));
fprintf('  beta1 (expectation deviation): %.3f\n', params_bayes(2));
fprintf('  beta2 (offer value): %.3f\n', params_bayes(3));
fprintf('  Learning rate: %.3f\n', learning_rate);
fprintf('Log-likelihood: %.2f\n', -nll_bayes);
fprintf('AIC: %.2f, BIC: %.2f\n', aic_bayes, bic_bayes);

%% ========================================================================
% Model 4: RL-Bayesian Model (Hypothesis 2+)
% Reinforcement Learning + Bayesian belief updating
% ========================================================================
fprintf('\n=== Fitting RL-Bayesian Model (H2+) ===\n');

[params_rl, nll_rl, aic_rl, bic_rl] = ...
    fit_rl_bayesian_model(offers, decisions, options);

fprintf('Parameters:\n');
fprintf('  w_r (reward weight): %.3f\n', params_rl(1));
fprintf('  w_p (punishment weight): %.3f\n', params_rl(2));
fprintf('  gamma (punishment decay): %.3f\n', params_rl(3));
fprintf('  beta (inverse temperature): %.3f\n', params_rl(4));
fprintf('  bias: %.3f\n', params_rl(5));
fprintf('  lambda (expectation effect): %.3f\n', params_rl(6));
fprintf('  alpha (learning rate): %.3f\n', params_rl(7));
fprintf('Log-likelihood: %.2f\n', -nll_rl);
fprintf('AIC: %.2f, BIC: %.2f\n', aic_rl, bic_rl);

%% ========================================================================
% Model 5: Hidden Markov Model (Hypothesis 3)
% ========================================================================
fprintf('\n=== Fitting Hidden Markov Model (H3) ===\n');

[params_hmm, nll_hmm, aic_hmm, bic_hmm] = ...
    fit_hmm_model(offers, decisions, options);

fprintf('Initial state probability (lenient): %.3f\n', params_hmm(1));
fprintf('Transition probabilities:\n');
fprintf('  After Accept: P(lenient|strict)=%.3f, P(lenient|lenient)=%.3f\n', ...
    params_hmm(2), params_hmm(3));
fprintf('  After Reject: P(lenient|strict)=%.3f, P(lenient|lenient)=%.3f\n', ...
    params_hmm(4), params_hmm(5));
fprintf('Emission parameters:\n');
fprintf('  Strict state: beta0=%.3f, beta1=%.3f\n', params_hmm(6), params_hmm(7));
fprintf('  Lenient state: beta0=%.3f, beta1=%.3f\n', params_hmm(8), params_hmm(9));
fprintf('Log-likelihood: %.2f\n', -nll_hmm);
fprintf('AIC: %.2f, BIC: %.2f\n', aic_hmm, bic_hmm);

%% ========================================================================
% Model Comparison
% ========================================================================
fprintf('\n');
fprintf('==============================================================\n');
fprintf('                    MODEL COMPARISON RESULTS                   \n');
fprintf('==============================================================\n');
fprintf('\n');

% Create comparison table
models = {'Threshold (H1)', 'Linear History (H2)', 'Bayesian (H2)', 'RL-Bayesian (H2+)', 'HMM (H3)'};
n_params = [2, 4, 4, 7, 9];
log_likelihoods = [-nll_threshold, -nll_linear, -nll_bayes, -nll_rl, -nll_hmm];
aics = [aic_threshold, aic_linear, aic_bayes, aic_rl, aic_hmm];
bics = [bic_threshold, bic_linear, bic_bayes, bic_rl, bic_hmm];

% Delta AIC/BIC
delta_aic = aics - min(aics);
delta_bic = bics - min(bics);

% AIC weights
aic_weights = exp(-0.5 * delta_aic);
aic_weights = aic_weights / sum(aic_weights);

fprintf('%-20s %8s %12s %10s %10s %10s\n', ...
    'Model', 'Params', 'LogLik', 'AIC', 'BIC', 'Weight');
fprintf('%-20s %8s %12s %10s %10s %10s\n', ...
    repmat('-', 1, 20), repmat('-', 1, 8), repmat('-', 1, 12), ...
    repmat('-', 1, 10), repmat('-', 1, 10), repmat('-', 1, 10));

for i = 1:length(models)
    fprintf('%-20s %8d %12.2f %10.2f %10.2f %10.3f\n', ...
        models{i}, n_params(i), log_likelihoods(i), aics(i), bics(i), aic_weights(i));
end

% Determine best model
[~, best_aic_idx] = min(aics);
[~, best_bic_idx] = min(bics);

fprintf('\n');
fprintf('Best model by AIC: %s (ΔAIC = 0)\n', models{best_aic_idx});
fprintf('Best model by BIC: %s (ΔBIC = 0)\n', models{best_bic_idx});

% Hypothesis conclusion
fprintf('\n');
fprintf('==============================================================\n');
fprintf('                       HYPOTHESIS SUPPORT                      \n');
fprintf('==============================================================\n');

if best_bic_idx == 1
    fprintf('\nSupported Hypothesis: H1\n');
    fprintf('→ Decisions depend ONLY on current offer amount\n');
    fprintf('  The threshold model provides the best balance of fit and parsimony.\n');
elseif best_bic_idx == 2 || best_bic_idx == 3
    fprintf('\nSupported Hypothesis: H2\n');
    fprintf('→ Decisions depend on BOTH current and previous offer amounts\n');
    fprintf('  Sequential effects on decision-making are present.\n');
elseif best_bic_idx == 4
    fprintf('\nSupported Hypothesis: H2+ (RL-Bayesian)\n');
    fprintf('→ Decisions follow RL reward-punishment framework with Bayesian updating\n');
    fprintf('  Accept = reward + punishment; punishment decreases with higher offers.\n');
else
    fprintf('\nSupported Hypothesis: H3\n');
    fprintf('→ Decisions depend on offers AND previous decisions\n');
    fprintf('  The decision process includes state-dependent dynamics.\n');
end

%% ========================================================================
% Visualization
% ========================================================================
fprintf('\n');
fprintf('==============================================================\n');
fprintf('                        VISUALIZATION                          \n');
fprintf('==============================================================\n');

% Figure 1: Model Comparison
figure('Position', [100, 100, 1200, 400]);

subplot(1, 3, 1);
bar_data = [aics; bics]';
bar(bar_data);
set(gca, 'XTickLabel', models, 'XTickLabelRotation', 45);
ylabel('Information Criterion');
title('AIC vs BIC Comparison');
legend('AIC', 'BIC', 'Location', 'best');

subplot(1, 3, 2);
bar(aic_weights, 'FaceColor', [0.4, 0.6, 0.8]);
set(gca, 'XTickLabel', models, 'XTickLabelRotation', 45);
ylabel('AIC Weight');
title('Model Weights');

subplot(1, 3, 3);
bar(log_likelihoods, 'FaceColor', [0.3, 0.5, 0.7]);
set(gca, 'XTickLabel', models, 'XTickLabelRotation', 45);
ylabel('Log-Likelihood');
title('Model Fit');

sgtitle('Model Comparison Results');

% Figure 2: Psychometric Curves
figure('Position', [100, 550, 800, 600]);

% Bin data for visualization
offer_bins = linspace(0.1, 0.5, 9);
bin_centers = (offer_bins(1:end-1) + offer_bins(2:end)) / 2;

empirical_rates = zeros(1, length(bin_centers));
empirical_sem = zeros(1, length(bin_centers));

for i = 1:length(bin_centers)
    mask = offers >= offer_bins(i) & offers < offer_bins(i+1);
    if sum(mask) > 0
        empirical_rates(i) = mean(decisions(mask));
        empirical_sem(i) = std(decisions(mask)) / sqrt(sum(mask));
    else
        empirical_rates(i) = NaN;
        empirical_sem(i) = NaN;
    end
end

% Plot empirical data
errorbar(bin_centers, empirical_rates, empirical_sem, 'ko', ...
    'MarkerSize', 10, 'MarkerFaceColor', 'k', 'LineWidth', 2);
hold on;

% Plot model predictions
x_pred = linspace(0.1, 0.5, 100);

% Threshold model prediction
y_threshold = 1 ./ (1 + exp(-(params_threshold(1) + params_threshold(2) * x_pred)));
plot(x_pred, y_threshold, 'r-', 'LineWidth', 2);

% Bayesian model prediction (using mean expectation)
mean_exp = mean(offers);
y_bayes = 1 ./ (1 + exp(-(params_bayes(1) + params_bayes(2) * (x_pred - mean_exp) + params_bayes(3) * x_pred)));
plot(x_pred, y_bayes, 'g--', 'LineWidth', 2);

xlabel('Offer Proportion');
ylabel('P(Accept)');
title('Psychometric Curves: Model Fits');
legend('Data', 'Threshold (H1)', 'Bayesian (H2)', 'Location', 'southeast');
xlim([0.05, 0.55]);
ylim([-0.05, 1.05]);
grid on;

% Save figures
saveas(gcf, 'model_comparison_results.png');
fprintf('\nFigures saved to model_comparison_results.png\n');

%% ========================================================================
% Helper Functions
% ========================================================================

function [params, nll, aic, bic] = fit_threshold_model(offers, decisions, options)
    % Fit threshold model using fmincon
    
    n = length(offers);
    
    % Objective function
    obj_func = @(p) threshold_nll(p, offers, decisions);
    
    % Initial parameters
    init_params = [0, 5];
    
    % Bounds
    lb = [-10, -50];
    ub = [10, 50];
    
    % Optimize
    opt_options = optimoptions('fmincon', 'Display', 'off', ...
        'MaxIterations', options.max_iter);
    
    [params, nll] = fmincon(obj_func, init_params, [], [], [], [], lb, ub, [], opt_options);
    
    % Calculate AIC/BIC
    k = 2;
    aic = 2*k + 2*nll;
    bic = k*log(n) + 2*nll;
end

function nll = threshold_nll(params, offers, decisions)
    % Negative log-likelihood for threshold model
    beta0 = params(1);
    beta1 = params(2);
    
    linear_pred = beta0 + beta1 * offers;
    p_accept = 1 ./ (1 + exp(-linear_pred));
    
    % Clip to avoid log(0)
    eps = 1e-10;
    p_accept = max(min(p_accept, 1-eps), eps);
    
    % Binary cross-entropy
    nll = -sum(decisions .* log(p_accept) + (1-decisions) .* log(1-p_accept));
end

function [params, nll, aic, bic] = fit_linear_history_model(curr_offers, prev_offers, decisions, options)
    % Fit linear history model
    
    n = length(curr_offers);
    
    % Design matrix: [1, current, previous, contrast]
    contrast = curr_offers - prev_offers;
    X = [ones(1, n); curr_offers; prev_offers; contrast]';
    
    % Objective function
    obj_func = @(p) linear_nll(p, X, decisions);
    
    % Initial parameters
    init_params = [0, 5, 0, 0];
    
    % Bounds
    lb = [-10, -50, -50, -50];
    ub = [10, 50, 50, 50];
    
    % Optimize
    opt_options = optimoptions('fmincon', 'Display', 'off', ...
        'MaxIterations', options.max_iter);
    
    [params, nll] = fmincon(obj_func, init_params, [], [], [], [], lb, ub, [], opt_options);
    
    % Calculate AIC/BIC
    k = 4;
    aic = 2*k + 2*nll;
    bic = k*log(n) + 2*nll;
end

function nll = linear_nll(params, X, decisions)
    % Negative log-likelihood for linear model
    linear_pred = X * params';
    p_accept = 1 ./ (1 + exp(-linear_pred));
    
    eps = 1e-10;
    p_accept = max(min(p_accept, 1-eps), eps);
    
    nll = -sum(decisions .* log(p_accept') + (1-decisions) .* log(1-p_accept'));
end

function [params, nll, aic, bic, alpha] = fit_bayesian_model(offers, decisions, options)
    % Fit Bayesian decision model
    
    n = length(offers);
    
    % Objective function (includes alpha)
    obj_func = @(p) bayesian_nll(p, offers, decisions);
    
    % Initial parameters: [beta0, beta1, beta2, alpha]
    init_params = [0, 2, 5, 0.2];
    
    % Bounds
    lb = [-10, -50, -50, 0.01];
    ub = [10, 50, 50, 0.99];
    
    % Optimize
    opt_options = optimoptions('fmincon', 'Display', 'off', ...
        'MaxIterations', options.max_iter);
    
    [full_params, nll] = fmincon(obj_func, init_params, [], [], [], [], lb, ub, [], opt_options);
    
    params = full_params(1:3);
    alpha = full_params(4);
    
    % Calculate AIC/BIC
    k = 4;
    aic = 2*k + 2*nll;
    bic = k*log(n) + 2*nll;
end

function nll = bayesian_nll(params, offers, decisions)
    % Negative log-likelihood for Bayesian model
    beta0 = params(1);
    beta1 = params(2);
    beta2 = params(3);
    alpha = params(4);
    
    n = length(offers);
    
    % Compute running expectations
    expectations = zeros(1, n);
    expectations(1) = 0.5;  % Initial expectation: fair split
    for t = 2:n
        expectations(t) = (1 - alpha) * expectations(t-1) + alpha * offers(t-1);
    end
    
    deviations = offers - expectations;
    linear_pred = beta0 + beta1 * deviations + beta2 * offers;
    p_accept = 1 ./ (1 + exp(-linear_pred));
    
    eps = 1e-10;
    p_accept = max(min(p_accept, 1-eps), eps);
    
    nll = -sum(decisions .* log(p_accept) + (1-decisions) .* log(1-p_accept));
end

function [params, nll, aic, bic] = fit_hmm_model(offers, decisions, options)
    % Fit Hidden Markov Model
    
    n = length(offers);
    
    % Objective function
    obj_func = @(p) hmm_nll(p, offers, decisions);
    
    % Initial parameters:
    % [pi1, A_acc[0,1], A_acc[1,1], A_rej[0,1], A_rej[1,1], 
    %  beta0_0, beta1_0, beta0_1, beta1_1]
    init_params = [0.5, 0.3, 0.7, 0.5, 0.5, -2, 8, 2, 4];
    
    % Bounds
    lb = [0.01, 0.01, 0.01, 0.01, 0.01, -10, -50, -10, -50];
    ub = [0.99, 0.99, 0.99, 0.99, 0.99, 10, 50, 10, 50];
    
    % Multiple restarts
    best_nll = Inf;
    best_params = init_params;
    
    opt_options = optimoptions('fmincon', 'Display', 'off', ...
        'MaxIterations', options.max_iter);
    
    for r = 1:options.n_restarts
        % Random initialization
        try_params = init_params + 0.5 * randn(size(init_params));
        try_params = max(min(try_params, ub), lb);
        
        try
            [try_opt_params, try_nll] = fmincon(obj_func, try_params, ...
                [], [], [], [], lb, ub, [], opt_options);
            
            if try_nll < best_nll
                best_nll = try_nll;
                best_params = try_opt_params;
            end
        catch
            continue;
        end
    end
    
    params = best_params;
    nll = best_nll;
    
    % Calculate AIC/BIC
    k = 9;
    aic = 2*k + 2*nll;
    bic = k*log(n) + 2*nll;
end

function nll = hmm_nll(params, offers, decisions)
    % Negative log-likelihood for HMM using forward algorithm
    
    n = length(offers);
    n_states = 2;
    
    % Unpack parameters
    pi = [1 - params(1), params(1)];  % Initial state distribution
    
    % Transition matrices [s_from, s_to] for accept/reject
    A = zeros(2, 2, 2);  % [prev_decision+1, s_from, s_to]
    A(2, 1, 1) = 1 - params(2);  % accept: s0 -> s0
    A(2, 1, 2) = params(2);       % accept: s0 -> s1
    A(2, 2, 1) = 1 - params(3);  % accept: s1 -> s0
    A(2, 2, 2) = params(3);       % accept: s1 -> s1
    
    A(1, 1, 1) = 1 - params(4);  % reject: s0 -> s0
    A(1, 1, 2) = params(4);       % reject: s0 -> s1
    A(1, 2, 1) = 1 - params(5);  % reject: s1 -> s0
    A(1, 2, 2) = params(5);       % reject: s1 -> s1
    
    % Emission parameters
    beta0 = [params(6), params(8)];
    beta1 = [params(7), params(9)];
    
    % Forward algorithm
    alpha = zeros(n, n_states);
    scale = zeros(1, n);
    
    % Initialize
    for s = 1:n_states
        p_emit = 1 / (1 + exp(-(beta0(s) + beta1(s) * offers(1))));
        if decisions(1) == 1
            p_obs = p_emit;
        else
            p_obs = 1 - p_emit;
        end
        alpha(1, s) = pi(s) * p_obs;
    end
    
    scale(1) = sum(alpha(1, :));
    if scale(1) > 0
        alpha(1, :) = alpha(1, :) / scale(1);
    else
        scale(1) = 1e-300;
    end
    
    % Forward pass
    for t = 2:n
        prev_dec = decisions(t-1) + 1;  % 1 for reject, 2 for accept
        trans_mat = squeeze(A(prev_dec, :, :));
        
        for s = 1:n_states
            p_emit = 1 / (1 + exp(-(beta0(s) + beta1(s) * offers(t))));
            if decisions(t) == 1
                p_obs = p_emit;
            else
                p_obs = 1 - p_emit;
            end
            
            alpha(t, s) = sum(alpha(t-1, :) .* trans_mat(:, s)') * p_obs;
        end
        
        scale(t) = sum(alpha(t, :));
        if scale(t) > 0
            alpha(t, :) = alpha(t, :) / scale(t);
        else
            scale(t) = 1e-300;
        end
    end
    
    % Log-likelihood
    nll = -sum(log(scale));
end

function [params, nll, aic, bic] = fit_rl_bayesian_model(offers, decisions, options)
    % Fit Reinforcement Learning + Bayesian Model
    % U(accept) = w_r * offer - w_p * exp(-gamma * offer)
    % P(accept) = sigmoid(beta * U + bias + lambda * (offer - expectation))
    
    n = length(offers);
    
    % Objective function
    obj_func = @(p) rl_bayesian_nll(p, offers, decisions);
    
    % Initial parameters: [w_r, w_p, gamma, beta, bias, lambda, alpha]
    init_params = [5, 2, 3, 1, 0, 2, 0.2];
    
    % Bounds
    lb = [0.1, 0.1, 0.1, 0.1, -5, -20, 0.01];
    ub = [20, 20, 20, 10, 5, 20, 0.99];
    
    % Multiple restarts
    best_nll = Inf;
    best_params = init_params;
    
    opt_options = optimoptions('fmincon', 'Display', 'off', ...
        'MaxIterations', options.max_iter);
    
    for r = 1:options.n_restarts
        % Random initialization
        try_params = init_params + 0.5 * randn(size(init_params));
        try_params = max(min(try_params, ub), lb);
        
        try
            [try_opt_params, try_nll] = fmincon(obj_func, try_params, ...
                [], [], [], [], lb, ub, [], opt_options);
            
            if try_nll < best_nll
                best_nll = try_nll;
                best_params = try_opt_params;
            end
        catch
            continue;
        end
    end
    
    params = best_params;
    nll = best_nll;
    
    % Calculate AIC/BIC
    k = 7;
    aic = 2*k + 2*nll;
    bic = k*log(n) + 2*nll;
end

function nll = rl_bayesian_nll(params, offers, decisions)
    % Negative log-likelihood for RL-Bayesian model
    w_r = params(1);      % reward weight
    w_p = params(2);      % punishment weight
    gamma_p = params(3);  % punishment decay
    beta = params(4);     % inverse temperature
    bias = params(5);     % baseline bias
    lambda = params(6);   % expectation effect
    alpha = params(7);    % learning rate
    
    n = length(offers);
    
    % Compute running expectations
    expectations = zeros(1, n);
    expectations(1) = 0.5;
    for t = 2:n
        expectations(t) = (1 - alpha) * expectations(t-1) + alpha * offers(t-1);
    end
    
    % Compute utilities: U = reward - punishment
    rewards = w_r * offers;
    punishments = w_p * exp(-gamma_p * offers);
    utilities = rewards - punishments;
    
    % Bayesian expectation effect
    expectation_effects = lambda * (offers - expectations);
    
    % Decision values
    decision_values = beta * utilities + bias + expectation_effects;
    
    % P(accept)
    p_accept = 1 ./ (1 + exp(-decision_values));
    
    eps = 1e-10;
    p_accept = max(min(p_accept, 1-eps), eps);
    
    nll = -sum(decisions .* log(p_accept) + (1-decisions) .* log(1-p_accept));
end

function [offers, decisions] = simulate_ug_data(n_trials, true_model, seed)
    % Simulate UG data from different models
    
    rng(seed);
    
    % Generate random offers
    offers = 0.1 + 0.4 * rand(1, n_trials);
    decisions = zeros(1, n_trials);
    
    sigmoid = @(x) 1 ./ (1 + exp(-x));
    
    switch true_model
        case 'H1'
            % Simple threshold
            threshold = 0.25;
            sensitivity = 10;
            for t = 1:n_trials
                p_accept = sigmoid(sensitivity * (offers(t) - threshold));
                decisions(t) = rand() < p_accept;
            end
            
        case 'H2'
            % Sequential effect
            base_threshold = 0.25;
            sensitivity = 10;
            seq_weight = 0.3;
            
            for t = 1:n_trials
                if t == 1
                    eff_threshold = base_threshold;
                else
                    eff_threshold = base_threshold - seq_weight * (offers(t-1) - 0.3);
                end
                p_accept = sigmoid(sensitivity * (offers(t) - eff_threshold));
                decisions(t) = rand() < p_accept;
            end
            
        case 'H3'
            % HMM
            thresholds = [0.30, 0.20];
            sensitivity = 10;
            trans_accept = [0.7, 0.3; 0.2, 0.8];
            trans_reject = [0.8, 0.2; 0.5, 0.5];
            
            state = randi(2);
            for t = 1:n_trials
                p_accept = sigmoid(sensitivity * (offers(t) - thresholds(state)));
                decisions(t) = rand() < p_accept;
                
                if decisions(t) == 1
                    state = randsample(1:2, 1, true, trans_accept(state, :));
                else
                    state = randsample(1:2, 1, true, trans_reject(state, :));
                end
            end
    end
end
