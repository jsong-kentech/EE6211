clear; clc; close all

%% Input
    %OCPs
path_root = 'G:\공유 드라이브';
subpath_ocpn = 'Battery Software Lab\Processed_data\Hyundai_dataset\OCV\AHC_(5)_OCV_C100.mat';
subpath_ocpp = 'Battery Software Lab\Processed_data\Hyundai_dataset\OCV\CHC_(5)_OCV_C100.mat';

ocpn = load([path_root filesep subpath_ocpn]);
ocpn = ocpn.OCV_golden.OCVchg;

ocpp = load([path_root filesep subpath_ocpp]);
ocpp = ocpp.OCV_golden.OCVchg;

figure(1)
subplot(1,2,1)
plot(ocpn(:,1),ocpn(:,2))
title('OCP_n')
subplot(1,2,2)
plot(ocpp(:,1),ocpp(:,2))
xlim([0 1])
    % parameters
    x0 = 0.002;
    y0 = 0.85;
    Qn = 1.2;
    Qp = 1.5;
    
    para_0 = [x0,y0,Qn,Qp];

%% Simulation

soc_vec = linspace(0,1,200);
ocv_model = func_ocv(soc_vec,para_0,ocpn,ocpp);

% check by plot
figure(2)
plot(soc_vec,ocv_model)
hold on

%compare to data
    subpath_ocv = 'Battery Software Lab\Processed_data\Hyundai_dataset\OCV\FCC_(5)_OCV_C100.mat';
   ocv_data = load([path_root filesep subpath_ocv]);
   ocv_data = ocv_data.OCV_golden.OCVchg;
   plot(ocv_data(:,1),ocv_data(:,2))

%% Fitting
%para_0 = [0.002, 0.85, 1.2, 1.8];
    %function handle
    func2min = @(para)func_cost(ocv_data,para,ocpn,ocpp);
    % minimize cost function
    para_hat = fmincon(func2min,para_0,[],[],[],[],[0 0 1 1],[1 1 2 2]);
    % compare to data
    ocv_hat =func_ocv(soc_vec,para_hat,ocpn,ocpp); % fitted model
    figure(2)
    hold on
    plot(soc_vec,ocv_hat);
    legend('initial guess','data','fitted model')


% quality check (dVdQ)

    % we could add "moving average to reduce the noise"
    
    % calculate dVdQ
    % data
    dvdq_data = (ocv_data(2:end,2)-ocv_data(1:end-1,2))./(ocv_data(2:end,1)-ocv_data(1:end-1,1));

    % model_hat
     dvdq_model = (ocv_hat(2:end)-ocv_hat(1:end-1))./(soc_vec(2:end)-soc_vec(1:end-1));


    % plot
    figure(3)
    plot(ocv_data(1:end-1,1),dvdq_data); hold on
    plot(soc_vec(1:end-1),dvdq_model)
    ylim([-5 10])
%% Functions

% Model
function ocv = func_ocv(soc,para,ocpn,ocpp)
x0=para(1); y0=para(2); Qn=para(3); Qp=para(4);

x_now = x0 + soc/Qn;
y_now = y0 - soc/Qp;

ocpn_now = interp1(ocpn(:,1),ocpn(:,2),x_now,"linear","extrap");
ocpp_now = interp1(ocpp(:,1),ocpp(:,2),y_now,"linear","extrap");

ocv = ocpp_now - ocpn_now;


end


%cost 
function [cost] = func_cost(ocv_data,para,ocpn,ocpp)

ocv_model = func_ocv(ocv_data(:,1),para,ocpn,ocpp);

cost = sqrt(sum((ocv_data(:,2) - ocv_model).^2));


end