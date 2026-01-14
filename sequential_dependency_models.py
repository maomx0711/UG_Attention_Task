#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Sequential Dependency Models for Ultimatum Game (UG) Task

This module implements mathematical models to verify hypotheses about sequential 
dependency effects in the Ultimatum Game:

Hypothesis 1: Decisions depend only on the current amount (Threshold Model)
Hypothesis 2: Decisions depend on both previous and current amounts (Linear/Bayesian Models)
Hypothesis 2+: Decisions follow RL reward-punishment framework with Bayesian updating
Hypothesis 2++: Formal Bayesian utility model with power functions and proper priors
Hypothesis 3: Decisions depend on current/previous amounts AND previous decisions (HMM)

Models implemented:
1. Threshold Model - Simple logistic regression on current offer
2. Linear Model with History - Logistic regression including previous trial information
3. Bayesian Decision Model - Adaptive threshold based on prior beliefs
4. Reinforcement Learning + Bayesian Model - Reward-punishment framework where:
   - Accepting provides reward (monetary gain)
   - Accepting incurs punishment (fairness violation)
   - Punishment decreases as offer amount increases
   - Combined with Bayesian belief updating
5. Bayesian Utility Model - Formal Bayesian framework with:
   - Power utility functions: u(r) = r^α, v(c) = λ*c^β
   - Proper prior distributions on all parameters
   - Risk attitude (α) and loss aversion (λ) interpretation
   - MAP or MLE estimation
6. Hidden Markov Model (HMM) - State-based decision model with decision history influence

Author: Sequential Dependency Analysis
Date: 2026-01-05
"""

import numpy as np
import pandas as pd
from scipy import stats
from scipy.optimize import minimize
from scipy.special import expit  # sigmoid function
import warnings
warnings.filterwarnings('ignore')


# ============================================================================
# Model 1: Threshold Model (Hypothesis 1)
# Decisions depend only on the current offer amount
# ============================================================================

class ThresholdModel:
    """
    Simple threshold model where acceptance probability depends only on current offer.
    
    P(accept | offer) = sigmoid(beta0 + beta1 * offer)
    
    Parameters:
    - beta0: intercept (threshold position)
    - beta1: sensitivity (steepness of decision curve)
    """
    
    def __init__(self):
        self.params = None
        self.fitted = False
        self.log_likelihood = None
        self.aic = None
        self.bic = None
        
    def _sigmoid(self, x):
        """Numerically stable sigmoid function."""
        return expit(x)
    
    def _neg_log_likelihood(self, params, offers, decisions):
        """
        Compute negative log-likelihood for the threshold model.
        
        Args:
            params: [beta0, beta1]
            offers: array of offer proportions (0-1)
            decisions: array of decisions (1=accept, 0=reject)
        """
        beta0, beta1 = params
        p_accept = self._sigmoid(beta0 + beta1 * offers)
        
        # Clip probabilities to avoid log(0)
        eps = 1e-10
        p_accept = np.clip(p_accept, eps, 1 - eps)
        
        # Binary cross-entropy loss
        log_lik = np.sum(decisions * np.log(p_accept) + 
                         (1 - decisions) * np.log(1 - p_accept))
        return -log_lik
    
    def fit(self, offers, decisions):
        """
        Fit the threshold model to data.
        
        Args:
            offers: array of offer proportions (0-1)
            decisions: array of decisions (1=accept, 0=reject)
        """
        offers = np.asarray(offers)
        decisions = np.asarray(decisions)
        
        # Initial parameter guess
        init_params = [0.0, 5.0]  # beta0, beta1
        
        # Optimize
        result = minimize(
            self._neg_log_likelihood,
            init_params,
            args=(offers, decisions),
            method='L-BFGS-B',
            bounds=[(-10, 10), (-50, 50)]
        )
        
        self.params = result.x
        self.fitted = True
        self.log_likelihood = -result.fun
        
        # Calculate AIC and BIC
        n = len(decisions)
        k = len(self.params)
        self.aic = 2 * k - 2 * self.log_likelihood
        self.bic = k * np.log(n) - 2 * self.log_likelihood
        
        return self
    
    def predict_proba(self, offers):
        """Predict acceptance probability."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        return self._sigmoid(self.params[0] + self.params[1] * offers)
    
    def predict(self, offers, threshold=0.5):
        """Predict binary decisions."""
        return (self.predict_proba(offers) >= threshold).astype(int)
    
    def get_threshold(self):
        """
        Get the offer proportion at which P(accept) = 0.5 (decision threshold).
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        return -self.params[0] / self.params[1]
    
    def summary(self):
        """Return model summary."""
        return {
            'model': 'Threshold Model',
            'hypothesis': 'H1: Decisions depend only on current offer',
            'n_params': 2,
            'params': {'beta0': self.params[0], 'beta1': self.params[1]},
            'threshold': self.get_threshold(),
            'log_likelihood': self.log_likelihood,
            'aic': self.aic,
            'bic': self.bic
        }


# ============================================================================
# Model 2: Linear Model with History (Hypothesis 2)
# Decisions depend on both previous and current amounts
# ============================================================================

class LinearHistoryModel:
    """
    Linear model where acceptance depends on current offer and previous offer.
    
    P(accept | offer_t, offer_{t-1}) = sigmoid(beta0 + beta1*offer_t + 
                                                beta2*offer_{t-1} + beta3*diff)
    where diff = offer_t - offer_{t-1} (contrast effect)
    
    Parameters:
    - beta0: intercept
    - beta1: current offer effect
    - beta2: previous offer effect
    - beta3: contrast effect (difference between current and previous)
    """
    
    def __init__(self, include_contrast=True):
        self.params = None
        self.fitted = False
        self.log_likelihood = None
        self.aic = None
        self.bic = None
        self.include_contrast = include_contrast
        
    def _sigmoid(self, x):
        return expit(x)
    
    def _neg_log_likelihood(self, params, X, decisions):
        """
        Compute negative log-likelihood.
        
        Args:
            params: model parameters
            X: design matrix (includes intercept)
            decisions: array of decisions
        """
        linear_pred = X @ params
        p_accept = self._sigmoid(linear_pred)
        
        eps = 1e-10
        p_accept = np.clip(p_accept, eps, 1 - eps)
        
        log_lik = np.sum(decisions * np.log(p_accept) + 
                         (1 - decisions) * np.log(1 - p_accept))
        return -log_lik
    
    def _prepare_features(self, current_offers, prev_offers):
        """Prepare feature matrix."""
        n = len(current_offers)
        if self.include_contrast:
            # Include contrast effect
            contrast = current_offers - prev_offers
            X = np.column_stack([np.ones(n), current_offers, prev_offers, contrast])
        else:
            X = np.column_stack([np.ones(n), current_offers, prev_offers])
        return X
    
    def fit(self, current_offers, prev_offers, decisions):
        """
        Fit the linear history model.
        
        Args:
            current_offers: array of current offer proportions
            prev_offers: array of previous offer proportions
            decisions: array of decisions (1=accept, 0=reject)
        """
        current_offers = np.asarray(current_offers)
        prev_offers = np.asarray(prev_offers)
        decisions = np.asarray(decisions)
        
        X = self._prepare_features(current_offers, prev_offers)
        n_params = X.shape[1]
        
        # Initial parameter guess
        init_params = np.zeros(n_params)
        init_params[1] = 5.0  # current offer effect
        
        # Optimize
        bounds = [(-10, 10)] * n_params
        bounds[1] = (-50, 50)  # wider range for current offer
        
        result = minimize(
            self._neg_log_likelihood,
            init_params,
            args=(X, decisions),
            method='L-BFGS-B',
            bounds=bounds
        )
        
        self.params = result.x
        self.fitted = True
        self.log_likelihood = -result.fun
        
        # Calculate AIC and BIC
        n = len(decisions)
        k = len(self.params)
        self.aic = 2 * k - 2 * self.log_likelihood
        self.bic = k * np.log(n) - 2 * self.log_likelihood
        
        return self
    
    def predict_proba(self, current_offers, prev_offers):
        """Predict acceptance probability."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        current_offers = np.asarray(current_offers)
        prev_offers = np.asarray(prev_offers)
        X = self._prepare_features(current_offers, prev_offers)
        
        return self._sigmoid(X @ self.params)
    
    def predict(self, current_offers, prev_offers, threshold=0.5):
        """Predict binary decisions."""
        return (self.predict_proba(current_offers, prev_offers) >= threshold).astype(int)
    
    def summary(self):
        """Return model summary."""
        if self.include_contrast:
            param_names = ['beta0 (intercept)', 'beta1 (current)', 
                          'beta2 (previous)', 'beta3 (contrast)']
        else:
            param_names = ['beta0 (intercept)', 'beta1 (current)', 'beta2 (previous)']
        
        params_dict = dict(zip(param_names, self.params))
        
        return {
            'model': 'Linear History Model',
            'hypothesis': 'H2: Decisions depend on current and previous offers',
            'n_params': len(self.params),
            'params': params_dict,
            'log_likelihood': self.log_likelihood,
            'aic': self.aic,
            'bic': self.bic
        }


