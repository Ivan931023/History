clc
clear all
close all

f = 300;
lambda = 447e-6;
CCD_pixel_size = 2.2e-3;
dx = 8e-3;
pixel = round(lambda*f / (dx*CCD_pixel_size),-1);
pixel_grating = 1000;
Beam_size = 1;
range = 1000;

Nx = pixel_grating;
Ny = pixel_grating;
dy = dx;
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

r = 0.055;
t = 1-r;
w = 6e-3;

theta_deg = 0;
theta_blazed = deg2rad(theta_deg);
max_phase = 255;
min_phase = 0;
repeat = 1;
level = 20; 

Blazed_theta = Grating_phase(pixel_grating, max_phase, min_phase, level, repeat, theta_blazed);
Gaussian_PSF = exp(-(X.^2+Y.^2)/2/w^2);
Gaussian_PSF = Gaussian_PSF / sum(Gaussian_PSF,'all');
Input_beam = Gaussian_beam(Beam_size,pixel,dx);

phi = Blazed_theta;
phi = padding(phi,pixel);
    
figure
imshow(mod(phi,2*pi),[0 2*pi])

E = -(r+exp(1j*phi))./(1+r*exp(1j*phi));

image = abs(DFT(Input_beam.*E)).^2;
imagesc_turbo(image)

c = round(pixel/2);
data_zoomin = image(c-range:c+range,c-range:c+range);
figure
imagesc(data_zoomin,[0 max(data_zoomin(:))])
colormap turbo
colorbar
axis image

figure
plot(1:length(data_zoomin),data_zoomin(range+1,:))
xlim([0 2*range+1])
