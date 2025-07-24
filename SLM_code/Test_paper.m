%% Test paper : Comprehensive model and performance optimization of phase-only spatial light modulators
clc
clear all
close all

% ---------- Beam parameter ---------- %
f = 300;                 % Focal length (mm)
lambda = 447e-6;         % Wave length (mm)
CCD_pixel_size = 2.2e-3; % (mm)
dx = 8e-3;               % (mm)
pixel = round(lambda*f / (dx*CCD_pixel_size),-1);  % According to Fourier optics
pixel_grating = 1000;
Beam_size = 1;
range = 1000;

% --------- SLM plane ---------
Nx = pixel_grating;
Ny = pixel_grating;

% dx = 8e-3; % (mm)
dy = dx; % (mm)
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);


% ---------- Main parameters ---------- %
r = 0.055;
t = 1-r;
w = 6e-3;

% ---------- Grating parameter ---------- %
theta_deg = 0;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 20; 



Blazed_theta = Grating_phase(pixel_grating, max_phase, min_phase, level, repeat, theta_blazed);
% Blazed_theta = Blazed_theta / (2*pi);
% Blazed_theta = Blazed_theta + 255;      % [0 2*pi] --> [0 255]

Gaussian_PSF = exp(-(X.^2+Y.^2)/2/w^2);
Gaussian_PSF = Gaussian_PSF / sum(Gaussian_PSF,'all');

Input_beam = Gaussian_beam(Beam_size,pixel,dx);

% phi = conv2(Blazed_theta, Gaussian_PSF, 'same');
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