# ============================================================================
# Model 3: Bayesian Decision Model (Hypothesis 2)
# Adaptive threshold based on prior beliefs
# ============================================================================

class BayesianDecisionModel:
    """
    Bayesian decision model where the acceptance threshold is updated based on
    prior experience with offers.
    
    The model maintains a belief about the expected offer distribution and 
    adjusts the acceptance threshold based on the difference between the 
    current offer and the expected value.
    
    P(accept) = sigmoid(beta0 + beta1 * (offer - expected_offer) + beta2 * offer)
    
    Parameters:
    - beta0: baseline acceptance bias
    - beta1: sensitivity to deviation from expectation
    - beta2: direct effect of offer value
    - alpha: learning rate for belief updating (0 < alpha < 1)
    """
    
    def __init__(self, learning_rate=0.2):
        self.params = None
        self.learning_rate = learning_rate
        self.fitted = False
        self.log_likelihood = None
        self.aic = None
        self.bic = None
        
    def _sigmoid(self, x):
        return expit(x)
    
    def _compute_expectations(self, offers):
        """
        Compute running expected values using exponential moving average.
        """
        n = len(offers)
        expectations = np.zeros(n)
        # Initial expectation is the fair split (0.5)
        expectations[0] = 0.5
        
        for t in range(1, n):
            expectations[t] = ((1 - self.learning_rate) * expectations[t-1] + 
                              self.learning_rate * offers[t-1])
        
        return expectations
    
    def _neg_log_likelihood(self, params, offers, decisions):
        """
        Compute negative log-likelihood for the Bayesian model.
        """
        beta0, beta1, beta2 = params
        
        expectations = self._compute_expectations(offers)
        deviations = offers - expectations
        
        linear_pred = beta0 + beta1 * deviations + beta2 * offers
        p_accept = self._sigmoid(linear_pred)
        
        eps = 1e-10
        p_accept = np.clip(p_accept, eps, 1 - eps)
        
        log_lik = np.sum(decisions * np.log(p_accept) + 
                         (1 - decisions) * np.log(1 - p_accept))
        return -log_lik
    
    def _neg_log_likelihood_with_alpha(self, params, offers, decisions):
        """
        Compute negative log-likelihood with alpha as a parameter.
        """
        beta0, beta1, beta2, alpha = params
        self.learning_rate = alpha
        return self._neg_log_likelihood([beta0, beta1, beta2], offers, decisions)
    
    def fit(self, offers, decisions, estimate_learning_rate=False):
        """
        Fit the Bayesian decision model.
        
        Args:
            offers: array of offer proportions
            decisions: array of decisions
            estimate_learning_rate: if True, also estimates the learning rate
        """
        offers = np.asarray(offers)
        decisions = np.asarray(decisions)
        
        if estimate_learning_rate:
            init_params = [0.0, 2.0, 5.0, 0.2]
            bounds = [(-10, 10), (-50, 50), (-50, 50), (0.01, 0.99)]
            
            result = minimize(
                self._neg_log_likelihood_with_alpha,
                init_params,
                args=(offers, decisions),
                method='L-BFGS-B',
                bounds=bounds
            )
            
            self.params = result.x[:3]
            self.learning_rate = result.x[3]
            n_params = 4
        else:
            init_params = [0.0, 2.0, 5.0]
            bounds = [(-10, 10), (-50, 50), (-50, 50)]
            
            result = minimize(
                self._neg_log_likelihood,
                init_params,
                args=(offers, decisions),
                method='L-BFGS-B',
                bounds=bounds
            )
            
            self.params = result.x
            n_params = 3
        
        self.fitted = True
        self.log_likelihood = -result.fun
        
        n = len(decisions)
        k = n_params
        self.aic = 2 * k - 2 * self.log_likelihood
        self.bic = k * np.log(n) - 2 * self.log_likelihood
        
        return self
    
    def predict_proba(self, offers):
        """Predict acceptance probability."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        expectations = self._compute_expectations(offers)
        deviations = offers - expectations
        
        linear_pred = self.params[0] + self.params[1] * deviations + self.params[2] * offers
        return self._sigmoid(linear_pred)
    
    def predict(self, offers, threshold=0.5):
        """Predict binary decisions."""
        return (self.predict_proba(offers) >= threshold).astype(int)
    
    def summary(self):
        """Return model summary."""
        return {
            'model': 'Bayesian Decision Model',
            'hypothesis': 'H2: Decisions based on belief updating',
            'n_params': 3 + (1 if hasattr(self, '_estimate_lr') else 0),
            'params': {
                'beta0 (baseline)': self.params[0],
                'beta1 (expectation deviation)': self.params[1],
                'beta2 (offer value)': self.params[2],
                'learning_rate': self.learning_rate
            },
            'log_likelihood': self.log_likelihood,
            'aic': self.aic,
            'bic': self.bic
        }


# ============================================================================
# Model 4: Reinforcement Learning + Bayesian Model (Hypothesis 2+)
# Reward-Punishment framework with Bayesian belief updating
# ============================================================================

class ReinforcementLearningBayesianModel:
    """
    Reinforcement Learning model combined with Bayesian belief updating.
    
    This model treats the UG decision as a risk-decision task where:
    - Accepting an offer provides REWARD (monetary gain)
    - Accepting also incurs PUNISHMENT (violating internal fairness norm)
    - Punishment DECREASES as offer amount INCREASES (unfair offers hurt more)
    - The expected offer is updated through Bayesian learning
    
    The utility of accepting is:
        U(accept) = reward - punishment
        reward = w_r * offer
        punishment = w_p * exp(-gamma * offer)  # decreases with higher offers
    
    The utility of rejecting is:
        U(reject) = 0  # neither reward nor punishment
    
    Decision probability:
        P(accept) = sigmoid(beta * (U(accept) - U(reject) + bias + 
                                    lambda * (offer - expected_offer)))
    
    Parameters:
    - w_r: reward weight (sensitivity to monetary reward)
    - w_p: punishment weight (sensitivity to fairness violation)
    - gamma: punishment decay rate (how fast punishment decreases with offer)
    - beta: inverse temperature (decision consistency)
    - bias: baseline acceptance bias
    - lambda: Bayesian expectation effect
    - alpha: learning rate for belief updating
    """
    
    def __init__(self, learning_rate=0.2):
        self.params = None
        self.learning_rate = learning_rate
        self.fitted = False
        self.log_likelihood = None
        self.aic = None
        self.bic = None
        
    def _sigmoid(self, x):
        return expit(x)
    
    def _compute_expectations(self, offers):
        """
        Compute running expected values using exponential moving average (Bayesian updating).
        """
        n = len(offers)
        expectations = np.zeros(n)
        expectations[0] = 0.5  # Initial expectation: fair split
        
        for t in range(1, n):
            expectations[t] = ((1 - self.learning_rate) * expectations[t-1] + 
                              self.learning_rate * offers[t-1])
        
        return expectations
    
    def _compute_utility(self, offer, w_r, w_p, gamma):
        """
        Compute utility of accepting an offer.
        
        U(accept) = reward - punishment
        where:
            reward = w_r * offer  (higher offer = more reward)
            punishment = w_p * exp(-gamma * offer)  (higher offer = less punishment)
        
        Args:
            offer: offer proportion (0-1)
            w_r: reward weight
            w_p: punishment weight
            gamma: punishment decay rate
        
        Returns:
            utility of accepting
        """
        reward = w_r * offer
        punishment = w_p * np.exp(-gamma * offer)
        return reward - punishment
    
    def _neg_log_likelihood(self, params, offers, decisions):
        """
        Compute negative log-likelihood for the RL-Bayesian model.
        
        Args:
            params: [w_r, w_p, gamma, beta, bias, lambda_exp, alpha]
            offers: array of offer proportions
            decisions: array of decisions (1=accept, 0=reject)
        """
        w_r, w_p, gamma, beta, bias, lambda_exp, alpha = params
        self.learning_rate = alpha
        
        expectations = self._compute_expectations(offers)
        
        # Compute utilities for each trial
        utilities = self._compute_utility(offers, w_r, w_p, gamma)
        
        # Bayesian expectation effect: surprise when offer differs from expectation
        expectation_effect = lambda_exp * (offers - expectations)
        
        # Decision value (utility + bias + expectation effect)
        decision_values = beta * utilities + bias + expectation_effect
        
        # P(accept)
        p_accept = self._sigmoid(decision_values)
        
        eps = 1e-10
        p_accept = np.clip(p_accept, eps, 1 - eps)
        
        log_lik = np.sum(decisions * np.log(p_accept) + 
                         (1 - decisions) * np.log(1 - p_accept))
        return -log_lik
    
    def fit(self, offers, decisions):
        """
        Fit the RL-Bayesian model to data.
        
        Args:
            offers: array of offer proportions (0-1)
            decisions: array of decisions (1=accept, 0=reject)
        """
        offers = np.asarray(offers)
        decisions = np.asarray(decisions)
        
        # Initial parameters: [w_r, w_p, gamma, beta, bias, lambda_exp, alpha]
        init_params = [5.0, 2.0, 3.0, 1.0, 0.0, 2.0, 0.2]
        
        # Bounds
        bounds = [
            (0.1, 20.0),    # w_r: reward weight (positive)
            (0.1, 20.0),    # w_p: punishment weight (positive)
            (0.1, 20.0),    # gamma: punishment decay rate (positive)
            (0.1, 10.0),    # beta: inverse temperature (positive)
            (-5.0, 5.0),    # bias: can be negative or positive
            (-20.0, 20.0),  # lambda_exp: expectation effect
            (0.01, 0.99)    # alpha: learning rate
        ]
        
        # Multiple random restarts
        best_result = None
        best_nll = np.inf
        
        for restart in range(5):
            # Random initialization
            init = np.array(init_params) + np.random.randn(len(init_params)) * 0.5
            # Clip to bounds
            for i, (lb, ub) in enumerate(bounds):
                init[i] = np.clip(init[i], lb, ub)
            
            try:
                result = minimize(
                    self._neg_log_likelihood,
                    init,
                    args=(offers, decisions),
                    method='L-BFGS-B',
                    bounds=bounds,
                    options={'maxiter': 1000}
                )
                
                if result.fun < best_nll:
                    best_nll = result.fun
                    best_result = result
            except:
                continue
        
        if best_result is None:
            raise ValueError("RL-Bayesian model fitting failed")
        
        self.params = best_result.x
        self.learning_rate = self.params[6]
        self.fitted = True
        self.log_likelihood = -best_result.fun
        
        # Calculate AIC and BIC
        n = len(decisions)
        k = len(self.params)
        self.aic = 2 * k - 2 * self.log_likelihood
        self.bic = k * np.log(n) - 2 * self.log_likelihood
        
        return self
    
    def predict_proba(self, offers):
        """Predict acceptance probability."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        w_r, w_p, gamma, beta, bias, lambda_exp, alpha = self.params
        
        expectations = self._compute_expectations(offers)
        utilities = self._compute_utility(offers, w_r, w_p, gamma)
        expectation_effect = lambda_exp * (offers - expectations)
        decision_values = beta * utilities + bias + expectation_effect
        
        return self._sigmoid(decision_values)
    
    def predict(self, offers, threshold=0.5):
        """Predict binary decisions."""
        return (self.predict_proba(offers) >= threshold).astype(int)
    
    def get_utility_components(self, offers):
        """
        Decompose utility into reward and punishment components.
        
        Useful for understanding model behavior and visualization.
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        w_r, w_p, gamma = self.params[:3]
        
        rewards = w_r * offers
        punishments = w_p * np.exp(-gamma * offers)
        utilities = rewards - punishments
        
        return {
            'offers': offers,
            'rewards': rewards,
            'punishments': punishments,
            'utilities': utilities
        }
    
    def get_indifference_point(self):
        """
        Find the offer proportion where utility = 0 (indifference point).
        This is where reward equals punishment.
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        w_r, w_p, gamma = self.params[:3]
        
        # Solve: w_r * offer = w_p * exp(-gamma * offer)
        # This requires numerical solution
        from scipy.optimize import brentq
        
        def utility_zero(offer):
            return w_r * offer - w_p * np.exp(-gamma * offer)
        
        try:
            # Search for root in [0.01, 0.99]
            indiff_point = brentq(utility_zero, 0.01, 0.99)
            return indiff_point
        except ValueError:
            # No root in the range
            return None
    
    def summary(self):
        """Return model summary."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        indiff_point = self.get_indifference_point()
        
        return {
            'model': 'Reinforcement Learning + Bayesian Model',
            'hypothesis': 'H2+: RL reward-punishment with Bayesian updating',
            'n_params': len(self.params),
            'params': {
                'w_r (reward weight)': self.params[0],
                'w_p (punishment weight)': self.params[1],
                'gamma (punishment decay)': self.params[2],
                'beta (inverse temperature)': self.params[3],
                'bias': self.params[4],
                'lambda (expectation effect)': self.params[5],
                'alpha (learning rate)': self.params[6]
            },
            'indifference_point': indiff_point,
            'log_likelihood': self.log_likelihood,
            'aic': self.aic,
            'bic': self.bic
        }


# ============================================================================
# Model 5: Bayesian Utility Model (Formal Bayesian Framework)
# Value-Risk Tradeoff with Power Utility Functions and Proper Priors
# ============================================================================

class BayesianUtilityModel:
    """
    Formal Bayesian Utility Model for accept/reject decisions.
    
    This model implements a complete Bayesian framework for value-risk tradeoff
    decisions in the Ultimatum Game, following the formal specification:
    
    Net Value Calculation:
        V(r) = u(r) - v(c(r))
        where:
            u(r) = r^α          (power utility for reward, α = reward sensitivity)
            v(c) = λ * c^β      (power disutility for punishment)
            c(r) = c0 * exp(-γ*r)  (punishment decreases with offer)
    
    Choice Probability (Logistic):
        P(accept | r) = 1 / (1 + exp(-(V(r) - θ) / σ))
        where:
            θ: decision threshold
            σ: decision noise (inverse temperature)
    
    Prior Distributions:
        α ~ Lognormal(0, 0.5)       (reward sensitivity, centered at 1)
        λ ~ Lognormal(0, 0.5)       (loss aversion, centered at 1)
        β ~ Gamma(2, 1)             (punishment sensitivity)
        γ ~ Gamma(2, 1)             (punishment decay rate)
        θ ~ Normal(0, 2)            (decision threshold)
        σ ~ HalfNormal(1)           (decision noise)
        c0 ~ Gamma(2, 1)            (baseline punishment)
    
    Parameters:
    - alpha (α): reward sensitivity (α<1: risk averse, α>1: risk seeking)
    - lambda_ (λ): loss aversion coefficient (λ>1: loss averse)
    - beta (β): punishment sensitivity
    - gamma (γ): punishment decay rate
    - theta (θ): decision threshold
    - sigma (σ): decision noise
    - c0: baseline punishment level
    """
    
    def __init__(self):
        self.params = None
        self.fitted = False
        self.log_likelihood = None
        self.aic = None
        self.bic = None
        self.prior_log_prob = None
        self.posterior_log_prob = None
        
    def _sigmoid(self, x):
        return expit(x)
    
    def _utility_reward(self, offer, alpha):
        """
        Power utility function for reward.
        u(r) = r^α
        """
        # Ensure numerical stability for small offers
        offer = np.clip(offer, 1e-10, 1.0)
        return np.power(offer, alpha)
    
    def _punishment_function(self, offer, c0, gamma):
        """
        Punishment as a function of offer (decreases with higher offers).
        c(r) = c0 * exp(-γ * r)
        """
        return c0 * np.exp(-gamma * offer)
    
    def _disutility_punishment(self, punishment, lambda_, beta):
        """
        Power disutility function for punishment.
        v(c) = λ * c^β
        """
        punishment = np.clip(punishment, 1e-10, 100.0)
        return lambda_ * np.power(punishment, beta)
    
    def _net_value(self, offer, alpha, lambda_, beta, gamma, c0):
        """
        Compute net subjective value.
        V(r) = u(r) - v(c(r))
        """
        u_reward = self._utility_reward(offer, alpha)
        punishment = self._punishment_function(offer, c0, gamma)
        v_punishment = self._disutility_punishment(punishment, lambda_, beta)
        return u_reward - v_punishment
    
    def _log_prior(self, params):
        """
        Compute log prior probability for all parameters.
        
        Prior distributions:
        - α ~ Lognormal(0, 0.5)
        - λ ~ Lognormal(0, 0.5)
        - β ~ Gamma(2, 1)
        - γ ~ Gamma(2, 1)
        - θ ~ Normal(0, 2)
        - σ ~ HalfNormal(1)
        - c0 ~ Gamma(2, 1)
        """
        alpha, lambda_, beta, gamma, theta, sigma, c0 = params
        
        log_prior = 0.0
        
        # α ~ Lognormal(0, 0.5)
        if alpha > 0:
            log_prior += stats.lognorm.logpdf(alpha, s=0.5, scale=np.exp(0))
        else:
            return -np.inf
        
        # λ ~ Lognormal(0, 0.5)
        if lambda_ > 0:
            log_prior += stats.lognorm.logpdf(lambda_, s=0.5, scale=np.exp(0))
        else:
            return -np.inf
        
        # β ~ Gamma(2, 1)
        if beta > 0:
            log_prior += stats.gamma.logpdf(beta, a=2, scale=1)
        else:
            return -np.inf
        
        # γ ~ Gamma(2, 1)
        if gamma > 0:
            log_prior += stats.gamma.logpdf(gamma, a=2, scale=1)
        else:
            return -np.inf
        
        # θ ~ Normal(0, 2)
        log_prior += stats.norm.logpdf(theta, loc=0, scale=2)
        
        # σ ~ HalfNormal(1)
        if sigma > 0:
            log_prior += stats.halfnorm.logpdf(sigma, scale=1)
        else:
            return -np.inf
        
        # c0 ~ Gamma(2, 1)
        if c0 > 0:
            log_prior += stats.gamma.logpdf(c0, a=2, scale=1)
        else:
            return -np.inf
        
        return log_prior
    
    def _log_likelihood(self, params, offers, decisions):
        """
        Compute log-likelihood for the Bayesian Utility model.
        
        P(y=1|r) = 1 / (1 + exp(-(V(r) - θ) / σ))
        """
        alpha, lambda_, beta, gamma, theta, sigma, c0 = params
        
        # Compute net values
        net_values = self._net_value(offers, alpha, lambda_, beta, gamma, c0)
        
        # Decision probability
        decision_values = (net_values - theta) / sigma
        p_accept = self._sigmoid(decision_values)
        
        # Clip probabilities
        eps = 1e-10
        p_accept = np.clip(p_accept, eps, 1 - eps)
        
        # Log-likelihood
        log_lik = np.sum(decisions * np.log(p_accept) + 
                         (1 - decisions) * np.log(1 - p_accept))
        
        return log_lik
    
    def _neg_log_posterior(self, params, offers, decisions):
        """
        Compute negative log posterior (for MAP estimation).
        log P(θ|y,r) ∝ log P(y|r,θ) + log P(θ)
        """
        log_prior = self._log_prior(params)
        
        if np.isinf(log_prior):
            return np.inf
        
        log_lik = self._log_likelihood(params, offers, decisions)
        
        if np.isnan(log_lik) or np.isinf(log_lik):
            return np.inf
        
        return -(log_prior + log_lik)
    
    def _neg_log_likelihood_only(self, params, offers, decisions):
        """Compute negative log-likelihood (for MLE estimation)."""
        log_lik = self._log_likelihood(params, offers, decisions)
        if np.isnan(log_lik) or np.isinf(log_lik):
            return np.inf
        return -log_lik
    
    def fit(self, offers, decisions, method='MAP'):
        """
        Fit the Bayesian Utility model to data.
        
        Args:
            offers: array of offer proportions (0-1)
            decisions: array of decisions (1=accept, 0=reject)
            method: 'MAP' for Maximum A Posteriori or 'MLE' for Maximum Likelihood
        
        Returns:
            self
        """
        offers = np.asarray(offers)
        decisions = np.asarray(decisions)
        
        # Initial parameters: [alpha, lambda_, beta, gamma, theta, sigma, c0]
        init_params = [1.0, 1.0, 1.0, 3.0, 0.0, 1.0, 2.0]
        
        # Bounds (ensure positivity where needed)
        bounds = [
            (0.1, 3.0),     # alpha: reward sensitivity
            (0.1, 5.0),     # lambda_: loss aversion
            (0.1, 5.0),     # beta: punishment sensitivity
            (0.1, 10.0),    # gamma: punishment decay
            (-5.0, 5.0),    # theta: decision threshold
            (0.1, 5.0),     # sigma: decision noise
            (0.1, 10.0)     # c0: baseline punishment
        ]
        
        # Choose objective function
        if method == 'MAP':
            obj_func = self._neg_log_posterior
        else:
            obj_func = self._neg_log_likelihood_only
        
        # Multiple random restarts
        best_result = None
        best_obj = np.inf
        
        for restart in range(5):
            # Random initialization around prior modes
            init = np.array([
                np.random.lognormal(0, 0.3),      # alpha
                np.random.lognormal(0, 0.3),      # lambda_
                np.random.gamma(2, 0.5),          # beta
                np.random.gamma(2, 0.5),          # gamma
                np.random.normal(0, 1),           # theta
                np.abs(np.random.normal(0, 0.5)) + 0.1,  # sigma
                np.random.gamma(2, 0.5)           # c0
            ])
            
            # Clip to bounds
            for i, (lb, ub) in enumerate(bounds):
                init[i] = np.clip(init[i], lb, ub)
            
            try:
                result = minimize(
                    obj_func,
                    init,
                    args=(offers, decisions),
                    method='L-BFGS-B',
                    bounds=bounds,
                    options={'maxiter': 1000}
                )
                
                if result.fun < best_obj:
                    best_obj = result.fun
                    best_result = result
            except:
                continue
        
        if best_result is None:
            raise ValueError("Bayesian Utility model fitting failed")
        
        self.params = best_result.x
        self.fitted = True
        
        # Compute log-likelihood (for AIC/BIC)
        self.log_likelihood = self._log_likelihood(self.params, offers, decisions)
        self.prior_log_prob = self._log_prior(self.params)
        self.posterior_log_prob = self.log_likelihood + self.prior_log_prob
        
        # Calculate AIC and BIC
        n = len(decisions)
        k = len(self.params)
        self.aic = 2 * k - 2 * self.log_likelihood
        self.bic = k * np.log(n) - 2 * self.log_likelihood
        
        return self
    
    def predict_proba(self, offers):
        """Predict acceptance probability."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        alpha, lambda_, beta, gamma, theta, sigma, c0 = self.params
        
        net_values = self._net_value(offers, alpha, lambda_, beta, gamma, c0)
        decision_values = (net_values - theta) / sigma
        
        return self._sigmoid(decision_values)
    
    def predict(self, offers, threshold=0.5):
        """Predict binary decisions."""
        return (self.predict_proba(offers) >= threshold).astype(int)
    
    def get_value_decomposition(self, offers):
        """
        Decompose net value into utility and disutility components.
        
        Useful for understanding model behavior and visualization.
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        alpha, lambda_, beta, gamma, theta, sigma, c0 = self.params
        
        u_rewards = self._utility_reward(offers, alpha)
        punishments = self._punishment_function(offers, c0, gamma)
        v_punishments = self._disutility_punishment(punishments, lambda_, beta)
        net_values = u_rewards - v_punishments
        
        return {
            'offers': offers,
            'u_reward': u_rewards,
            'punishment': punishments,
            'v_punishment': v_punishments,
            'net_value': net_values
        }
    
    def get_indifference_point(self):
        """
        Find the offer proportion where V(r) = θ (decision threshold).
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        alpha, lambda_, beta, gamma, theta, sigma, c0 = self.params
        
        from scipy.optimize import brentq
        
        def value_at_threshold(offer):
            return self._net_value(offer, alpha, lambda_, beta, gamma, c0) - theta
        
        try:
            indiff_point = brentq(value_at_threshold, 0.01, 0.99)
            return indiff_point
        except ValueError:
            return None
    
    def get_risk_attitude(self):
        """
        Determine risk attitude based on reward sensitivity parameter.
        
        α < 1: Risk averse (concave utility)
        α = 1: Risk neutral (linear utility)
        α > 1: Risk seeking (convex utility)
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        alpha = self.params[0]
        
        if alpha < 0.9:
            return 'risk_averse'
        elif alpha > 1.1:
            return 'risk_seeking'
        else:
            return 'risk_neutral'
    
    def get_loss_aversion(self):
        """
        Determine loss aversion level.
        
        λ > 1: Loss averse (punishment weighted more than reward)
        λ = 1: No loss aversion
        λ < 1: Gain seeking (reward weighted more)
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        lambda_ = self.params[1]
        
        if lambda_ > 1.1:
            return 'loss_averse'
        elif lambda_ < 0.9:
            return 'gain_seeking'
        else:
            return 'neutral'
    
    def summary(self):
        """Return model summary."""
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        indiff_point = self.get_indifference_point()
        risk_attitude = self.get_risk_attitude()
        loss_aversion = self.get_loss_aversion()
        
        return {
            'model': 'Bayesian Utility Model',
            'hypothesis': 'H2++: Formal Bayesian value-risk tradeoff',
            'n_params': len(self.params),
            'params': {
                'α (reward sensitivity)': self.params[0],
                'λ (loss aversion)': self.params[1],
                'β (punishment sensitivity)': self.params[2],
                'γ (punishment decay)': self.params[3],
                'θ (decision threshold)': self.params[4],
                'σ (decision noise)': self.params[5],
                'c0 (baseline punishment)': self.params[6]
            },
            'interpretation': {
                'risk_attitude': risk_attitude,
                'loss_aversion': loss_aversion,
                'indifference_point': indiff_point
            },
            'log_likelihood': self.log_likelihood,
            'prior_log_prob': self.prior_log_prob,
            'posterior_log_prob': self.posterior_log_prob,
            'aic': self.aic,
            'bic': self.bic
        }


