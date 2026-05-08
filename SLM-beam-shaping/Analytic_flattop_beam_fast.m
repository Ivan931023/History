clc
clear all
close all

tic

lambda = 447e-6;
f = 300;
Beam_size = 3.45;
Output_x = 0.4;
Output_y = 0.1;

a = Beam_size / (2*sqrt(2));
ax1 = a; ax2 = Output_x / 2;
ay1 = a; ay2 = Output_y / 2;

pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;

CCD_mode = 'F7_Mono16_2592x1944_Mode0';
Find_beam_order = 'First_order';
intensity_range = [0 63258];
Shutter = 0.38;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 0;
CCD_pixel = 2.2e-3;

theta_deg = -90;
theta_blazed = deg2rad(theta_deg);
max_phase = 180;
min_phase = 0;
repeat = 1;
level = 20; 

Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);
Z(2) = 0;
Z(3) = 0.02;
Z(4) = 0.04;
Z(6) = 0.07;
Z(7) = -0.05;
Z(8) = 0.05;
Z(9) = -0.04+0.05;
Z(15) = -0.04;

range = 150;

[v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
v = round(v);
h = round(h);
position = [v,h,range];

Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);

Total_phase = Blazed_phi;
phase = mod(Total_phase,2*pi);

run('CCD_snapshot.m')
data_zoomin_nor = data_zoomin / max(data_zoomin(:));

f1 = figure;
imagesc(image,intensity_range)
axis image; colorbar; colormap turbo
title('CCD image')

f2 = figure;
imagesc(data_zoomin,intensity_range)
axis image; colorbar; colormap turbo
title('CCD image (zoom in)')

f3 = figure;
transverse = data_zoomin(range+1,:);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')

f4 = figure;
transverse = data_zoomin(:,range+1);
plot(1:2*range+1,transverse)
xlim([0 2*range+1])
title('Transverse plane')

toc
