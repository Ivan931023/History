clc
clear all
close all

tic

% Part.1 Parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %
f = 300;                 % Focal length (mm)
lambda = 447e-6;         % Wave length (mm)
CCD_pixel_size = 2.2e-3; % (mm)
dx = 8e-3;               % (mm)
pixel = round(lambda*f / (dx*CCD_pixel_size),-1);  % According to Fourier optics
% pixel = 1080;
pixel_pattern = 1080;          % The phase pattern size(SLM) 
pixel_Zernike = 750; % Zernike pupil size (pixel)

Beam_size = 3.45;           % 1/e^2 intensity (mm)  --> 
Inputx = 3.55;              % Input beam size (1/e^2)  --> Analytic parameter
Inputy = 3.55;              % Input beam size (1/e^2)  --> Analytic parameter
Outputx = 0.4;              % Output beam size (1/e^2) --> Analytic parameter
Outputy = 0.4;              % Output beam size (1/e^2) --> Analytic parameter

Beam_size_x = Beam_size;    % Input beam size (1/e^2)  --> Experimental value (Input beam)
Beam_size_y = Beam_size;    % Input beam size (1/e^2)  --> Experimental value (Input beam)

FWHM = Beam_size/1.6949;    % 0.5 intensity (mm)
unit_power = 18000;         % Simulate input beam power

% Ref:Analytical beam shaping with application to laser-diode arrays
ax1 = Inputx / (2*sqrt(2));    % Assuming input beam is perfect gaussian beam
ax2 = Outputx / 2;
ay1 = Inputy / (2*sqrt(2));    % Assumeing input beam is perfect gaussian beam
ay2 = Outputy / 2;

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
level = 8; 
% ---------------------------------------------- %

% ---------- Zernike parameter ---------- %
Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

% Z(4) = 0.3;
% Z(5) = -0.5;
% Z(6) = -0.4;
% Z(15) = 0.2;

% path = pwd;
% cd('G:\Other computers\yan\Files\Lab\Experiment_records\Metropolis_data_new')
% Z = readmatrix('Z_best_2025_3_21_13_54_27.581.csv')
% cd(path)
% Z(2) = 0; % - down, + up
% Z(3) = 0; % - right, + left
% 
% Z = -Z;
% --------------------------------------- %

% ---------- Other parameter ---------- %
range = 150;         % The size of figure after zoom in
ratio = 0.99999;     % Phase modulate ability
no_modulate = 0.01;  % No modulate part

% ------------------------------------- %





% Part.2 Setup 
% ------------------------------------------------------------------------ %
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

sig_x = Beam_size_x / 4;
sig_y = Beam_size_y / 4;

Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2)) ; % Gaussian beam
Input_beam = Input_beam ./ max(Input_beam(:));
% Input_beam = Input_beam + (rand(pixel)-0.5)*2*0.1;   % Simulate noise


Input_beam_origin_power = sum(Input_beam,'all');
Input_beam_normalized = Input_beam;
ratio_power = (unit_power * 10000) / Input_beam_origin_power;
Input_beam = Input_beam * ratio_power;
H = Input_beam(pixel/2,:);

% ---------- Zernike polynomial ---------- %
circle = pupil(pixel_Zernike);
ZZ = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z, Zernike_n, circle);
Angle_z = padding(ZZ, pixel); 

% ---------- Brazed grating ---------- %
grat = Blazed_grating_rotate(pixel_pattern, max_phase, min_phase, level, repeat, theta_blazed);
grat = padding(grat,pixel);
Blazed_phi = 2*pi/255 * grat; % [0 255] -> [0 2pi]

% ---------- Analytic solution ---------- %
%%% Paper : Analytical beam shaping with application to laser-diode arrays %%%
%%% The analytic below is a special case where n1 = 2, n2 = Inf            %%%
x = dx * (-pixel_pattern/2:pixel_pattern/2-1);
y = dy * (-pixel_pattern/2:pixel_pattern/2-1);
[X, Y] = meshgrid(x,y);
thetax = (1/lambda/f) * (sqrt(2*pi)*ax1*ax2*exp(-2*(X/ax1).^2) + 2*pi*ax2*X.*erf(sqrt(2)/ax1.*X));
thetay = (1/lambda/f) * (sqrt(2*pi)*ay1*ay2*exp(-2*(Y/ay1).^2) + 2*pi*ay2*Y.*erf(sqrt(2)/ay1.*Y));
theta = thetax + thetay;
theta = mod(theta,2*pi);

theta_rad = mod(theta, 2*pi);
theta_rad = padding(theta_rad,pixel);
% Total_phase = Blazed_phi + theta_rad + Angle_z;
Total_phase = Blazed_phi + theta_rad;
% Total_phase = theta_rad;
phase = mod(Total_phase,2*pi);

% ------------------------------------------------------------------------ %






% Part.3 Fourier transform
% ------------------------------------------------------------------------ %
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

phase_part_power = sum(abs(phase_part).^2,'all');
amplitude_part_power = sum(abs(amplitude_part).^2,'all');
no_modulate_part_power = sum(abs(no_modulate_part).^2,'all');

result = phase_part + amplitude_part + no_modulate_part;
% result = result / max(result,[],'all');

% result = DFT(Input_beam .* exp(1j*phase));
I = abs(result).^2;
I = I / max(I(:));

if repeat*level == 32 && pixel == 6350
    data_zoomin = I(2978-range:2978+range,pixel/2-range:pixel/2+range); % 32
elseif repeat*level == 8 && pixel == 6350
    data_zoomin = I(2380-range:2380+range,pixel/2-range:pixel/2+range); % 8