# ============================================================================
# Model 6: Hidden Markov Model (Hypothesis 3)
# State-based decision model with decision history influence
# ============================================================================

class HiddenMarkovModel:
    """
    Hidden Markov Model for sequential decision-making.
    
    The model assumes subjects can be in one of two latent states:
    - State 0: "Strict" state (lower acceptance probability)
    - State 1: "Lenient" state (higher acceptance probability)
    
    Transition probabilities depend on the previous decision (accept/reject).
    Emission probabilities (acceptance) depend on the current offer and state.
    
    This model tests Hypothesis 3: decisions depend on current/previous amounts
    AND previous decisions.
    
    Parameters:
    - pi: initial state distribution [p(s0), p(s1)]
    - A: transition matrix (2x2x2) - depends on previous decision
      A[prev_decision, s_prev, s_curr] = P(s_curr | s_prev, prev_decision)
    - beta0_s, beta1_s: emission parameters for each state
    """
    
    def __init__(self, n_states=2):
        self.n_states = n_states
        self.params = None
        self.fitted = False
        self.log_likelihood = None
        self.aic = None
        self.bic = None
        
    def _sigmoid(self, x):
        return expit(x)
    
    def _unpack_params(self, params):
        """
        Unpack flat parameter vector into model components.
        
        Parameters (12 total for 2 states):
        - pi[1]: probability of starting in state 1 (pi[0] = 1 - pi[1])
        - A parameters: 4 transition probabilities conditioned on prev decision
          - A_accept[0,1]: P(s=1 | s=0, prev=accept)
          - A_accept[1,1]: P(s=1 | s=1, prev=accept)
          - A_reject[0,1]: P(s=1 | s=0, prev=reject)
          - A_reject[1,1]: P(s=1 | s=1, prev=reject)
        - beta0[0], beta1[0]: emission params for state 0
        - beta0[1], beta1[1]: emission params for state 1
        """
        pi = np.array([1 - params[0], params[0]])  # initial state dist
        
        # Transition matrices (conditioned on previous decision)
        A = np.zeros((2, 2, 2))  # [prev_decision, s_from, s_to]
        
        # Given previous accept
        A[1, 0, 0] = 1 - params[1]  # s0 -> s0
        A[1, 0, 1] = params[1]       # s0 -> s1
        A[1, 1, 0] = 1 - params[2]  # s1 -> s0
        A[1, 1, 1] = params[2]       # s1 -> s1
        
        # Given previous reject
        A[0, 0, 0] = 1 - params[3]  # s0 -> s0
        A[0, 0, 1] = params[3]       # s0 -> s1
        A[0, 1, 0] = 1 - params[4]  # s1 -> s0
        A[0, 1, 1] = params[4]       # s1 -> s1
        
        # Emission parameters for each state
        beta0 = np.array([params[5], params[7]])  # intercepts
        beta1 = np.array([params[6], params[8]])  # slopes
        
        return pi, A, beta0, beta1
    
    def _emission_prob(self, offer, state, beta0, beta1):
        """
        P(decision=accept | offer, state)
        """
        return self._sigmoid(beta0[state] + beta1[state] * offer)
    
    def _forward_algorithm(self, offers, decisions, params):
        """
        Forward algorithm for HMM.
        
        Returns log-likelihood of the sequence.
        """
        pi, A, beta0, beta1 = self._unpack_params(params)
        n = len(offers)
        
        # Forward variables: alpha[t, s] = P(obs_1:t, s_t = s)
        alpha = np.zeros((n, self.n_states))
        
        # Initialize
        for s in range(self.n_states):
            p_emit = self._emission_prob(offers[0], s, beta0, beta1)
            if decisions[0] == 1:
                p_obs = p_emit
            else:
                p_obs = 1 - p_emit
            alpha[0, s] = pi[s] * p_obs
        
        # Rescale to avoid underflow
        scale = np.zeros(n)
        scale[0] = np.sum(alpha[0])
        if scale[0] > 0:
            alpha[0] /= scale[0]
        else:
            scale[0] = 1e-300
        
        # Forward pass
        for t in range(1, n):
            prev_decision = decisions[t-1]
            trans_matrix = A[prev_decision]
            
            for s in range(self.n_states):
                p_emit = self._emission_prob(offers[t], s, beta0, beta1)
                if decisions[t] == 1:
                    p_obs = p_emit
                else:
                    p_obs = 1 - p_emit
                
                # Sum over previous states
                alpha[t, s] = np.sum(alpha[t-1] * trans_matrix[:, s]) * p_obs
            
            # Rescale
            scale[t] = np.sum(alpha[t])
            if scale[t] > 0:
                alpha[t] /= scale[t]
            else:
                scale[t] = 1e-300
        
        # Log-likelihood
        log_lik = np.sum(np.log(scale))
        
        return log_lik
    
    def _neg_log_likelihood(self, params, offers, decisions):
        """Compute negative log-likelihood."""
        try:
            log_lik = self._forward_algorithm(offers, decisions, params)
            if np.isnan(log_lik) or np.isinf(log_lik):
                return 1e10
            return -log_lik
        except:
            return 1e10
    
    def fit(self, offers, decisions):
        """
        Fit the HMM to data.
        
        Args:
            offers: array of offer proportions
            decisions: array of decisions (1=accept, 0=reject)
        """
        offers = np.asarray(offers)
        decisions = np.asarray(decisions)
        
        # Parameters: [pi[1], A_accept[0,1], A_accept[1,1], A_reject[0,1], A_reject[1,1],
        #              beta0[0], beta1[0], beta0[1], beta1[1]]
        # Total: 9 parameters
        
        init_params = [
            0.5,      # pi[1]
            0.3,      # A_accept[0,1] 
            0.7,      # A_accept[1,1]
            0.5,      # A_reject[0,1]
            0.5,      # A_reject[1,1]
            -2.0,     # beta0[0] (strict state)
            8.0,      # beta1[0]
            2.0,      # beta0[1] (lenient state)
            4.0       # beta1[1]
        ]
        
        bounds = [
            (0.01, 0.99),   # pi[1]
            (0.01, 0.99),   # A_accept[0,1]
            (0.01, 0.99),   # A_accept[1,1]
            (0.01, 0.99),   # A_reject[0,1]
            (0.01, 0.99),   # A_reject[1,1]
            (-10, 10),      # beta0[0]
            (-50, 50),      # beta1[0]
            (-10, 10),      # beta0[1]
            (-50, 50)       # beta1[1]
        ]
        
        # Multiple random restarts
        best_result = None
        best_nll = np.inf
        
        for _ in range(5):
            # Random initialization
            init = np.array(init_params) + np.random.randn(len(init_params)) * 0.5
            # Clip to bounds
            for i, (lb, ub) in enumerate(bounds):
                init[i] = np.clip(init[i], lb, ub)
            
            try:
                result = minimize(
                    self._neg_log_likelihood,
                    init,
                    args=(offers, decisions),
                    method='L-BFGS-B',
                    bounds=bounds,
                    options={'maxiter': 1000}
                )
                
                if result.fun < best_nll:
                    best_nll = result.fun
                    best_result = result
            except:
                continue
        
        if best_result is None:
            raise ValueError("HMM fitting failed")
        
        self.params = best_result.x
        self.fitted = True
        self.log_likelihood = -best_result.fun
        
        # Calculate AIC and BIC
        n = len(decisions)
        k = len(self.params)
        self.aic = 2 * k - 2 * self.log_likelihood
        self.bic = k * np.log(n) - 2 * self.log_likelihood
        
        return self
    
    def predict_proba(self, offers, prev_decisions=None):
        """
        Predict acceptance probability using most likely state sequence.
        
        Note: This is an approximation. For proper inference, use Viterbi algorithm.
        """
        if not self.fitted:
            raise ValueError("Model not fitted yet.")
        
        offers = np.asarray(offers)
        n = len(offers)
        
        if prev_decisions is None:
            prev_decisions = np.zeros(n, dtype=int)
        
        pi, A, beta0, beta1 = self._unpack_params(self.params)
        
        # Use most likely state at each time step
        probs = np.zeros(n)
        state_probs = pi.copy()
        
        for t in range(n):
            # Weighted average over states
            for s in range(self.n_states):
                probs[t] += state_probs[s] * self._emission_prob(offers[t], s, beta0, beta1)
            
            if t < n - 1:
                # Update state probabilities
                prev_dec = prev_decisions[t]
                trans_matrix = A[prev_dec]
                state_probs = state_probs @ trans_matrix
        
        return probs
    
    def summary(self):
        """Return model summary."""
        pi, A, beta0, beta1 = self._unpack_params(self.params)
        
        return {
            'model': 'Hidden Markov Model',
            'hypothesis': 'H3: Decisions depend on offers AND previous decisions',
            'n_params': len(self.params),
            'params': {
                'pi (initial state)': pi.tolist(),
                'A_accept (transition given accept)': A[1].tolist(),
                'A_reject (transition given reject)': A[0].tolist(),
                'beta0 (intercepts)': beta0.tolist(),
                'beta1 (slopes)': beta1.tolist()
            },
            'log_likelihood': self.log_likelihood,
            'aic': self.aic,
            'bic': self.bic
        }


