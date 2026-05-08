clc
clear all
close all
tic

Z = zeros(1,15);
z = 50;
Shutter = 0.12;
pixel = 750;
pixel_target = 400;
snapshot_times = 1;
path = pwd;

Grating_mode = 'Normal';
CCD_mode = 'F7_Mono16_2592x1944_Mode0';

move_X = -94;
move_Y = 155;
move_X_origin = move_X;
move_Y_origin = move_Y;
offset = 50;

Nx = pixel; Ny = pixel;
dx = 8e-3; dy = 8e-3;
Lx = Nx * dx; Ly = Ny * dy;
fx = -1/(2*dx):1/Lx:1/(2*dx)-1/Lx;
[FX,FY] = meshgrid(fx,fx);
l = 447e-6; 

theta_deg = -90;
theta = deg2rad(theta_deg);
max_phase = 255;
min_phase = 0;
repeat = 2;
level = 16;

[v, h] = Find_beam(theta_deg,repeat,level,'First_order',CCD_mode);
range = 150;

count = 1;
for i = 1:length(move_X)
    move_x = move_X(i)
    move_y = move_Y(i)

    phaseImage = ones(pixel);
    [rows, cols] = size(phaseImage);
    [xx1, yy1] = meshgrid(linspace(-1, 1, cols), linspace(1, -1, rows));
    [theta2, rho] = cart2pol(xx1, yy1);
    
    circle = pupil(pixel);
    ZZ = Zernike_polynomial_superposition_ver2(pixel, Z, 4, circle);
    Angle_z = ZZ;

    H = exp(-1j*pi*l*z*(FX.^2+FY.^2));
    [xx yy] = size(H);
    pixel_h = xx;
    for ii = 1:xx
        for jj = 1:yy
            if sqrt((pixel_h/2-ii)^2+(pixel_h/2-jj)^2) > pixel_h/2
                H(ii,jj) = 0; 
            end
        end
    end

    if strcmp(Grating_mode,'Normal')
        grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, deg2rad(-90));
        Blazed_phi = 2*pi/255 * grat;
    end

    Angle_exp_z = Angle_0_2pi(H);
    radius = pixel_target/2;
    center = round(pixel/2);
    for xx = 1:pixel
        for yy = 1:pixel
            if sqrt((xx-center).^2+(yy-center).^2) <= radius
                Blazed_phi(xx,yy) = 0;
            end
        end
    end

    phase = mod(Angle_z + Blazed_phi,2*pi);
    move_image_on_screen(move_x, move_y, pixel, phase)
    pause(0.1)
    
    image = Snapshot(Shutter);
    data_zoomin = image(v-range:v+range,h-range:h+range);
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

toc
