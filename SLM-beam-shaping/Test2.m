clc
clear all
close all

tic

lambda = 447e-6;
f = 300;
Beam_size = 3.45;

pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;

CCD_mode = 'F7_Mono16_2592x1944_Mode0';
intensity_range = [0 63258];
Shutter = 3;
Exposure = 0; Sharpness = 0; Brightness = 0; Gain = 0;
snapshot_times = 5;
CCD_pixel = 2.2e-3;

theta_deg = -90;
theta_blazed = deg2rad(theta_deg);
min_phase = 0;
repeat = 1;
level = 12; 

Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

row_idx = 800;
col_list = [1520, 1700, 1800];
amplitude_range = 0:2:248;
num_points = length(amplitude_range);
num_positions = length(col_list);
intensity_matrix = zeros(num_points, num_positions);

vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter; src.Sharpness = Sharpness;
src.Brightness = Brightness; src.Exposure = Exposure; src.Gain = Gain;

for i = 1:num_points
    max_phase = amplitude_range(i);
    Angle_z = Zernike_phase(pixel, pixel_Zernike, Z, Zernike_n);
    Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
    Total_phase = Angle_z + Blazed_phi;
    phase = mod(Total_phase, 2*pi);
    close all
    move_image_on_screen(move_x, move_y, pixel, phase);
    pause(0.1)
    img_accum = 0;
    for s = 1:snapshot_times
        start(vid); data = getdata(vid, 1); data = double(data); stop(vid);
        img_accum = img_accum + data; pause(0.05)
    end
    img_avg = img_accum / snapshot_times;
    window_size = 12;
    half_win = floor(window_size / 2);
    for k = 1:num_positions
        col = col_list(k);
        row_range = max(1, min((row_idx - half_win + 1):(row_idx + half_win), size(img_avg,1)));
        col_range = max(1, min((col - half_win + 1):(col + half_win), size(img_avg,2)));
        roi_img = img_avg(row_range, col_range);
        intensity_matrix(i, k) = mean(roi_img(:));
    end
    fprintf('max_phase = %3d | Intensity = [%.1f, %.1f, %.1f]\n', ...
        max_phase, intensity_matrix(i,1), intensity_matrix(i,2), intensity_matrix(i,3));
end

delete(vid);

figure; hold on;
marker_set = {'rx', 'g+', 'b*'};
label_set = {'(800,1500)', '(800,1700)', '(800,1900)'};
for k = 1:num_positions
    plot(amplitude_range, intensity_matrix(:,k), marker_set{k}, 'DisplayName', label_set{k});
end
xlabel('Grating max phase amplitude');
ylabel('Intensity at selected pixels');
legend('show');
title('Intensity vs Grating Amplitude (level = window_size = 12)');
grid on;
saveas(gcf, 'intensity_vs_grating_2.fig');

output_table = table(amplitude_range', intensity_matrix(:,1), intensity_matrix(:,2), intensity_matrix(:,3), ...
    'VariableNames', {'GratingPhaseAmplitude', 'Pixel_800_1520', 'Pixel_800_1700', 'Pixel_800_1800'});
writetable(output_table, 'grating_intensity_data_2.csv');

toc