# ============================================================================
# Model Comparison Functions
# ============================================================================

def compare_models(offers, decisions, prev_offers=None, verbose=True):
    """
    Fit all models and compare them using AIC/BIC.
    
    Args:
        offers: array of offer proportions (for current trial)
        decisions: array of decisions (1=accept, 0=reject)
        prev_offers: array of previous offer proportions (optional, will be computed if not provided)
        verbose: print comparison results
    
    Returns:
        dict containing fitted models and comparison results
    """
    offers = np.asarray(offers)
    decisions = np.asarray(decisions)
    
    if prev_offers is None and len(offers) > 1:
        # Use lagged offers as previous offers
        prev_offers = np.concatenate([[offers[0]], offers[:-1]])
    else:
        prev_offers = np.asarray(prev_offers) if prev_offers is not None else offers
    
    results = {}
    
    # Model 1: Threshold Model
    if verbose:
        print("Fitting Threshold Model (H1)...")
    m1 = ThresholdModel()
    m1.fit(offers, decisions)
    results['threshold'] = m1
    
    # Model 2a: Linear Model with History
    if verbose:
        print("Fitting Linear History Model (H2)...")
    # Skip first trial since we need previous offer
    m2 = LinearHistoryModel(include_contrast=True)
    m2.fit(offers[1:], prev_offers[1:], decisions[1:])
    results['linear_history'] = m2
    
    # Model 2b: Bayesian Decision Model
    if verbose:
        print("Fitting Bayesian Decision Model (H2)...")
    m3 = BayesianDecisionModel(learning_rate=0.2)
    m3.fit(offers, decisions, estimate_learning_rate=True)
    results['bayesian'] = m3
    
    # Model 3: Hidden Markov Model
    if verbose:
        print("Fitting Hidden Markov Model (H3)...")
    m4 = HiddenMarkovModel(n_states=2)
    m4.fit(offers, decisions)
    results['hmm'] = m4
    
    # Model 4: Reinforcement Learning + Bayesian Model
    if verbose:
        print("Fitting RL-Bayesian Model (H2+)...")
    m5 = ReinforcementLearningBayesianModel(learning_rate=0.2)
    m5.fit(offers, decisions)
    results['rl_bayesian'] = m5
    
    # Model 5: Bayesian Utility Model (formal Bayesian framework)
    if verbose:
        print("Fitting Bayesian Utility Model (H2++)...")
    m6 = BayesianUtilityModel()
    m6.fit(offers, decisions, method='MAP')
    results['bayesian_utility'] = m6
    
    # Comparison
    all_models = [m1, m2, m3, m4, m5, m6]
    model_names = ['Threshold (H1)', 'Linear History (H2)', 'Bayesian (H2)', 'HMM (H3)', 
                   'RL-Bayesian (H2+)', 'Bayesian Utility (H2++)']
    hypotheses = ['H1', 'H2', 'H2', 'H3', 'H2+', 'H2++']
    
    comparison = pd.DataFrame({
        'Model': model_names,
        'Hypothesis': hypotheses,
        'N_Params': [m.summary()['n_params'] for m in all_models],
        'Log_Likelihood': [m.log_likelihood for m in all_models],
        'AIC': [m.aic for m in all_models],
        'BIC': [m.bic for m in all_models]
    })
    
    # Compute delta AIC/BIC
    comparison['Delta_AIC'] = comparison['AIC'] - comparison['AIC'].min()
    comparison['Delta_BIC'] = comparison['BIC'] - comparison['BIC'].min()
    
    # AIC weights
    comparison['AIC_Weight'] = np.exp(-0.5 * comparison['Delta_AIC'])
    comparison['AIC_Weight'] = comparison['AIC_Weight'] / comparison['AIC_Weight'].sum()
    
    results['comparison'] = comparison
    
    if verbose:
        print("\n" + "="*60)
        print("MODEL COMPARISON RESULTS")
        print("="*60)
        print(comparison.to_string(index=False))
        print("\nBest model by AIC:", comparison.loc[comparison['AIC'].idxmin(), 'Model'])
        print("Best model by BIC:", comparison.loc[comparison['BIC'].idxmin(), 'Model'])
        
        # Determine which hypothesis is supported
        best_model = comparison.loc[comparison['BIC'].idxmin(), 'Hypothesis']
        print(f"\nSupported Hypothesis: {best_model}")
        
        if best_model == 'H1':
            print("→ Decisions depend ONLY on current offer amount")
        elif best_model == 'H2':
            print("→ Decisions depend on BOTH current and previous offer amounts")
        elif best_model == 'H2+':
            print("→ Decisions follow RL reward-punishment framework with Bayesian updating")
            print("  (Accept = reward + punishment; punishment decreases with higher offers)")
        elif best_model == 'H2++':
            print("→ Decisions follow formal Bayesian utility model with power functions")
            print("  (u(r)=r^α, v(c)=λ*c^β; proper priors on all parameters)")
        elif best_model == 'H3':
            print("→ Decisions depend on current/previous amounts AND previous decisions")
    
    return results


