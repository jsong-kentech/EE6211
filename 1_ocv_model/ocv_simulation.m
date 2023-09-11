clear; clc; close all

% Inputs

% folder
path_root = 'G:\공유 드라이브';
subpath_OCPn = 'Battery Software Lab\Processed_data\Hyundai_dataset\OCV\AHC_(5)_OCV_C100.mat';
subpath_OCPp = 'Battery Software Lab\Processed_data\Hyundai_dataset\OCV\CHC_(5)_OCV_C100.mat';

% Load OCPs
OCPn = load([path_root filesep subpath_OCPn]);
OCPn = OCPn.OCV_golden.OCVchg;
OCPp = load([path_root filesep subpath_OCPp]);
OCPp = OCPp.OCV_golden.OCVchg;

figure(1)
subplot(1,2,1)
plot(OCPn(:,1),OCPn(:,2))
title('OCP_n(x)')
subplot(1,2,2)
plot(OCPp(:,1),OCPp(:,2))
xlim([0 1])
title('OCP_p(y)')

% Parameters
x0 = 0.002;
y0 = 0.850;
Qn = 1.2;
Qp = 1.8;
para_0 = [x0, y0, Qn, Qp];

%% Simulation
soc_vec = linspace(0,1,200);
ocv_vec = func_OCV(soc_vec,para_0,OCPn,OCPp);

% plot simulation
figure(2)
plot(soc_vec,ocv_vec)
title('OCV(soc)')
hold on

% compare
    % OCV folder
    subpath_OCV = 'Battery Software Lab\Processed_data\Hyundai_dataset\OCV\FCC_(5)_OCV_C100.mat';
    OCV = load([path_root filesep subpath_OCV]);
    OCV = OCV.OCV_golden.OCVchg;
    plot(OCV(:,1),OCV(:,2))


%% Fitting
    para_hat = fmincon(@(para)func_cost(OCV(:,1),OCV(:,2),para,OCPn,OCPp),para_0,[],[],[],[],[0 0 1 1],[1 1 2 2]);
    ocv_hat = func_OCV(OCV(:,1),para_hat,OCPn,OCPp);

    % plot
    plot(OCV(:,1),ocv_hat)
    legend('initial guess','data','model fit')



%% Quality check


function OCV = func_OCV(soc, para, OCPn, OCPp)
    x0 = para(1); y0 = para(2); Qn = para(3); Qp = para(4);

    x = x0 + soc./Qn;
    y = y0 - soc./Qp;

    OCPn_soc = interp1(OCPn(:,1),OCPn(:,2),x,'linear','extrap');
    OCPp_soc = interp1(OCPp(:,1),OCPp(:,2),y,'linear','extrap');

    OCV = OCPp_soc - OCPn_soc;

end


function cost = func_cost(soc,ocv_data,para,OCPn,OCPp)

    ocv_model = func_OCV(soc,para,OCPn,OCPp);
    
    cost = sqrt(sum((ocv_data - ocv_model).^2));
    

end