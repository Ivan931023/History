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

move_x = -90;
move_y = 130;


% sprintf('pixel = %d',pixel)
% The different definition of gaussian distribution cause the different
% factor 2*sqrt(2) and 2.
% Paper definition : exp(-abs(x/a)^n)    n -> The order of super gaussian
% My definition : exp(-(x^2/2/sigma^2))  when n = 2 --> Gaussian
% ------------------------------------ %

% ---------- CCD parameter ---------- %
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
% CCD_mode = 'F7_Mono16_640x480_Mode5';
Find_beam_order = 'First_order'; % 'Zero_order' or 'First_order' 
intensity_range = [0 63258];
Shutter = 0.4;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 1;
CCD_pixel = 2.2e-3; % CCD pixel size (CCD : BFLY-PGE-50A2C-CS)

% ---------- Brazed grating parameter ---------- %
theta_deg = -45;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 16; 
% ---------------------------------------------- %

% ---------- Other parameter ---------- %
range = 200;         % The size of figure after zoom in
iteration = 50;

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

% ---------- Input beam power constrain ---------- %
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
l = 2;
Target = zeros(pixel);
Target(center-l:center+l,center-w:center+w) = 1;

% path = pwd;
% cd('G:\Other computers\yan\Files\程式語言\Matlab\Error_diffusion_code\data')
% data = imread('mao.jpg');
% data = imresize(data, [200 200], 'bilinear');
% data = rgb2gray(data);
% Target = double(data);
% cd(path)
Target = padding(Target,pixel);
% imagesc_turbo(Target)

% ---------- Phase ---------- %
phi = rand(pixel)*2*pi;
% phi = ones(pixel)*2*pi;

for t = 1:iteration
    focal_field = IDFT(Input_beam.*exp(1j*phi));
    focal_phase = Angle_0_2pi(focal_field);
    
    SLM_field = DFT(Target.*exp(1j*focal_phase));
    SLM_phase = Angle_0_2pi(SLM_field);
    phi = SLM_phase;
end

% ---------- Theory solution ---------- %
para = [1080 1080 f lambda range];
beam_para = Beam_size;
grating_para = [theta_deg repeat level];
data_zoomin_simulation = Simulate_phase_pattern(SLM_phase,para,beam_para,grating_para,CCD_pixel);
data_zoomin_simulation = data_zoomin_simulation / max(data_zoomin_simulation(:));



% Part.2 Setup 
% ------------------------------------------------------------------------ %
% ---------- Find first order coordinate ---------- %
[v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
v = round(v);
h = round(h);
% v = 1332;
% h = 1710;
position = [v,h,range];

% ---------- Zernike polynomial ---------- %
pixel_Zernike = 750;
Z = zeros(1,15);
Zernike_n = 4;
Z(2) = 0; % - down, + up
Z(3) = 0; % - right, + left
Z(4) = 0.04;
Z(5) = -0.05;
Z(6) = 0.07;
Z(7) = -0.05;
Z(8) = 0.05;
Z(9) = -0.04;
Z(15) = -0.04;
circle = pupil(pixel_Zernike);
ZZ = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z, Zernike_n, circle);
Angle_z = padding(ZZ, pixel); 

% ---------- Brazed grating ---------- %
grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, theta_blazed);
Blazed_phi = 2*pi/255 * grat; % [0 255] -> [0 2pi]


% Total_phase = Blazed_phi + theta_rad + Angle_z;
Total_phase = Blazed_phi + SLM_phase + Angle_z;
phase = mod(Total_phase,2*pi);

% ---------- Put phase pattern to SLM ---------- %
close all
move_image_on_screen(move_x, move_y, pixel, phase)
pause(0.1)

% ---------- CCD setup ---------- %
vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter;
src.Sharpness = Sharpness;
src.Brightness = Brightness;
src.Exposure = Exposure;
src.Gain = Gain;

% ---------- Snapshots ---------- %
image = 0;
for i = 1:snapshot_times
    sprintf('Snapshot : %d',i)
    start(vid);
    data = getdata(vid,1);
    data = double(data);
    stop(vid)
    image = image + data;
    pause(0.05)
end
image = image / snapshot_times;
data_zoomin = image(v-range:v+range,h-range:h+range);
if Check_Shutter == 1
    [Shutter,data_zoomin] = Check_shutter(data_zoomin,Shutter,intensity_range,position);
end
data_zoomin_nor = data_zoomin / max(data_zoomin(:));

% focal_intensity = abs(focal_field).^2;
% focal_intensity_nor = focal_intensity / max(focal_intensity(:));
% data_zoomin_simulation = focal_intensity_nor(center-range:center+range,center-range:center+range);


% Part.4 Plot figure
% ------------------------------------------------------------------------ %
% % Figure 1 : CCD image(all) %
f1 = figure;
imagesc(image,intensity_range)
axis image
colorbar
colormap turbo
title('CCD image')
xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
% 
% % Figure 2 : CCD image(Zoom in) %
% f2 = figure;
% imagesc(data_zoomin,intensity_range)
% axis image
% colorbar
% colormap turbo
% title('CCD image (zoom in)')
% xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
% ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')

% Figure 3 %
f3 = figure;
imagesc(data_zoomin_nor,[0 1])
axis image
axis off
colormap turbo
% title('CCD image (Experiment)')
% xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
% ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')

% Figure 4 %
f4 = figure;
imagesc(data_zoomin_simulation,[0 1])
axis image
axis off
colormap turbo
% title('CCD image (Simulation)')
% xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
% ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')

% % Figure 5 %
% f5 = figure;
% imagesc(Target,[0 1])
% axis image
% colorbar
% colormap turbo
% title('Target')
% xlabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')
% ylabel('$2.2 \, \mu \mathrm{m}$', 'Interpreter', 'latex')

% Figure 6 %
f6 = figure;
subplot(1,2,1)
imagesc(data_zoomin_nor,[0 1])
axis image
colorbar
colormap turbo
title('Experiment')
subplot(1,2,2)
imagesc(data_zoomin_simulation,[0 1])
axis image
colorbar
colormap turbo
title('Simulation')

toc

% path = pwd;
% cd('G:\Other computers\yan\Files\Lab\Experiment_records\20250508_GS_algorithm')
% % exportgraphics(f3,sprintf('GS_experiment_%g_%g.png',l,w))
% % exportgraphics(f4,sprintf('GS_simulation_%g_%g.png',l,w))
% exportgraphics(f3,'GS_experiment_mao.png')
% exportgraphics(f4,'GS_simulation_mao.png')
% cd(path)
%%
f1 = figure;
imagesc(data_zoomin_nor,[0 1])
axis image off
% colorbar
colormap turbo
% title('Experiment')
set(gca,'FontSize',14)

f2 = figure;
imagesc(data_zoomin_simulation,[0 1])
axis image off
% colorbar
colormap turbo
% title('Simulation')
set(gca,'FontSize',14)

path = pwd;
cd('G:\Other computers\yan\Files\Lab\Experiment_records\GS_algorithm_important')
exportgraphics(f1,sprintf('GS_experiment_square_%g_%g.png',l,w))
exportgraphics(f2,sprintf('GS_simulation_square_%g_%g.png',l,w))
cd(path)

