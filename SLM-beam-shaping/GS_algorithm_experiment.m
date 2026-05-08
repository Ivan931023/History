clc
clear all
close all

tic
f = 300;
lambda = 447e-6;
dx = 8e-3;
pixel = 1080;
Beam_size = 3.45;
move_x = -90;
move_y = 130;

CCD_mode = 'F7_Mono16_2592x1944_Mode0';
Find_beam_order = 'First_order';
intensity_range = [0 63258];
Shutter = 0.4;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 1;
CCD_pixel = 2.2e-3;

theta_deg = -45;
theta_blazed = deg2rad(theta_deg);
max_phase = 255;
min_phase = 0;
repeat = 1;
level = 16; 

range = 200;
iteration = 50;

Nx = pixel; Ny = pixel;
dy = dx;
Lx = Nx * dx; Ly = Ny * dy;
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

sig_x = Beam_size / 4;
sig_y = Beam_size / 4;
Input_beam = exp(-(X.^2/2/sig_x^2+Y.^2/2/sig_y^2));
Input_beam = Input_beam ./ max(Input_beam(:));

center = round(pixel/2);
w = 20; l = 2;
Target = zeros(pixel);
Target(center-l:center+l,center-w:center+w) = 1;
Target = padding(Target,pixel);

phi = rand(pixel)*2*pi;

for t = 1:iteration
    focal_field = IDFT(Input_beam.*exp(1j*phi));
    focal_phase = Angle_0_2pi(focal_field);
    SLM_field = DFT(Target.*exp(1j*focal_phase));
    SLM_phase = Angle_0_2pi(SLM_field);
    phi = SLM_phase;
end

para = [1080 1080 f lambda range];
beam_para = Beam_size;
grating_para = [theta_deg repeat level];
data_zoomin_simulation = Simulate_phase_pattern(SLM_phase,para,beam_para,grating_para,CCD_pixel);
data_zoomin_simulation = data_zoomin_simulation / max(data_zoomin_simulation(:));

[v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
v = round(v);
h = round(h);
position = [v,h,range];

pixel_Zernike = 750;
Z = zeros(1,15);
Zernike_n = 4;
Z(4) = 0.04; Z(5) = -0.05; Z(6) = 0.07;
Z(7) = -0.05; Z(8) = 0.05; Z(9) = -0.04;
Z(15) = -0.04;
circle = pupil(pixel_Zernike);
ZZ = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z, Zernike_n, circle);
Angle_z = padding(ZZ, pixel); 

grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, theta_blazed);
Blazed_phi = 2*pi/255 * grat;
Total_phase = Blazed_phi + SLM_phase + Angle_z;
phase = mod(Total_phase,2*pi);

close all
move_image_on_screen(move_x, move_y, pixel, phase)
pause(0.1)

vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter; src.Sharpness = Sharpness;
src.Brightness = Brightness; src.Exposure = Exposure; src.Gain = Gain;

image = 0;
for i = 1:snapshot_times
    sprintf('Snapshot : %d',i)
    start(vid); data = getdata(vid,1); data = double(data); stop(vid)
    image = image + data;
    pause(0.05)
end
image = image / snapshot_times;
data_zoomin = image(v-range:v+range,h-range:h+range);
if Check_Shutter == 1
    [Shutter,data_zoomin] = Check_shutter(data_zoomin,Shutter,intensity_range,position);
end
data_zoomin_nor = data_zoomin / max(data_zoomin(:));

f1 = figure;
imagesc(image,intensity_range); axis image; colorbar; colormap turbo
title('CCD image')

f3 = figure;
imagesc(data_zoomin_nor,[0 1]); axis image off; colormap turbo

f4 = figure;
imagesc(data_zoomin_simulation,[0 1]); axis image off; colormap turbo

f6 = figure;
subplot(1,2,1); imagesc(data_zoomin_nor,[0 1]); axis image; colorbar; colormap turbo; title('Experiment')
subplot(1,2,2); imagesc(data_zoomin_simulation,[0 1]); axis image; colorbar; colormap turbo; title('Simulation')

toc

function result = DFT(u)
    result = fftshift(fft2(ifftshift(u)));
end
function result = IDFT(u)
    result = fftshift(ifft2(ifftshift(u)));
end
