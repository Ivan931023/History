clc
clear all
close all

tic
% Part.1 Parameters
f = 300;
lambda = 447e-6;
dx = 8e-3;
pixel = 1080;
Beam_size = 3.45;

theta_deg = -90;
theta_blazed = deg2rad(theta_deg);
max_phase = 255;
min_phase = 0;
repeat = 1;
level = 16; 

range = 150;
iteration = 30;

Nx = pixel;
Ny = pixel;
dy = dx;
Lx = Nx * dx;
Ly = Ny * dy;
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

x0 = 0;
y0 = 0;
sig_x = Beam_size / 4;
sig_y = Beam_size / 4;

Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2));
Input_beam = Input_beam ./ max(Input_beam(:));

center = round(pixel/2);
w = 20;
l = 20;
Target = zeros(pixel);
Target(center-l:center+l,center-w:center+w) = 1;

phi = rand(pixel)*2*pi;

for t = 1:iteration
    focal_field = DFT(Input_beam.*exp(1j*phi));
    focal_phase = Angle_0_2pi(focal_field);
    SLM_field = IDFT(Target.*exp(1j*focal_phase));
    SLM_phase = Angle_0_2pi(SLM_field);
    phi = SLM_phase;
end

focal_intensity = abs(focal_field).^2;
imagesc_turbo(focal_intensity)

a = max(w,l);
focal_intensity_small = focal_intensity(center-1.25*a:center+1.25*a,center-1.25*a:center+1.25*a);
SLM_phase = Angle_0_2pi(SLM_field);
Target_small = Target(center-1.25*a:center+1.25*a,center-1.25*a:center+1.25*a);

figure
subplot(1,2,1)
imagesc(Target_small)
axis image
colormap turbo
colorbar
subplot(1,2,2)
imagesc(focal_intensity_small)
axis image
colormap turbo
colorbar

f1 = figure;
imshow(SLM_phase,[0 2*pi])
axis off

f2 = figure;
imagesc(focal_intensity_small)
axis image
axis off
colormap turbo

toc

function result = DFT(u)
    result = fftshift(fft2(ifftshift(u)));
end
function result = IDFT(u)
    result = fftshift(ifft2(ifftshift(u)));
end
