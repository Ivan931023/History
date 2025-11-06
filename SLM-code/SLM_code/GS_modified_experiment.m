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
pixel = 1080;            % The phase pattern size(SLM) 
pixel_phase = 250;       % Signal region size
Beam_size = 3.45;        % 1/e^2 intensity (mm)

move_x = -90;
move_y = 130;

% ---------- CCD parameter ---------- %
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
% CCD_mode = 'F7_Mono16_640x480_Mode5';
Find_beam_order = 'First_order'; % 'Zero_order' or 'First_order' 
intensity_range = [0 63258];
Shutter = 2;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 0;
CCD_pixel = 2.2e-3; % CCD pixel size (CCD : BFLY-PGE-50A2C-CS)


% ---------- Other parameter ---------- %
range = 300;         % The size of figure after zoom in
iteration = 50;
e_ratio = 0.3;

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

% ---------- Brazed grating parameter ---------- %
theta_deg = -45;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 16; 
% ---------------------------------------------- %


% ---------- Quadratic phase ---------- %
m = linspace(-pixel_phase/2, pixel_phase/2-1, pixel_phase);
n = linspace(-pixel_phase/2, pixel_phase/2-1, pixel_phase);
[M, N] = meshgrid(m, -n);

r = pi/pixel_phase; % The parameter of quadratic phase
a = r;
b = r;

phi = a*M.^2 + b*N.^2; % The phase of quadratic phase
% phi = a*M.^2; % The phase of quadratic phase
% phi = rand(pixel_phase); % ---- Test random phase



% ---------- Target ---------- %
center = round(pixel_phase/2);
w = 20;
l = 20;
Target_intensity = zeros(pixel_phase);
Target_intensity(center-l:center+l,center-w:center+w) = 1;
% Target_intensity = Target_intensity * 10000;

exp_phase = exp(1j*(phi));
Target_phase = padding(exp_phase,pixel);

spectrum = DFT(exp_phase);


% path = pwd;
% cd('I:\其他電腦\yan\Files\程式語言\Matlab\Error_diffusion_code\data')
% cd('G:\Other computers\yan\Files\程式語言\Matlab\Error_diffusion_code\data')
% data = imread('mindy_200.jpg');
% data = im2gray(data);
% data = im2double(data);
% data = double(data);
% data = data * 250;
% Target_intensity = imresize(data, [150 150], 'bilinear');
% cd(path)


Target_intensity = padding(Target_intensity,pixel);

% ------ Calculate the first iteration power ------
initial = sum(abs(DFT(Input_beam)).^2,'all');

Target_power_before = sum(abs(Target_intensity).^2,'all');  % Test the power before power correction
r = initial / Target_power_before;        % The relation between before and after power correction
Target_intensity = Target_intensity * sqrt(r) * sqrt(e_ratio);      % Power correction use the function "Calculate_initial_power"
% Target_power_after = sum(abs(Target_intensity).^2,'all');   % Test the power after power correction


Target = Target_intensity .* Target_phase;


% ------------------------------ GS algorithm --------------------------------------
u = Target;
uu = u;
sum(abs(u).^2,'all')

for t = 1:iteration
    t
    % ------ Focal plane --> hologram_plane ------
    % DOEphase = exp(1j * DOE);
    SLM_field = IDFT(u);
    % function_holo = propTF(u,Lx,l,-z);
    SLM_phase = Angle_0_2pi(SLM_field);

    % ------ hologram_plane --> Focal plane ------
    focal_field = DFT(Input_beam.*exp(1j*SLM_phase));
    % focal_field = DFT(exp(1j*SLM_phase));
    focal_field_before = focal_field;
    focal_field_intensity = abs(focal_field).^2;
    % function_focal = propTF(function_holo_exp_phase,Lx,l,z);

    
    % function_focal = function_focal / max(function_focal,[],"all");  %%%%%%%%%%%%%%%%%% 
    % ------ Define signal and noise region ------
    for xx = 1:pixel
        for yy = 1:pixel
            if xx > (pixel-pixel_phase)/2 && xx < (pixel+pixel_phase)/2 && yy > (pixel-pixel_phase)/2 && yy < (pixel+pixel_phase)/2
                focal_field(xx,yy) = uu(xx,yy);
            end
        end
    end
    u = focal_field;
end

