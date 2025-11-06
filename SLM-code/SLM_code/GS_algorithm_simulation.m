clc
clear all
close all

% imaqreset   %%% Reset CCD
% imaqhwinfo
% imaqhwinfo('pointgrey')
% imaqhwinfo('gige')

tic
% Part.1 Parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %
f = 300;                 % Focal length (mm)
lambda = 447e-6;         % Wave length (mm)
CCD_pixel_size = 2.2e-3; % (mm)
dx = 8e-3;               % (mm)
% pixel = round(lambda*f / (dx*CCD_pixel_size),-1);  % According to Fourier optics
pixel = 1080;          % The phase pattern size(SLM) 
Beam_size = 3.45;           % 1/e^2 intensity (mm)
% FWHM = Beam_size/1.6949; % 0.5 intensity (mm)


% sprintf('pixel = %d',pixel)
% The different definition of gaussian distribution cause the different
% factor 2*sqrt(2) and 2.
% Paper definition : exp(-abs(x/a)^n)    n -> The order of super gaussian
% My definition : exp(-(x^2/2/sigma^2))  when n = 2 --> Gaussian
% ------------------------------------ %

% ---------- Brazed grating parameter ---------- %
theta_deg = -90;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 16; 
% ---------------------------------------------- %

% ---------- Other parameter ---------- %
range = 150;         % The size of figure after zoom in
iteration = 30;

% ------------------------------------- %

% ---------- SLM plane ---------- %
Nx = pixel;
Ny = pixel;

dy = dx; % (mm)
Lx = Nx * dx; % (mm)
Ly = Ny * dy; % (mm)
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

% ---------- Input beam power ---------- %
x0 = 0;
y0 = 0;

sig_x = Beam_size / 4;
sig_y = Beam_size / 4;

Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2)) ; % Gaussian beam
Input_beam = Input_beam ./ max(Input_beam(:));

% imagesc_turbo(Input_beam)

% ---------- Target ---------- %
center = round(pixel/2);
w = 20;
l = 20;
Target = zeros(pixel);
Target(center-l:center+l,center-w:center+w) = 1;

% imagesc_turbo(Target)

% ---------- Phase ---------- %
phi = rand(pixel)*2*pi;
% phi = ones(pixel)*2*pi;

for t = 1:iteration
    focal_field = DFT(Input_beam.*exp(1j*phi));
    focal_phase = Angle_0_2pi(focal_field);
    
    % Target = Target * (sum(Input_beam,"all")/sum(Target,"all"));
    SLM_field = IDFT(Target.*exp(1j*focal_phase));
    % SLM_intensity = abs(SLM_field).^2;
    SLM_phase = Angle_0_2pi(SLM_field);
    phi = SLM_phase;
    % Input_beam = Input_beam * (sum(SLM_intensity,"all")/sum(Input_beam,"all"));
end

focal_intensity = abs(focal_field).^2;
% focal_intensity = focal_intensity / max(focal_intensity(:));
imagesc_turbo(focal_intensity)

a = max(w,l);
focal_intensity_small = focal_intensity(center-1.25*a:center+1.25*a,center-1.25*a:center+1.25*a);
SLM_phase_small = Angle_0_2pi(SLM_field(center-1.25*a:center+1.25*a,center-1.25*a:center+1.25*a));
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

% path = pwd;
% cd('J:\其他電腦\yan\Files\Lab\Experiment_records\20250508_GS_algorithm')
% % exportgraphics(f1,sprintf('GS_phase_%g_%g.png',w,l))
% % exportgraphics(f2,sprintf('GS_intensity_%g_%g.png',w,l))
% cd(path)
toc