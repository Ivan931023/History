clc
clear all

pixel = 1080;
l = 447e-6; % lambda (mm)
z = 500;
% --------- SLM plane ---------
Nx = pixel;
Ny = pixel;
dx = 8e-3; % (mm)
dy = 8e-3; % (mm)
Lx = Nx * dx; % (mm)
Ly = Ny * dy; % (mm)
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

% --------- The coordinate of quadratic phase ---------
m = linspace(-pixel/2, pixel/2-1, pixel);
n = linspace(-pixel/2, pixel/2-1, pixel);
[M, N] = meshgrid(m, -n);

% ------ Quadratic phase ------
a = 0.001;
b = 0.001;
phi = a*M.^2 + b*N.^2; % The phase of quadratic phase
% phi = a*M.^2; % The phase of quadratic phase
% phi = rand(pixel); % ---- Test random phase
% phi = ones(pixel); % ---- Test constant phase
exp_phase = exp(1j*(phi));

% --------- Set the Parameter of input beam ---------
FWHM = 2.2;
FWHM_xx = FWHM; % Experiment value
FWHM_yy = FWHM;
x0 = 0;
y0 = 0;
sig_x = FWHM_xx * 1/(2*sqrt(2*log(2)));
sig_y = FWHM_yy * 1/(2*sqrt(2*log(2)));
Gaussian = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2)) ; % Gaussian beam
% Gaussian = ones(pixel);
% Input_beam = Gaussian .* exp_phase;

% --------- Read data ---------
path_1 = 'C:\Users\USER\Desktop\資料\程式語言\Matlab\phase_pattern\20240221'; % The folder of phase pattern 
name_1 = 'Fresnel_x_2_y_0.2_FWHM_2.26_2.17_pixel_1080_1080_z_500_SLM_phase'; % The file name of phase pattern
name_11 = append(name_1,'.png');
name_1 = append(name_1, sprintf('_FWHM_x_%g_FWHM_y_%g',FWHM_xx,FWHM_yy),'.png');
phase = read_data(path_1,name_11);
phase = -3.14 + 6.28*phase; % Due to the range of read_data is (0,1), (0,1) -> (-pi,pi)

Input_beam = Gaussian .* exp(1j*phase);

Input_beam_TF = propTF(Input_beam,Lx,l,z);

figure
subplot(1,2,1)
imshow(mat2gray(Angle_0_2pi(Input_beam)))
title('Input beam phase')
colorbar
subplot(1,2,2)
imshow(mat2gray(Angle_0_2pi(Input_beam_TF)))
title('Input beam after propagation phase')
colorbar

figure
subplot(1,2,1)
imagesc(abs(Input_beam).^2)
axis image
title('Input beam')
colorbar
subplot(1,2,2)
imagesc(abs(Input_beam_TF).^2)
str = sprintf('CCD z = %g',z);
title(str)
colormap turbo
axis image
colorbar

figure
intensity = abs(Input_beam_TF).^2;
plot(x, intensity(Nx/2,:))

function u2 = propTF(u1,L,lambda,z)
    % propagation - transfer function approach
    % assumes same x and y side lengths and
    % uniform sampling
    % u1 - source plane field
    % L - source and observation plane side length
    % lambda - wavelength
    % z - propagation distance
    % u2 - observation plane field
    
    [M,N] = size(u1); %get input field array size
    dx = L/M; %sample interval
    k = 2*pi/lambda; %wavenumber
    
    fx = -1/(2*dx):1/L:1/(2*dx)-1/L; %freq coords
    [FX,FY] = meshgrid(fx,fx);
    
    H = exp(-j*pi*lambda*z*(FX.^2+FY.^2)); %trans func
    H = fftshift(H); %shift trans func
    U1 = fft2(fftshift(u1)); %shift, fft src field
    U2 = H.*U1; %multiply
    u2 = ifftshift(ifft2(U2)); %inv fft, center obs field
end

function Target = read_data(path, name)
    filepath = pwd;
    cd(path)    
    RGB = imread(name);
    I = im2gray(RGB);
    I = im2double(I);
    Target = I;
    cd(filepath)
end