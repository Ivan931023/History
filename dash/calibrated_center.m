clc
clear all
close all

tic
%%% Setup Parameters
lambda = 447e-6;  % Wavelength (mm)
f = 300;          % Focal length (mm)

pixel = 1080;     % SLM resolution
move_x = -90;
move_y = 130;

% CCD Parameters
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
CCD_pixel = 2.2e-3;
snapshot_times = 5;

% Grating parameters
theta_deg = -90;
theta_blazed = deg2rad(theta_deg);
max_phase = 200;
min_phase = 0;
repeat = 1;
level = 12;

%%% Define Annular Ring Parameters
inner_radius = 0.05;  % Inner radius (normalized, 0-1)
outer_radius = 0.4;   % Outer radius (normalized, 0-1)
spot_radius = 0.02;   % Central bright spot radius (normalized, 0-1)


%%% Generate Annular Ring with Central Bright Spot
[x, y] = meshgrid(linspace(-1, 1, pixel));
r = sqrt(x.^2 + y.^2);

annular_mask = (r >= inner_radius) & (r <= outer_radius);
spot_mask = (r <= spot_radius);

final_mask = annular_mask | spot_mask;

%%% Generate Phase Patterns
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);

% Apply masks
Total_phase = Blazed_phi.* final_mask;
phase = mod(Total_phase, 2*pi);


%%% Display on SLM
move_image_on_screen(move_x, move_y, pixel, phase)
pause(0.1)

%%% CCD Snapshot
vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = 0.2;
src.Brightness = 0;

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
imagesc_turbo(image)

title('Annular Ring with Central Bright Spot')

%%% Optional: Save Image
imwrite(mat2gray(image), 'calibrated_ring_with_spot.png');

delete(vid)

toc