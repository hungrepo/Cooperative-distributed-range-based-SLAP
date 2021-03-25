%% This EKF for one range, written in the standard form used in the paper entitled

%   Cooperative distributed estimation and control of multiple autonomous vehicles 
%   for range-based underwater target localization and pursuit”

%   Authors: Nguyen T. Hung, Francisco Rego, Antonio Pascoal, Institute System and Robotic, IST, Lisbon
%   Contact: nguyen.hung@tecnico.ulisboa.pt
%   More information: https://nt-hung.github.io/research/Range-based-target-localization/
         
%% Note: 
% This standard form  is equivalent with the
% information form in the paper. For the case of single tracker-single target, this form is simpler 
% than the information form but the results are equivelent. We use the information form in distributed setup, which is
% more convenient
% =========================================================================================================================

function [xhatOut,POut] = STST_EKF_PosVel(r,p,xhat,P,Ts,depth,t) 
% Tunning parameter of the EKF
    Q = 1e-4*diag([10 10 1 1]);
    R = 10;
% Discrete model
    F = [1 0 Ts 0;
         0 1 0  Ts;
         0 0 1  0;
         0 0 0  1];
    qhat=xhat(1:2);
    rhat = norm([qhat-p;depth]);
    H = [(qhat-p)'/rhat 0 0] ;              % Jacobian
% Predict
    xhat = F*xhat;
    P = F*P*F' + Q;
% Calculate the Kalman gain
    K = P*H'/(H*P*H' + R);
% Calculate the measurement residual
    resid = r - rhat;
% Update the state and covariance estimates
    Ts_meas = 2;
    if rem(t,Ts_meas)==0
        xhat = xhat + K*resid;
        P = (eye(size(K,1))-K*H)*P;
        % only correct predicted mean and covariance when having 
        % a new range, assumed available at every Ts_meas second
    end
% Return
    xhatOut = xhat;
    POut = P;