% focal_field_intensity = focal_field_intensity / max(focal_field_intensity(:));
% 
% figure
% imagesc(focal_field_intensity)
% axis image
% colormap turbo
% colorbar



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
Z(3) = 0.02; % - right, + left
Z(4) = 0.04;
Z(5) = -0.05;
Z(6) = 0.07;
Z(7) = -0.05;
Z(8) = -0.05;
Z(9) = -0.04+0.05;
% Z(13) = 0.01;
Z(15) = -0.04;
circle = pupil(pixel_Zernike);
ZZ = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z, Zernike_n, circle);
Angle_z = padding(ZZ, pixel); 

% ---------- Brazed grating ---------- %
grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, theta_blazed);
Blazed_phi = 2*pi/255 * grat; % [0 255] -> [0 2pi]


Total_phase = Blazed_phi + SLM_phase + Angle_z;
% Total_phase = SLM_phase + Angle_z;
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

f7 = figure;
plot(1:length(data_zoomin_nor),data_zoomin_nor(range+1+5,:))
xlim([0 length(data_zoomin_nor)])
ylim([0 1])

f8 = figure;
plot(1:length(data_zoomin_simulation),data_zoomin_simulation(range+1,:))
xlim([0 length(data_zoomin_simulation)])


% path = pwd;
% cd('G:\Other computers\yan\Files\Lab\Experiment_records\20250509_GS_modified')
% % exportgraphics(f3,sprintf('GS_experiment_%g_%g.png',l,w))
% % exportgraphics(f4,sprintf('GS_simulation_%g_%g.png',l,w))
% exportgraphics(f3,'GS_modified_experiment_mindy.png')
% exportgraphics(f4,'GS_modified_simulation_mindy.png')
% cd(path)

figure
imagesc(abs(spectrum).^2)
axis image off
colormap turbo

toc
%%
f9 = figure;
imagesc(data_zoomin_nor,[0 1])
axis image off
% colorbar
colormap turbo
% title('Experiment')
set(gca,'FontSize',14)

f10 = figure;
imagesc(data_zoomin_simulation,[0 1])
axis image off
% colorbar
colormap turbo
% title('Simulation')
set(gca,'FontSize',14)


path = pwd;
cd('G:\Other computers\yan\Files\Lab\Experiment_records\GS_modified_important')
writematrix(image,sprintf('GS_experiment_image_data_flattop_%g_%g.csv',l,w))
writematrix(data_zoomin,sprintf('GS_experiment_image_zoomin_data_flattop_%g_%g.csv',l,w))
exportgraphics(f1,sprintf('GS_experiment_image_flattop_%g_%g.png',l,w))
exportgraphics(f7,sprintf('GS_experiment_transverse_flattop_%g_%g.png',l,w))
exportgraphics(f8,sprintf('GS_simulation_transverse_flattop_%g_%g.png',l,w))
exportgraphics(f9,sprintf('GS_experiment_flattop_%g_%g.png',l,w))
exportgraphics(f10,sprintf('GS_simulation_flattop_%g_%g.png',l,w))
cd(path)





function SG = SuperGaussian(A, x, y, FWHM_x, FWHM_y, px, py)
    x0 = 0;
    y0 = 0;
    sigx = sqrt((FWHM_x/2)^2*0.5*(log(2))^(-1/px)); % Sigma for Super-Gaussian beam
    sigy = sqrt((FWHM_y/2)^2*0.5*(log(2))^(-1/py)); % Sigma for Super-Gaussian beam
    SG = A*exp(-((x-x0).^2/2/sigx^2).^px-((y-y0).^2/2/sigy^2).^py);
end

function grating = Grating(X, wl, phi)
    grating = exp(-1j*2*pi/wl*sin(phi)*X);
end

% ------ DFT ------
function result = DFT(u, pixel)
    result = fftshift(fft2(ifftshift(u)));
end

% ------ IDFT ------
function result = IDFT(u, pixel)
    result = fftshift(ifft2(ifftshift(u)));
end

function initial = Calculate_initial_power(Input_beam,Target,pixel,pixel_phase,exp_phase_pad)
    Target_pad = padding(Target,pixel);
    u = Target_pad .* exp_phase_pad;
    function_holo = IDFT(u);
    function_holo_phase = Angle_0_2pi(function_holo);
    function_holo_exp_phase = exp(1j*function_holo_phase);
    function_focal = DFT(Input_beam .* function_holo_exp_phase);
    % function_focal = DFT(function_holo_exp_phase);
    power_before1 = 0;
    for xx = 1:pixel
        for yy = 1:pixel
            if xx > (pixel-pixel_phase)/2 && xx <= (pixel+pixel_phase)/2 && yy > (pixel-pixel_phase)/2 && yy <= (pixel+pixel_phase)/2
                power_before1 = power_before1 + abs(function_focal(xx,yy).^2);
            end
        end  
    end
    initial = power_before1;
end