else
    % ---- Find first order position ---- %
    parameter = [f lambda dx];
    grating_para = [theta_deg repeat level];
    Mode = 'First_order';    % 'First_order' or 'Zero_order'
    [v, h] = Find_beam_simulation(parameter,grating_para,Beam_size,Mode)
    data_zoomin = I(v-range:v+range,h-range:h+range);
end

% v = 3335;
% h = 3811;
% v = pixel/2;
% h = v;
% v = 3137;
% h = v;
data_zoomin = I(v-range:v+range,h-range:h+range);

% ------------------------------------------------------------------------ %





% Part.4 Analysis
% ------------------------------------------------------------------------ %
% ---------- Calculate input beam size ---------- %
left_index = find(H >= max(H)*1/exp(1)^2,1,'first');
right_index = find(H >= max(H)*1/exp(1)^2,1,'last');
sprintf('Beam size = %g(mm)',dx*(right_index-left_index))

% ----------- Measure beam size ----------- %
T = data_zoomin(range+1,:);
V = data_zoomin(:,range+1);
T = T / max(T);
V = V / max(V);

left_index1 = find(T > 1/exp(1)^2*max(T),1 ,'first');
right_index1 = find(T > 1/exp(1)^2*max(T),1 ,'last');
up_index1 = find(V > 1/exp(1)^2*max(V),1 ,'first');
down_index1 = find(V > 1/exp(1)^2*max(V),1 ,'last');

% sprintf('The 2D region RMS var. = %g%%',RMS_2D)
sprintf('The horizental beam size = %g(pixel) = %g(um)\nThe vertical beam size = %g(pixel) = %g(um)',...
    right_index1-left_index1,(right_index1-left_index1)*2.2,down_index1-up_index1,(down_index1-up_index1)*2.2)
r = (right_index1-left_index1) / (down_index1-up_index1);
sprintf('ax2 / ay2 = %g, horizental beam size / vertical beam size = %g',ax2/ay2,r)

% ------------------------------------------------------------------------ %





% Part.5 Plot figure
% ------------------------------------------------------------------------ %
% Figure 1 : CCD image(all) %
f1 = figure;
% I = I / max(I(:));
imagesc(I,[0 1])
% imagesc(I)
axis image
colorbar
colormap turbo
title('CCD image')
xlabel(sprintf('$%.1f \\, (\\mathrm{\\mu m}/\\mathrm{pixel})$', 1/Lx*(lambda*f)*1000), 'Interpreter', 'latex')
ylabel(sprintf('$%.1f \\, (\\mathrm{\\mu m}/\\mathrm{pixel})$', 1/Ly*(lambda*f)*1000), 'Interpreter', 'latex')
% set(gca,'FontSize',14)
% set(gca,'YTick',[2000 4000 6000])

% Figure 2 : CCD image(Zoom in) %
f2 = figure;
imagesc(data_zoomin)
axis image
colorbar
colormap turbo
title('CCD image (zoom in)')
xlabel(sprintf('$%.1f \\, (\\mathrm{\\mu m}/\\mathrm{pixel})$', 1/Lx*(lambda*f)*1000), 'Interpreter', 'latex')
ylabel(sprintf('$%.1f \\, (\\mathrm{\\mu m}/\\mathrm{pixel})$', 1/Ly*(lambda*f)*1000), 'Interpreter', 'latex')
set(gca,'FontSize',14)

% Figure 3 : 2D contour line %
f3 = figure;
center = round(pixel/2);
l = pixel_pattern/2;
phase_small = phase(center-l+1:center+l,center-l+1:center+l);
Input_beam_small = Input_beam_normalized(center-l+1:center+l,center-l+1:center+l);
imshow(phase_small,[0 2*pi])
% hold on
% contour_height_FWHM = 0.5;
% contour_height_size = 0.1353;
% contour_height_99 = 0.0098;
% Input_beam_max = max(Input_beam_small(:));
% hold on
% contour(Input_beam_small, [contour_height_FWHM*Input_beam_max, contour_height_FWHM*Input_beam_max], ...
%     'LineColor', 'green', 'LineWidth', 1); 
% contour(Input_beam_small, [contour_height_size*Input_beam_max, contour_height_size*Input_beam_max], ...
%     'LineColor', 'blue', 'LineWidth', 1); 
% hold on
% contour(Input_beam_small, [contour_height_99*Input_beam_max, contour_height_99*Input_beam_max], ...
%     'LineColor', 'red', 'LineWidth', 1); 
% legend('FWHM','Beam size(1/e^2)','Energy > 99%')
% title(sprintf('Beam size = %g (mm), FWHM = %g (mm)',Beam_size,FWHM))

% Figure 4 : Transverse plane %
f4 = figure;
T1 = data_zoomin(range+1,:);
T1 = T1 / max(T1(:));
plot(1:length(data_zoomin),T1)
% xlabel(sprintf('$%.1f \\, \\mu \\mathrm{m}$', 1/Lx*(lambda*f)*1000), 'Interpreter', 'latex')
% ylabel('Intensity')
xlim([0 2*range+1])
% title('Transverse plane(horizen)')

% Figure 5 : Transverse plane %
f5 = figure;
T2 = data_zoomin(:,range+1);
T2 = T2 / max(T2(:));
plot(1:length(data_zoomin),T2)
% xlabel(sprintf('$%.1f \\, \\mu \\mathrm{m}$', 1/Lx*(lambda*f)*1000), 'Interpreter', 'latex')
% ylabel('Intensity')
xlim([0 2*range+1])
% title('Transverse plane(vertical)')

% ------------------------------------------------------------------------ %


toc



function SG = SuperGaussian(x,a,n)
    SG = exp(-abs(x/a).^n);
end