def cross_validate_models(offers, decisions, n_folds=5, verbose=True):
    """
    Perform k-fold cross-validation for model comparison.
    
    Args:
        offers: array of offer proportions
        decisions: array of decisions
        n_folds: number of cross-validation folds
        verbose: print results
    
    Returns:
        DataFrame with cross-validation results
    """
    offers = np.asarray(offers)
    decisions = np.asarray(decisions)
    n = len(offers)
    
    # Create folds
    fold_size = n // n_folds
    indices = np.arange(n)
    
    cv_results = {
        'Threshold': [],
        'Linear_History': [],
        'Bayesian': [],
        'HMM': [],
        'RL_Bayesian': [],
        'Bayesian_Utility': []
    }
    
    for fold in range(n_folds):
        if verbose:
            print(f"\nFold {fold + 1}/{n_folds}...")
        
        # Test indices
        test_start = fold * fold_size
        test_end = (fold + 1) * fold_size if fold < n_folds - 1 else n
        test_idx = np.arange(test_start, test_end)
        train_idx = np.concatenate([np.arange(0, test_start), np.arange(test_end, n)])
        
        # Train data
        train_offers = offers[train_idx]
        train_decisions = decisions[train_idx]
        train_prev_offers = np.concatenate([[train_offers[0]], train_offers[:-1]])
        
        # Test data
        test_offers = offers[test_idx]
        test_decisions = decisions[test_idx]
        test_prev_offers = np.concatenate([[test_offers[0]], test_offers[:-1]])
        
        try:
            # Threshold Model
            m1 = ThresholdModel()
            m1.fit(train_offers, train_decisions)
            pred1 = m1.predict_proba(test_offers)
            ll1 = np.mean(test_decisions * np.log(pred1 + 1e-10) + 
                         (1 - test_decisions) * np.log(1 - pred1 + 1e-10))
            cv_results['Threshold'].append(ll1)
            
            # Linear History Model
            m2 = LinearHistoryModel()
            m2.fit(train_offers[1:], train_prev_offers[1:], train_decisions[1:])
            pred2 = m2.predict_proba(test_offers[1:], test_prev_offers[1:])
            ll2 = np.mean(test_decisions[1:] * np.log(pred2 + 1e-10) + 
                         (1 - test_decisions[1:]) * np.log(1 - pred2 + 1e-10))
            cv_results['Linear_History'].append(ll2)
            
            # Bayesian Model
            m3 = BayesianDecisionModel()
            m3.fit(train_offers, train_decisions)
            pred3 = m3.predict_proba(test_offers)
            ll3 = np.mean(test_decisions * np.log(pred3 + 1e-10) + 
                         (1 - test_decisions) * np.log(1 - pred3 + 1e-10))
            cv_results['Bayesian'].append(ll3)
            
            # HMM - Note: For fair comparison, we predict without using test decisions
            # This uses the stationary state distribution for predictions
            m4 = HiddenMarkovModel()
            m4.fit(train_offers, train_decisions)
            # Use None for prev_decisions to avoid data leakage - model uses prior state distribution
            pred4 = m4.predict_proba(test_offers, prev_decisions=None)
            ll4 = np.mean(test_decisions * np.log(pred4 + 1e-10) + 
                         (1 - test_decisions) * np.log(1 - pred4 + 1e-10))
            cv_results['HMM'].append(ll4)
            
            # RL-Bayesian Model
            m5 = ReinforcementLearningBayesianModel()
            m5.fit(train_offers, train_decisions)
            pred5 = m5.predict_proba(test_offers)
            ll5 = np.mean(test_decisions * np.log(pred5 + 1e-10) + 
                         (1 - test_decisions) * np.log(1 - pred5 + 1e-10))
            cv_results['RL_Bayesian'].append(ll5)
            
            # Bayesian Utility Model
            m6 = BayesianUtilityModel()
            m6.fit(train_offers, train_decisions, method='MAP')
            pred6 = m6.predict_proba(test_offers)
            ll6 = np.mean(test_decisions * np.log(pred6 + 1e-10) + 
                         (1 - test_decisions) * np.log(1 - pred6 + 1e-10))
            cv_results['Bayesian_Utility'].append(ll6)
        except Exception as e:
            if verbose:
                print(f"  Error in fold {fold + 1}: {e}")
            continue
    
    # Summary
    cv_summary = pd.DataFrame({
        'Model': list(cv_results.keys()),
        'Mean_Log_Likelihood': [np.mean(v) if v else np.nan for v in cv_results.values()],
        'Std_Log_Likelihood': [np.std(v) if v else np.nan for v in cv_results.values()]
    })
    
    if verbose:
        print("\n" + "="*60)
        print("CROSS-VALIDATION RESULTS")
        print("="*60)
        print(cv_summary.to_string(index=False))
    
    return cv_summary


