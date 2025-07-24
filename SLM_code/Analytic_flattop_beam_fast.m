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
% intensity_min = 0;
% intensity_max = 63258;
intensity_range = [0 63258];
Shutter = 0.38;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 0;
CCD_pixel = 2.2e-3; % CCD pixel size (CCD : BFLY-PGE-50A2C-CS)



% ---------- Grating parameter ---------- %
theta_deg = -90;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 180;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 20; 



% ---------- Zernike parameter ---------- %
Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

Z(2) = 0; % - down, + up
Z(3) = 0.02; % - right, + left
Z(4) = 0.04;
% Z(5) = -0.05;
Z(6) = 0.07;
Z(7) = -0.05;
Z(8) = 0.05;
Z(9) = -0.04+0.05;
% Z(13) = 0.01;
Z(15) = -0.04;



% ---------- Other parameter ---------- %
range = 150;


% ------------------------------------------------------------------------ %





% Part.2 Setup 
% ------------------------------------------------------------------------ %
% ---------- Find first order coordinate ---------- %
[v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
v = round(v);
h = round(h);
position = [v,h,range];

% ---------- Generate hologram phase ---------- %
Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed); % [0 255] -> [0 2pi]
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);
% theta_rad = Circle_analytic_phase(pixel,lambda,f,ax1,ay1)

% Total_phase = Angle_z + Blazed_phi + theta_rad;
% Total_phase = theta_rad;
Total_phase = Blazed_phi;
% Total_phase = ones(pixel);
phase = mod(Total_phase,2*pi);
%%
% ---------- Setup CCD and shapshot ---------- %
run('CCD_snapshot.m')

% data_zoomin = image(v-range:v+range,h-range:h+range);
data_zoomin_nor = data_zoomin / max(data_zoomin(:));

% ------------------------------------------------------------------------ %





% Part.3 Plot figure
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


% Figure 3 : Horizontal transverse plane (experiment) %
f3 = figure;
transverse = data_zoomin(range+1,:);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')


% Figure 4 : Vertical transverse plane (experiment) %
f4 = figure;
transverse = data_zoomin(:,range+1);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')

% ------------------------------------------------------------------------ %
















toc