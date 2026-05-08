clc
clear all
close all

tic

% Part.1 Parameters
f = 300;
lambda = 447e-6;
CCD_pixel_size = 2.2e-3;
dx = 8e-3;
pixel = round(lambda*f / (dx*CCD_pixel_size),-1);
pixel_pattern = 1080;
pixel_Zernike = 750;

Beam_size = 3.45;
Inputx = 3.55; Inputy = 3.55;
Outputx = 0.4; Outputy = 0.4;
Beam_size_x = Beam_size; Beam_size_y = Beam_size;
unit_power = 18000;

ax1 = Inputx / (2*sqrt(2)); ax2 = Outputx / 2;
ay1 = Inputy / (2*sqrt(2)); ay2 = Outputy / 2;

theta_deg = -90;
theta_blazed = deg2rad(theta_deg);
max_phase = 255; min_phase = 0; repeat = 1; level = 8; 

Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

range = 150;
ratio = 0.99999;
no_modulate = 0.01;

% Part.2 Setup
Nx = pixel; Ny = pixel;
dy = dx;
Lx = Nx * dx; Ly = Ny * dy;
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

sig_x = Beam_size_x / 4;
sig_y = Beam_size_y / 4;
Input_beam = exp(-((X).^2/2/(sig_x)^2+(Y).^2/2/(sig_y)^2));
Input_beam = Input_beam ./ max(Input_beam(:));
Input_beam_origin_power = sum(Input_beam,'all');
ratio_power = (unit_power * 10000) / Input_beam_origin_power;
Input_beam = Input_beam * ratio_power;
H = Input_beam(pixel/2,:);
Input_beam_normalized = Input_beam / ratio_power;

circle = pupil(pixel_Zernike);
ZZ = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z, Zernike_n, circle);
Angle_z = padding(ZZ, pixel);

grat = Blazed_grating_rotate(pixel_pattern, max_phase, min_phase, level, repeat, theta_blazed);
grat = padding(grat,pixel);
Blazed_phi = 2*pi/255 * grat;

x = dx * (-pixel_pattern/2:pixel_pattern/2-1);
y = dy * (-pixel_pattern/2:pixel_pattern/2-1);
[X, Y] = meshgrid(x,y);
thetax = (1/lambda/f) * (sqrt(2*pi)*ax1*ax2*exp(-2*(X/ax1).^2) + 2*pi*ax2*X.*erf(sqrt(2)/ax1.*X));
thetay = (1/lambda/f) * (sqrt(2*pi)*ay1*ay2*exp(-2*(Y/ay1).^2) + 2*pi*ay2*Y.*erf(sqrt(2)/ay1.*Y));
theta = thetax + thetay;
theta = mod(theta,2*pi);
theta_rad = mod(theta, 2*pi);
theta_rad = padding(theta_rad,pixel);
Total_phase = Blazed_phi + theta_rad;
phase = mod(Total_phase,2*pi);

% Part.3 Fourier transform
origin_power = sum(abs(IDFT(Input_beam)).^2,'all');
power_phase = origin_power*(1-no_modulate)*ratio;
power_amplitude = origin_power*(1-no_modulate)*(1-ratio);
power_no_modulate = origin_power*no_modulate;

phase_part = IDFT(Input_beam .* exp(1j*phase));
amplitude_part = IDFT(Input_beam .* (phase/2/pi));
no_modulate_part = IDFT(Input_beam);

phase_part = phase_part * sqrt(power_phase / sum(abs(phase_part).^2, 'all'));
amplitude_part = amplitude_part * sqrt(power_amplitude / sum(abs(amplitude_part).^2, 'all'));
no_modulate_part = no_modulate_part * sqrt(power_no_modulate / sum(abs(no_modulate_part).^2, 'all'));

result = phase_part + amplitude_part + no_modulate_part;
I = abs(result).^2;
I = I / max(I(:));

parameter = [f lambda dx];
grating_para = [theta_deg repeat level];
Mode = 'First_order';
[v, h] = Find_beam_simulation(parameter,grating_para,Beam_size,Mode);
data_zoomin = I(v-range:v+range,h-range:h+range);

% Part.4 Analysis
left_index = find(H >= max(H)*1/exp(1)^2,1,'first');
right_index = find(H >= max(H)*1/exp(1)^2,1,'last');
sprintf('Beam size = %g(mm)',dx*(right_index-left_index))

T = data_zoomin(range+1,:);
V = data_zoomin(:,range+1);
T = T / max(T); V = V / max(V);
left_index1 = find(T > 1/exp(1)^2*max(T),1 ,'first');
right_index1 = find(T > 1/exp(1)^2*max(T),1 ,'last');
up_index1 = find(V > 1/exp(1)^2*max(V),1 ,'first');
down_index1 = find(V > 1/exp(1)^2*max(V),1 ,'last');
sprintf('Horizental beam size = %g(pixel) = %g(um)\nVertical beam size = %g(pixel) = %g(um)',...
    right_index1-left_index1,(right_index1-left_index1)*2.2,down_index1-up_index1,(down_index1-up_index1)*2.2)

% Part.5 Plot
f1 = figure; imagesc(I,[0 1]); axis image; colorbar; colormap turbo; title('CCD image')
f2 = figure; imagesc(data_zoomin); axis image; colorbar; colormap turbo; title('CCD image (zoom in)')
f4 = figure; T1 = data_zoomin(range+1,:); T1 = T1/max(T1(:)); plot(1:length(data_zoomin),T1); xlim([0 2*range+1])
f5 = figure; T2 = data_zoomin(:,range+1); T2 = T2/max(T2(:)); plot(1:length(data_zoomin),T2); xlim([0 2*range+1])

toc

function SG = SuperGaussian(x,a,n)
    SG = exp(-abs(x/a).^n);
end