# ============================================================================
# Simulation and Example Usage
# ============================================================================

def simulate_ug_data(n_trials=200, true_model='H2', seed=42):
    """
    Simulate Ultimatum Game data from different models.
    
    Args:
        n_trials: number of trials
        true_model: 'H1', 'H2', or 'H3'
        seed: random seed
    
    Returns:
        offers, decisions, true_params
    """
    np.random.seed(seed)
    
    # Generate random offers (proportion, 0.1 to 0.5)
    offers = np.random.uniform(0.1, 0.5, n_trials)
    decisions = np.zeros(n_trials, dtype=int)
    
    if true_model == 'H1':
        # Simple threshold model
        threshold = 0.25
        sensitivity = 10
        for t in range(n_trials):
            p_accept = expit(sensitivity * (offers[t] - threshold))
            decisions[t] = np.random.binomial(1, p_accept)
        true_params = {'threshold': threshold, 'sensitivity': sensitivity}
        
    elif true_model == 'H2':
        # Sequential effect on threshold
        base_threshold = 0.25
        sensitivity = 10
        seq_weight = 0.3  # weight of previous offer on current decision
        
        for t in range(n_trials):
            if t == 0:
                effective_threshold = base_threshold
            else:
                # Threshold shifts based on previous offer
                effective_threshold = base_threshold - seq_weight * (offers[t-1] - 0.3)
            
            p_accept = expit(sensitivity * (offers[t] - effective_threshold))
            decisions[t] = np.random.binomial(1, p_accept)
        
        true_params = {
            'base_threshold': base_threshold,
            'sensitivity': sensitivity,
            'seq_weight': seq_weight
        }
        
    elif true_model == 'H3':
        # HMM with state switching based on previous decision
        # State 0: strict (low threshold), State 1: lenient (high threshold)
        thresholds = [0.30, 0.20]  # threshold for each state
        sensitivity = 10
        
        # Transition probs: [prev_decision, current_state -> next_state]
        # After accept: more likely to stay lenient
        # After reject: more likely to become strict
        trans_accept = np.array([[0.7, 0.3], [0.2, 0.8]])  # from strict/lenient to strict/lenient
        trans_reject = np.array([[0.8, 0.2], [0.5, 0.5]])
        
        state = np.random.binomial(1, 0.5)  # initial state
        
        for t in range(n_trials):
            p_accept = expit(sensitivity * (offers[t] - thresholds[state]))
            decisions[t] = np.random.binomial(1, p_accept)
            
            # State transition
            if decisions[t] == 1:
                state = np.random.choice([0, 1], p=trans_accept[state])
            else:
                state = np.random.choice([0, 1], p=trans_reject[state])
        
        true_params = {
            'thresholds': thresholds,
            'sensitivity': sensitivity,
            'trans_accept': trans_accept.tolist(),
            'trans_reject': trans_reject.tolist()
        }
    else:
        raise ValueError(f"Unknown true_model: {true_model}")
    
    return offers, decisions, true_params


