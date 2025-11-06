clc
clear all
close all

% imaqreset   %%% Reset CCD
% imaqhwinfo  %%% 查看有哪些硬體介面支援套件
% imaqhwinfo('pointgrey') %%% 查詢 PointGrey 相機資訊與模式
% imaqhwinfo('gige') %%% 查詢 GigE Vision 相機資訊

tic

% Part.1 Input parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %

lambda = 447e-6;
f = 300;
Beam_size = 3.45;    % 強度衰減至 1/e^2 之光束直徑 

% ---------- Phase pattern parameter ---------- %
pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;

% ---------- CCD parameter ---------- %
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
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
% max_phase = 200;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 12; 

% ---------- Zernike parameter ---------- %
Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

% Z(2) = 0; % - down, + up
% Z(3) = 0; % - right, + left
% Z(4) = 0;
% Z(5) = 1.35;
% Z(6) = 0;
% Z(7) = 0;
% Z(8) = 0;
% Z(9) = 0.1;
% Z(13) = 0.02;
% Z(15) = -1.5;


% Part.2 Setup 
% ------------------------------------------------------------------------ %
% ---------- Setup CCD and shapshot ---------- %

% ROI pixel positions
row_idx = 800;
col_list = [1520, 1700, 1800];   % Three pixel columns
amplitude_range = 0:2:248;
num_points = length(amplitude_range);
num_positions = length(col_list);
intensity_matrix = zeros(num_points, num_positions);


% ---------- CCD setup ---------- %
vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter;
src.Sharpness = Sharpness;
src.Brightness = Brightness;
src.Exposure = Exposure;
src.Gain = Gain;

% ------------------------------------------------------------------------ %

for i = 1:num_points
    max_phase = amplitude_range(i);

    % Generate phase pattern
    Angle_z = Zernike_phase(pixel, pixel_Zernike, Z, Zernike_n);
    Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
    Total_phase = Angle_z + Blazed_phi;
    phase = mod(Total_phase, 2*pi);

    % Show phase pattern on SLM
    close all
    move_image_on_screen(move_x, move_y, pixel, phase);
    pause(0.1)

    % Capture and average CCD image
    img_accum = 0;
    for s = 1:snapshot_times
        start(vid);
        data = getdata(vid, 1);
        data = double(data);
        stop(vid);
        img_accum = img_accum + data;
        pause(0.05)
    end
    img_avg = img_accum / snapshot_times;

    % % 只拍一次不再平均 snapshot
    % start(vid);
    % img_avg = double(getdata(vid, 1));
    % stop(vid);

    % 對三個位置做 12x12 區域平均
    window_size = 12;
    half_win = floor(window_size / 2);

    for k = 1:num_positions
        col = col_list(k);
   
        % 計算區域範圍
        row_range = max(1, min((row_idx - half_win + 1):(row_idx + half_win), size(img_avg,1)));
        col_range = max(1, min((col - half_win + 1):(col + half_win), size(img_avg,2)));

        % 擷取子圖並平均
        roi_img = img_avg(row_range, col_range);
        intensity_matrix(i, k) = mean(roi_img(:));

    end

    % Record intensity for each ROI point

    fprintf('max_phase = %3d | Intensity = [%.1f, %.1f, %.1f]\n', ...
        max_phase, intensity_matrix(i,1), intensity_matrix(i,2), intensity_matrix(i,3));

    % % Create GIF
    % frame_img = mat2gray(img_avg);
    % frame_img_uint8 = im2uint8(frame_img);
    % [imind, cm] = gray2ind(frame_img_uint8, 256);
    % gif_filename = 'ccd_grating_sweep_1.gif';
    % 
    % if i == 1
    %     imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
    % else
    %     imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
    % end

    % ---------- 彩色 GIF 儲存 ----------
    fig = figure('Visible','off'); % 不顯示 figure，加快速度
    imagesc_turbo(img_avg);
    % axis off;
    % axis image;
    % colormap(turbo); % 使用 Turbo colormap
    % colorbar;

    % 抓取圖像框內容
    frame = getframe(fig);
    rgb_image = frame2im(frame);

    gif_filename = 'ccd_grating_sweep_color_2.gif';
    [rgb_indexed, map] = rgb2ind(rgb_image, 256);

    if i == 1
        imwrite(rgb_indexed, map, gif_filename, 'gif', 'Loopcount', inf, 'DelayTime', 0.05);
    else
        imwrite(rgb_indexed, map, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', 0.05);
    end

    close(fig); % 關掉 figure 以節省資源
end

% Cleanup
delete(vid);

% Plot intensity vs phase (dot plot)
figure;
hold on;
marker_set = {'rx', 'g+', 'b*'};  % Red circle, green square, blue triangle
label_set = {'(800,1500)', '(800,1700)', '(800,1900)'};

for k = 1:num_positions
    plot(amplitude_range, intensity_matrix(:,k), marker_set{k}, 'DisplayName', label_set{k});
end
xlabel('Grating max phase amplitude');
ylabel('Intensity at selected pixels');
legend('show');
title('Intensity vs Grating Amplitude (level = window_size = 12)');
grid on;
saveas(gcf, 'intensity_vs_grating_2.fig');     % MATLAB figure 檔

% Save to .csv
output_table = table(amplitude_range', intensity_matrix(:,1), intensity_matrix(:,2), intensity_matrix(:,3), ...
    'VariableNames', {'GratingPhaseAmplitude', 'Pixel_800_1520', 'Pixel_800_1700', 'Pixel_800_1800'});
writetable(output_table, 'grating_intensity_data_2.csv');

toc