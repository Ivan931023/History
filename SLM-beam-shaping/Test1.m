clc
clear all
close all

tic

lambda = 447e-6;
f = 300;
Beam_size = 3.45;
Output_x = 0.4;
Output_y = 0.1;

a = Beam_size / (2*sqrt(2));
ax1 = a; ax2 = Output_x / 2;
ay1 = a; ay2 = Output_y / 2;

pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;

CCD_mode = 'F7_Mono16_2592x1944_Mode0';
Find_beam_order = 'First_order';
intensity_range = [0 63258];
Shutter = 3;
Exposure = 0; Sharpness = 0; Brightness = 0; Gain = 0;
snapshot_times = 5;
Check_Shutter = 1;
CCD_pixel = 2.2e-3;

theta_deg = -90;
theta_blazed = deg2rad(theta_deg);
max_phase = 200;
min_phase = 0;
repeat = 1;
level = 12; 

Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);
Z(5) = 1.35;
Z(8) = 0.0;
Z(9) = 0.1;
Z(13) = 0.02;

range = 150;

Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);

Total_phase = Angle_z + Blazed_phi;
phase = mod(Total_phase,2*pi);

close all
move_image_on_screen(move_x, move_y, pixel, phase)
pause(0.1)

row_idx = 800;
col_idx = 1900;
amplitude_range = 0:1:255;
intensity_trace = zeros(size(amplitude_range));

vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter; src.Sharpness = Sharpness;
src.Brightness = Brightness; src.Exposure = Exposure; src.Gain = Gain;

for i = 1:length(amplitude_range)
    max_phase = amplitude_range(i);
    Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
    Total_phase = Angle_z + Blazed_phi;
    phase = mod(Total_phase, 2*pi);
    close all
    move_image_on_screen(move_x, move_y, pixel, phase);
    pause(0.1)
    image = 0;
    for s = 1:snapshot_times
        start(vid); data = getdata(vid, 1); data = double(data); stop(vid);
        image = image + data; pause(0.05)
    end
    image = image / snapshot_times;
    intensity_trace(i) = image(row_idx, col_idx);
    fprintf('max_phase = %d, Intensity = %.2f\n', max_phase, intensity_trace(i));
    frame_img = mat2gray(image);
    frame_img_uint8 = im2uint8(frame_img);
    [imind, cm] = gray2ind(frame_img_uint8, 256);
    gif_filename = 'ccd_grating_sweep.gif';
    if i == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
    end
end

delete(vid)

figure;
plot(amplitude_range, intensity_trace, 'LineWidth', 1.5);
xlabel('Grating max phase amplitude');
ylabel(sprintf('Intensity at pixel (%d,%d)', row_idx, col_idx));
title('Intensity vs Grating Amplitude');
grid on;

toc
