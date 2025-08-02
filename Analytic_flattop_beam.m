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

% Z(2) = 0.05; % - down, + up
% Z(3) = 0.00; % - right, + left
% Z(4) = 0.06;
% Z(5) = -0.05;
% Z(6) = 0.04;
% Z(7) = -0.02;
% Z(8) = 0.03;
% Z(9) = 0.00;
% Z(13) = 0.01;
% Z(15) = -0.02;

Z(2) = 0.05;      % 垂直 tilt，維持
Z(3) = 0.015;    % 水平 tilt，fine-tune
Z(4) = 0.05;      % 加強 0/90 astigmatism → 壓扁上下邊
Z(5) = -0.05;     % 維持斜向 astigmatism
Z(6) = -0.075;      % 再降低 defocus，收窄模擬邊界
Z(7) = 0.00;      % 無 vertical coma
Z(8) = 0.00;      % 無 horizontal coma
Z(9) = 0.00;      % 不用 trefoil
Z(13) = 0.005;    % spherical aberration 微調
Z(14) = -0.01;    % 新增 secondary astigmatism，收邊（上下邊修得更直）
Z(15) = -0.01;    % 保留修飾邊角

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
% theta_rad = Circle_analytic_phase(pixel,lambda,f,ax1,ay1)

Total_phase = Angle_z + Blazed_phi + theta_rad;
phase = mod(Total_phase,2*pi);

% ---------- Setup CCD and shapshot ---------- %
run('CCD_snapshot.m')

% data_zoomin = image(v-range:v+range,h-range:h+range);
data_zoomin_nor = data_zoomin / max(data_zoomin(:));



% ---------- Theory solution ---------- %
para = [1080 1080 f lambda range];
% beam_para = [Beam_size Output_x Output_y];
beam_para = [Beam_size Output_x Output_y];
grating_para = [theta_deg repeat level];
data_zoomin_analytic = Simulate_flattop(para,beam_para,grating_para,CCD_pixel);
% data_zoomin_analytic = Simulate_flattop_circle(para,beam_para,grating_para,CCD_pixel);
data_zoomin_analytic = data_zoomin_analytic / max(data_zoomin_analytic(:));

% ------------------------------------------------------------------------ %




% Part.3 Analysis data
% ------------------------------------------------------------------------ %
% ---------- Find transverse plane RMS var. ---------- %
E = data_zoomin(range+1,:); % Experiment
S = data_zoomin_analytic(range+1,:); % Simulation
E = E / max(E);
S = S / max(S);
trans_RMS = RMS_var(E,S);

% ---------- Find 2D region RMS var. ---------- %
threshold1 = 0.001;
threshold2 = 0.95;
% mask = data_zoomin_analytic < 0.1;
% data_zoomin_analytic(mask) = NaN;
Index1 = Mask(data_zoomin_analytic,threshold1);
Index2 = Mask(data_zoomin_analytic,threshold2);
% d = 35;
% Index2 = Index2 + [d -d d -d];

data_zoomin_2D = data_zoomin(Index2(1):Index2(2),Index2(3):Index2(4));
data_zoomin_2D = data_zoomin_2D / max(data_zoomin_2D(:));
data_zoomin_2D_avg = mean(data_zoomin_2D,'all');
data_zoomin_2D_avg = data_zoomin_2D_avg*ones(size(data_zoomin_2D));
RMS_2D = RMS_var_ver2(data_zoomin_2D,data_zoomin_2D_avg);

data_zoomin_nor_small = data_zoomin_nor(Index1(1):Index1(2),Index1(3):Index1(4));
data_zoomin_analytic_small = data_zoomin_analytic(Index1(1):Index1(2),Index1(3):Index1(4));

% ---------- Find all region RMS var. ---------- %
RMS_all = RMS_var_ver2(data_zoomin_nor_small, data_zoomin_analytic_small);
% RMS_all = RMS_var(data_zoomin, data_fit);


sprintf(['The RMS var. = %g%%\n' ...
         'The 2D region RMS var. = %g%%\n' ...
         'Transverse plane RMS var. = %g%%'],RMS_all,RMS_2D,trans_RMS)

% ------------------------------------------------------------------------ %





% Part.4 Plot figure
% ------------------------------------------------------------------------ %
% Figure 1 : CCD image(all) %
f1 = figure;
imagesc(image,intensity_range)
axis image
colorbar
colormap turbo
title('CCD image')
xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')


% Figure 2 : CCD image(Zoom in) %
f2 = figure;
imagesc(data_zoomin,intensity_range)
axis image
colorbar
colormap turbo
title('CCD image (zoom in)')
xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')


% Figure 3 : CCD image (experiment vs simulation) %
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


% Figure 4 : 2D region %
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


% Figure 5 : 2D contour line (experiment vs simulation) %
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


% Figure 6 : Transverse plane (experiment) %
f6 = figure;
transverse = data_zoomin(range+1,:);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')


% Figure 7 : Transverse plane (experiment vs simulation) %
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


% Figure 8 : Vertical transverse plane (experiment) %
f8 = figure;
transverse = data_zoomin(:,range+1);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')

% ------------------------------------------------------------------------ %




% %%
% % % Part.5 Save data
% % % ------------------------------------------------------------------------ %
% path = pwd;
% % cd('G:\Other computers\yan\Files\程式語言\Matlab\Main_code\CCD_image_ver2')
% cd('G:\Other computers\yan\Files\Lab\Experiment_records\20250522_square_circle_flat_top')
% exportgraphics(f2,append('CCD_image_',Get_time(),'.png'))
% % exportgraphics(f3,append('CCD_image_compare',Get_time(),'.png'))
% exportgraphics(f4,append('2D_region_',Get_time(),'.png'))
% exportgraphics(f5,append('Contour_line_',Get_time(),'.png'))
% exportgraphics(f6,append('Transverse_plane_',Get_time(),'.png'))
% exportgraphics(f7,append('Transverse_plane_compare_',Get_time(),'.png'))
% exportgraphics(f8,append('Transverse_plane_vertical_',Get_time(),'.png'))
% writematrix(data_zoomin,append('Data_',Get_time(),'.csv'))
% cd(path)














toc