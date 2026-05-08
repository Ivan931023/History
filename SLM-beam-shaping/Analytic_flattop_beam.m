clc
clear all
close all

% imaqreset   %%% Reset CCD
% imaqhwinfo
% imaqhwinfo('pointgrey')
% imaqhwinfo('gige')

tic

% Part.1 Input parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %
lambda = 447e-6;
f = 300;
Beam_size = 3.45;     % 1/e^2 intensity
Output_x = 0.4;      % The horizental beam size (1/e^2)
Output_y = 0.1;      % The vertical beam size (1/e^2)

% Ref:Analytical beam shaping with application to laser-diode arrays
a = Beam_size / (2*sqrt(2));
ax1 = a;
ax2 = Output_x / 2;
ay1 = a;
ay2 = Output_y / 2;

% ---------- Phase pattern parameter ---------- %
pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;



% ---------- CCD parameter ---------- %
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
% CCD_mode = 'F7_Mono16_640x480_Mode5';
Find_beam_order = 'First_order'; % 'Zero_order' or 'First_order' 
intensity_min = 0;
intensity_max = 63258;
intensity_range = [0 63258];
Shutter = 0.58;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 1;
CCD_pixel = 2.2e-3; % CCD pixel size (CCD : BFLY-PGE-50A2C-CS)



% ---------- Grating parameter ---------- %
theta_deg = -90;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 12; 



% ---------- Zernike parameter ---------- %
Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

Z(2) = 0.05;
Z(3) = 0.015;
Z(4) = 0.05;
Z(5) = -0.05;
Z(6) = -0.075;
Z(7) = 0.00;
Z(8) = 0.00;
Z(9) = 0.00;
Z(13) = 0.005;
Z(14) = -0.01;
Z(15) = -0.01;

% ---------- Other parameter ---------- %
range = 150;


% ------------------------------------------------------------------------ %





% Part.2 Setup 
% ------------------------------------------------------------------------ %
% ---------- Find first order coordinate ---------- %
% [v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
% v = round(v);
% h = round(h);
v = 680;
h = 1567;
position = [v,h,range];

% ---------- Generate hologram phase ---------- %
Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed); % [0 255] -> [0 2pi]
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);

Total_phase = Angle_z + Blazed_phi + theta_rad;
phase = mod(Total_phase,2*pi);

% ---------- Setup CCD and shapshot ---------- %
run('CCD_snapshot.m')

data_zoomin_nor = data_zoomin / max(data_zoomin(:));



% ---------- Theory solution ---------- %
para = [1080 1080 f lambda range];
beam_para = [Beam_size Output_x Output_y];
grating_para = [theta_deg repeat level];
data_zoomin_analytic = Simulate_flattop(para,beam_para,grating_para,CCD_pixel);
data_zoomin_analytic = data_zoomin_analytic / max(data_zoomin_analytic(:));

% ------------------------------------------------------------------------ %




% Part.3 Analysis data
% ------------------------------------------------------------------------ %
E = data_zoomin(range+1,:);
S = data_zoomin_analytic(range+1,:);
E = E / max(E);
S = S / max(S);
trans_RMS = RMS_var(E,S);

threshold1 = 0.001;
threshold2 = 0.95;
Index1 = Mask(data_zoomin_analytic,threshold1);
Index2 = Mask(data_zoomin_analytic,threshold2);

data_zoomin_2D = data_zoomin(Index2(1):Index2(2),Index2(3):Index2(4));
data_zoomin_2D = data_zoomin_2D / max(data_zoomin_2D(:));
data_zoomin_2D_avg = mean(data_zoomin_2D,'all');
data_zoomin_2D_avg = data_zoomin_2D_avg*ones(size(data_zoomin_2D));
RMS_2D = RMS_var_ver2(data_zoomin_2D,data_zoomin_2D_avg);

data_zoomin_nor_small = data_zoomin_nor(Index1(1):Index1(2),Index1(3):Index1(4));
data_zoomin_analytic_small = data_zoomin_analytic(Index1(1):Index1(2),Index1(3):Index1(4));

RMS_all = RMS_var_ver2(data_zoomin_nor_small, data_zoomin_analytic_small);

sprintf(['The RMS var. = %g%%\n' ...
         'The 2D region RMS var. = %g%%\n' ...
         'Transverse plane RMS var. = %g%%'],RMS_all,RMS_2D,trans_RMS)

% ------------------------------------------------------------------------ %





% Part.4 Plot figure
% ------------------------------------------------------------------------ %
f1 = figure;
imagesc(image,intensity_range)
axis image
colorbar
colormap turbo
title('CCD image')
xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')

f2 = figure;
imagesc(data_zoomin,intensity_range)
axis image
colorbar
colormap turbo
title('CCD image (zoom in)')
xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')

f3 = figure;
subplot(1,2,1)
imagesc(data_zoomin,intensity_range)
colormap turbo
colorbar
axis image
title('CCD image')
subplot(1,2,2)
imagesc(data_zoomin_analytic)
colormap turbo
colorbar
axis image
title('Analytic result')

f4 = figure;
subplot(1,2,1)
imagesc(data_zoomin_2D,[0.8 1])
axis image
colorbar
colormap turbo
title('Experimental result')
subplot(1,2,2)
imagesc(data_zoomin_2D_avg,[0.8 1])
axis image
colorbar
title('Average')

f5 = figure;
contour_height1 = 0.8;
contour_height2 = 0.3;
data_zoomin_max = max(data_zoomin(:));
data_zoomin_analytic_max = max(data_zoomin_analytic(:));
subplot(1,2,1)
contour(data_zoomin, [contour_height1*data_zoomin_max, contour_height1*data_zoomin_max], 'LineColor', 'black', 'LineWidth', 1); 
hold on
contour(data_zoomin_analytic, [contour_height1*data_zoomin_analytic_max, contour_height1*data_zoomin_analytic_max], 'LineColor', 'r', 'LineWidth', 1);
legend('CCD data contour','Analytic result contour')
title(sprintf('Contour line height : %g',contour_height1))
axis image
subplot(1,2,2)
contour(data_zoomin, [contour_height2*data_zoomin_max, contour_height2*data_zoomin_max], 'LineColor', 'black', 'LineWidth', 1); 
hold on
contour(data_zoomin_analytic, [contour_height2*data_zoomin_analytic_max, contour_height2*data_zoomin_analytic_max], 'LineColor', 'r', 'LineWidth', 1);
title(sprintf('Contour line height : %g',contour_height2))
axis image
legend('CCD data contour','Analytic result contour')

f6 = figure;
transverse = data_zoomin(range+1,:);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')

f7 = figure;
x2 = 1:length(data_zoomin);
H1 = data_zoomin(range+1,:);
H1 = H1 / max(H1);
H2 = data_zoomin_analytic(range+1,:);
H2 = H2 / max(H2);
plot(x2,H1)
hold on
plot(x2,H2)
legend('Experimental data','Analytic data','Location','south')
xlim([0 2*range+1])

f8 = figure;
transverse = data_zoomin(:,range+1);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')

% ------------------------------------------------------------------------ %

toc
