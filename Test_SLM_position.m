clc
clear all
close all
tic

Z = zeros(1,15);
% Z(5) = -20;

z = 50;
Shutter = 0.12;
pixel = 750;
pixel_target = 400;
snapshot_times = 1;
path = pwd;

Grating_mode = 'Normal'; % 'Normal' or 'Special'
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
% CCD_mode = 'F7_Mono16_1296x960_Mode1';


% move_Y = (-100:20:100)+20;
% move_X = zeros(1,length(move_Y));


move_X = -94;
move_Y = 155;

move_X_origin = move_X;
move_Y_origin = move_Y;
offset = 50;

% move_X = [move_X-offset move_X        move_X+offset  move_X-offset  move_X  move_X+offset  move_X-offset  move_X         move_X+offset];
% move_Y = [move_Y+offset move_Y+offset move_Y+offset  move_Y         move_Y  move_Y         move_Y-offset  move_Y-offset  move_Y-offset];

Nx = pixel;
Ny = pixel;
dx = 8e-3; % (mm)
dy = 8e-3; % (mm)
Lx = Nx * dx; % (mm)
Ly = Ny * dy; % (mm)
fx = -1/(2*dx):1/Lx:1/(2*dx)-1/Lx; %freq coords
[FX,FY] = meshgrid(fx,fx);
l = 447e-6; 


theta_deg = -90;     % Grating rotate angle(Deg)
theta= deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 2;          % The number of times the phase is repeated
level = 16;          % Phase level

% ---- Find first order coordinate ----
% [v, h] = Find_beam(repeat,level,'Zero_order');
[v, h] = Find_beam(theta_deg,repeat,level,'First_order',CCD_mode);
range = 150;


count = 1;
t = clock;
f1 = figure;
f1.Position = [100, 100, 800, 600];
for i = 1:length(move_X)
    move_x = move_X(i)
    move_y = move_Y(i)
    % ---------- Zernike polynomial ----------
    phaseImage = ones(pixel);
    
    [rows, cols] = size(phaseImage);
    [xx1, yy1] = meshgrid(linspace(-1, 1, cols), linspace(1, -1, rows));
    [theta2, rho] = cart2pol(xx1, yy1);
    
    % Z(5) = -0.6;
    circle = pupil(pixel);
    ZZ = Zernike_polynomial_superposition_ver2(pixel, Z, 4, circle);
    Angle_z = ZZ;

    H = exp(-1j*pi*l*z*(FX.^2+FY.^2)); %trans func
    [xx yy] = size(H);
    pixel = xx;
    for ii = 1:xx
        for jj = 1:yy
            if sqrt((pixel/2-ii)^2+(pixel/2-jj)^2) > pixel/2
                H(ii,jj) = 0; 
            end
        end
    end

    
    % ---------- Special blazed grating ---------- %
    if strcmp(Grating_mode,'Special')
        grat1 = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, deg2rad(-45));
        Blazed_phi1 = 2*pi/255 * grat1; % [0 255] -> [0 2pi]
        grat2 = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, deg2rad(0));
        Blazed_phi2 = 2*pi/255 * grat2; % [0 255] -> [0 2pi]
        grat3 = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, deg2rad(45));
        Blazed_phi3 = 2*pi/255 * grat3; % [0 255] -> [0 2pi]
        grat4 = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, deg2rad(-90));
        Blazed_phi4 = 2*pi/255 * grat4; % [0 255] -> [0 2pi]
    
        Blazed_phi = zeros(pixel);
    
        for i1 = 1:pixel
            for j1 = 1:pixel
                if i1>pixel/2 && j1<pixel/2
                    Blazed_phi(i1,j1) = Blazed_phi1(i1,j1);
                end
                if i1<pixel/2 && j1<pixel/2
                    Blazed_phi(i1,j1) = Blazed_phi2(i1,j1);
                end
                if i1<pixel/2 && j1>pixel/2
                    Blazed_phi(i1,j1) = Blazed_phi3(i1,j1);
                end
                if i1>pixel/2 && j1>pixel/2
                    Blazed_phi(i1,j1) = Blazed_phi4(i1,j1);
                end
            end
        end
    end


    % ---------- Normal blazed grating ---------- %
    if strcmp(Grating_mode,'Normal')
        grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, deg2rad(-90));
        Blazed_phi = 2*pi/255 * grat; % [0 255] -> [0 2pi]
        Blazed_phi_before = Blazed_phi;
    end

    Angle_exp_z = Angle_0_2pi(H);
    Angle_exp_z_before = Angle_exp_z;
    [m n] = size(Angle_exp_z);
    length = (pixel-pixel_target)/2;
    
    radius = pixel_target/2;
    center = round(pixel/2);
    for xx = 1:pixel
        for yy = 1:pixel
            if sqrt((xx-center).^2+(yy-center).^2) <= radius
                Blazed_phi(xx,yy) = 0;
            end
        end
    end
    % ---------------------------------------- %

    figure
    imshow(Blazed_phi,[0 2*pi])
    phase = mod(Angle_z + Blazed_phi,2*pi);
    move_image_on_screen(move_x, move_y, pixel, phase)
    % move_image_on_screen(move_x, move_y, pixel, Blazed_phi)
    
    pause(0.1)
    
    % vid = videoinput('pointgrey', 1, 'F7_Mono16_2592x1944_Mode2');
    vid = videoinput('pointgrey', 1, CCD_mode);
    

    src = getselectedsource(vid);
    src.Shutter = Shutter;
    src.Brightness = 0;
    
    image = Snapshot(Shutter);
    data_zoomin = image(v-range:v+range,h-range:h+range);
    % 
    % figure(f1)
    % subplot(3,3,i)
    % imagesc(data_zoomin,[0 65280])
    % axis image 
    % colormap turbo
    % title(sprintf('X = %d, Y = %d',move_x,move_y))

    Sum(i) = sum(data_zoomin,'all');
end
Sum

if size(move_X) == [1 1]
    figure
    imagesc(data_zoomin,[0 65280])
    axis image 
    colormap turbo
    title(sprintf('X = %d, Y = %d',move_x,move_y))
end

cd('G:\Other computers\yan\Files\程式語言\Matlab\Main_code\Important\Test_SLM_position')
exportgraphics(f1,sprintf('Test_SLM_position_XY_%d_%d_%d_offset_%d.png',move_X_origin,move_Y_origin,pixel_target,offset))
cd(path)


toc
function none = Generate_GIF(f1,gif_filename,time,count)
    frame = getframe(f1);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    % gif_filename = sprintf('Different_z%g.gif',t);
    
    % Write to the GIF File
    if count == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', Inf, 'DelayTime', time);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', time);
    end
end