def load_behavioral_data(filepath):
    """
    Load behavioral data from a CSV or MAT file.
    
    Expected columns:
    - offer/rate: the offer proportion
    - decision/accept: the decision (1=accept, 0=reject)
    
    Returns:
        offers, decisions as numpy arrays
    """
    import os
    
    ext = os.path.splitext(filepath)[1].lower()
    
    if ext == '.csv':
        df = pd.read_csv(filepath)
        # Try common column names
        offer_cols = ['offer', 'rate', 'discount', 'money_you', 'proportion']
        decision_cols = ['decision', 'accept', 'response', 'choice']
        
        offers = None
        decisions = None
        
        for col in offer_cols:
            if col in df.columns:
                offers = df[col].values
                break
        
        for col in decision_cols:
            if col in df.columns:
                decisions = df[col].values
                break
        
        if offers is None or decisions is None:
            raise ValueError(f"Could not find offer/decision columns in {filepath}")
        
        # Convert decision to binary if needed
        if decisions.dtype == object:
            decisions = (decisions.astype(str).str.lower() == 'accept').astype(int)
        
        return offers, decisions
        
    elif ext == '.mat':
        from scipy.io import loadmat
        data = loadmat(filepath)
        
        # Look for result matrix as in SD_UG.m
        if 'result' in data:
            result = data['result']
            # Based on SD_UG.m (MATLAB uses 1-indexed arrays):
            # result(7,:) = discount (offer rate) -> Python: result[6, :] (0-indexed)
            # result(4,:) = accept/reject decision -> Python: result[3, :] (0-indexed)
            offers = result[6, :]  # MATLAB row 7 = Python index 6
            decisions = result[3, :]  # MATLAB row 4 = Python index 3
            return offers, decisions
        else:
            raise ValueError(f"Could not find 'result' matrix in {filepath}")
    
    else:
        raise ValueError(f"Unsupported file format: {ext}")


