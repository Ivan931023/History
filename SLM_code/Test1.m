clc
clear all
close all

% imaqreset   %%% Reset CCD
% imaqhwinfo
% imaqhwinfo('pointgrey')
% imaqhwinfo('gige')

tic

% Part.1 Input parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %
lambda = 447e-6;
f = 300;
Beam_size = 3.45;     % 1/e^2 intensity
Output_x = 0.4;      % The horizental beam size (1/e^2)
Output_y = 0.1;      % The vertical beam size (1/e^2)

% Ref:Analytical beam shaping with application to laser-diode arrays
a = Beam_size / (2*sqrt(2));
ax1 = a;
ax2 = Output_x / 2;
ay1 = a;
ay2 = Output_y / 2;

% ---------- Phase pattern parameter ---------- %
pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;



% ---------- CCD parameter ---------- %
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
% CCD_mode = 'F7_Mono16_640x480_Mode5';
Find_beam_order = 'First_order'; % 'Zero_order' or 'First_order' 
% intensity_min = 0;
% intensity_max = 63258;
intensity_range = [0 63258];
Shutter = 3;
Exposure = 0;
Sharpness = 0;
Brightness = 0;
Gain = 0;
snapshot_times = 5;
Check_Shutter = 1;
CCD_pixel = 2.2e-3; % CCD pixel size (CCD : BFLY-PGE-50A2C-CS)



% ---------- Grating parameter ---------- %
theta_deg = -90;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 200;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 12; 
% [12~255]


% ---------- Zernike parameter ---------- %
Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

% Z(2) = 0; % - down, + up
% Z(3) = 0.02; % - right, + left
% Z(4) = 0.5;
Z(5) = 1.35;
% Z(5) = 0.8;
% Z(6) = 0.5;
% Z(7) = -0.05;
Z(8) = 0.0;
Z(9) = 0.1;
Z(13) = 0.02;
% Z(15) = -1.5;



% ---------- Other parameter ---------- %
range = 150;


% ------------------------------------------------------------------------ %





% Part.2 Setup 
% ------------------------------------------------------------------------ %
% ---------- Find first order coordinate ---------- %
% [v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
% v = round(v);
% h = round(h);
% position = [v,h,range];

% ---------- Generate hologram phase ---------- %
Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed); % [0 255] -> [0 2pi]
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);
% theta_rad = Circle_analytic_phase(pixel,lambda,f,ax1,ay1)

% Total_phase = Angle_z + Blazed_phi + theta_rad;
% Total_phase = theta_rad;
Total_phase = Angle_z + Blazed_phi;
% Total_phase = ones(pixel);
phase = mod(Total_phase,2*pi);

close all
move_image_on_screen(move_x, move_y, pixel, phase)

% ---------- Setup CCD and shapshot ---------- %
% ---------- Put phase pattern to SLM ---------- %
close all
move_image_on_screen(move_x, move_y, pixel, phase)
pause(0.1)

% CCD fixed target pixel
row_idx = 800;
col_idx = 1900;
amplitude_range = 0:1:255;
intensity_trace = zeros(size(amplitude_range));

% ---------- CCD setup ---------- %
vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter;
src.Sharpness = Sharpness;
src.Brightness = Brightness;
src.Exposure = Exposure;
src.Gain = Gain;

% ---------- Snapshots ---------- %
% image = 0;
% for i = 1:snapshot_times
%     sprintf('Snapshot : %d',i)
%     start(vid);
%     data = getdata(vid,1);
%     data = double(data);
%     stop(vid)
%     image = image + data;
%     pause(0.05)
% end
% image = image / snapshot_times;
% 
% % data_zoomin = image(v-range:v+range,h-range:h+range);
% % data_zoomin_nor = data_zoomin / max(data_zoomin(:));
% 
% imagesc_turbo(image)

% ------------------------------------------------------------------------ %

for i = 1:length(amplitude_range)
    max_phase = amplitude_range(i);

    % Generate phase pattern
    Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
    Total_phase = Angle_z + Blazed_phi;
    phase = mod(Total_phase, 2*pi);

    % Send to SLM
    close all
    move_image_on_screen(move_x, move_y, pixel, phase);
    pause(0.1)

    % Capture image
    image = 0;
    for s = 1:snapshot_times
        start(vid);
        data = getdata(vid, 1);
        data = double(data);
        stop(vid);
        image = image + data;
        pause(0.05)
    end
    image = image / snapshot_times;

    % Record intensity at (row_idx, col_idx)
    intensity_trace(i) = image(row_idx, col_idx);
    fprintf('max_phase = %d, Intensity = %.2f\n', max_phase, intensity_trace(i));
    
    
   % ---------- 建立 GIF ----------
    frame_img = mat2gray(image);                    % 正規化到 [0,1]
    frame_img_uint8 = im2uint8(frame_img);          % 轉為 uint8 格式
    [imind, cm] = gray2ind(frame_img_uint8, 256);   % 轉為 indexed image

    gif_filename = 'ccd_grating_sweep.gif';

    if i == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);

    end
end

% Cleanup
delete(vid)

% Plot result
figure;
plot(amplitude_range, intensity_trace, 'LineWidth', 1.5);
xlabel('Grating max phase amplitude');
ylabel(sprintf('Intensity at pixel (%d,%d)', row_idx, col_idx));
title('Intensity vs Grating Amplitude');
grid on;


% Optional: Save data
% writematrix([amplitude_range', intensity_trace'], 'grating_amplitude_vs_intensity.csv');
















toc