# ============================================================================
# Visualization Functions
# ============================================================================

def plot_model_comparison(results, save_path=None):
    """
    Create visualization of model comparison results.
    """
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not available for plotting")
        return
    
    fig, axes = plt.subplots(1, 3, figsize=(15, 5))
    
    comparison = results['comparison']
    models = comparison['Model'].values
    
    # Plot 1: AIC/BIC comparison
    ax1 = axes[0]
    x = np.arange(len(models))
    width = 0.35
    ax1.bar(x - width/2, comparison['AIC'], width, label='AIC', alpha=0.8)
    ax1.bar(x + width/2, comparison['BIC'], width, label='BIC', alpha=0.8)
    ax1.set_xticks(x)
    ax1.set_xticklabels(models, rotation=45, ha='right')
    ax1.set_ylabel('Information Criterion')
    ax1.set_title('Model Comparison: AIC vs BIC')
    ax1.legend()
    
    # Plot 2: AIC weights
    ax2 = axes[1]
    colors = ['#ff9999', '#66b3ff', '#99ff99', '#ffcc99']
    ax2.bar(models, comparison['AIC_Weight'], color=colors, alpha=0.8)
    ax2.set_ylabel('AIC Weight')
    ax2.set_title('Model Weights (AIC-based)')
    ax2.set_xticklabels(models, rotation=45, ha='right')
    
    # Plot 3: Log-likelihood
    ax3 = axes[2]
    ax3.bar(models, comparison['Log_Likelihood'], color='steelblue', alpha=0.8)
    ax3.set_ylabel('Log-Likelihood')
    ax3.set_title('Model Fit: Log-Likelihood')
    ax3.set_xticklabels(models, rotation=45, ha='right')
    
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"Figure saved to {save_path}")
    
    plt.show()


def plot_psychometric_curves(results, offers, decisions, save_path=None):
    """
    Plot psychometric curves for each model.
    """
    try:
        import matplotlib.pyplot as plt
    except ImportError:
        print("matplotlib not available for plotting")
        return
    
    fig, ax = plt.subplots(figsize=(10, 6))
    
    # Bin the data for visualization
    offer_bins = np.linspace(0.1, 0.5, 9)
    bin_centers = (offer_bins[:-1] + offer_bins[1:]) / 2
    
    # Compute empirical acceptance rates
    empirical_rates = []
    empirical_sem = []
    for i in range(len(offer_bins) - 1):
        mask = (offers >= offer_bins[i]) & (offers < offer_bins[i+1])
        if np.sum(mask) > 0:
            rate = np.mean(decisions[mask])
            sem = np.std(decisions[mask]) / np.sqrt(np.sum(mask))
            empirical_rates.append(rate)
            empirical_sem.append(sem)
        else:
            empirical_rates.append(np.nan)
            empirical_sem.append(np.nan)
    
    # Plot empirical data
    ax.errorbar(bin_centers, empirical_rates, yerr=empirical_sem, 
                fmt='ko', markersize=10, capsize=5, label='Data', zorder=5)
    
    # Plot model predictions
    x_pred = np.linspace(0.1, 0.5, 100)
    
    # Threshold model
    if 'threshold' in results:
        y_pred = results['threshold'].predict_proba(x_pred)
        ax.plot(x_pred, y_pred, 'r-', linewidth=2, label='Threshold (H1)')
    
    # Bayesian model
    if 'bayesian' in results:
        # For visualization, use constant "expected" offer
        y_pred = results['bayesian'].predict_proba(x_pred)
        ax.plot(x_pred, y_pred, 'g--', linewidth=2, label='Bayesian (H2)')
    
    ax.set_xlabel('Offer Proportion', fontsize=12)
    ax.set_ylabel('P(Accept)', fontsize=12)
    ax.set_title('Psychometric Curves: Model Fits', fontsize=14)
    ax.legend(loc='lower right')
    ax.set_xlim(0.05, 0.55)
    ax.set_ylim(-0.05, 1.05)
    ax.grid(True, alpha=0.3)
    
    plt.tight_layout()
    
    if save_path:
        plt.savefig(save_path, dpi=300, bbox_inches='tight')
        print(f"Figure saved to {save_path}")
    
    plt.show()


# ============================================================================
# Main Function
# ============================================================================

def main():
    """
    Main function demonstrating the sequential dependency analysis.
    """
    print("="*60)
    print("Sequential Dependency Analysis for Ultimatum Game")
    print("="*60)
    print()
    
    # Simulate data from each hypothesis for demonstration
    for true_hypothesis in ['H1', 'H2', 'H3']:
        print(f"\n{'='*60}")
        print(f"SIMULATION: Data generated from {true_hypothesis}")
        print("="*60)
        
        offers, decisions, true_params = simulate_ug_data(
            n_trials=200, 
            true_model=true_hypothesis, 
            seed=42
        )
        
        print(f"\nTrue parameters: {true_params}")
        print(f"N trials: {len(offers)}")
        print(f"Accept rate: {np.mean(decisions):.2%}")
        
        # Compare models
        results = compare_models(offers, decisions, verbose=True)
        
        # Cross-validation
        print("\nPerforming cross-validation...")
        cv_results = cross_validate_models(offers, decisions, n_folds=5, verbose=True)
    
    print("\n" + "="*60)
    print("Analysis complete!")
    print("="*60)
    print("\nTo analyze your own data:")
    print("  1. Load your data: offers, decisions = load_behavioral_data('your_data.csv')")
    print("  2. Run comparison: results = compare_models(offers, decisions)")
    print("  3. Visualize: plot_model_comparison(results)")


if __name__ == "__main__":
    main()
