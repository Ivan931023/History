%% Test paper : Comprehensive model and performance optimization of phase-only spatial light modulators
clc
clear all
close all

% ---------- Beam parameter ---------- %
f = 300;                 % Focal length (mm)
lambda = 447e-6;         % Wave length (mm)
CCD_pixel_size = 2.2e-3; % (mm)
dx = 8e-3;               % (mm)
pixel = round(lambda*f / (dx*CCD_pixel_size),-1);  % According to Fourier optics
pixel_grating = 1000;
Beam_size = 1;
range = 1000;

% --------- SLM plane ---------
Nx = pixel_grating;
Ny = pixel_grating;

% dx = 8e-3; % (mm)
dy = dx; % (mm)
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

a = 0.1;
b = a;
Quadratic_phase = a*X.^2 + b*Y.^2;

save_path = 'G:\Other computers\yan\Files\Lab\SLM_code\Power_data_simulation_w_1_pixel';

% ---------- Main parameters ---------- %
r = 0.055;
t = 1-r;
w = 1*8e-3;

count = 1;
Max_phase = 1:2:248;
zero_array = zeros(size(Max_phase));
first_array = zeros(size(Max_phase));
second_array = zeros(size(Max_phase));
% Max_phase = [100 200];
for max_phase = Max_phase
   fprintf('Processing max_phase = %d ...\n', max_phase);
    % ---------- Grating parameter ---------- %
    theta_deg = 0;     % Grating rotate angle(Deg)
    theta_blazed = deg2rad(theta_deg); % deg to rad
    % max_phase = 100;     % Maximum brazed grating phase
    min_phase = 0;       % Minimum brazed grating phase
    repeat = 1;          % The number of times the phase is repeated
    level = 12; 
    
    
    
    Blazed_theta = Grating_phase(pixel_grating, max_phase, min_phase, level, repeat, theta_blazed);
    
    Gaussian_PSF = exp(-(X.^2+Y.^2)/2/w^2);
    Gaussian_PSF = Gaussian_PSF / sum(Gaussian_PSF,'all');
    
    Input_beam = Gaussian_beam(Beam_size,pixel,dx);
    
    phi = conv2(Blazed_theta, Gaussian_PSF, 'same');
    phi = padding(phi,pixel);
    
    E = -(r+exp(1j*phi))./(1+r*exp(1j*phi));
    
    u1 = propTF(Input_beam.*E,pixel*dx,lambda,250);
    u2 = DFT(u1);
    u3 = propTF(u2,pixel*dx,lambda,250);
    
    image = abs(u3).^2;
    
    c = round(pixel/2);
    data_zoomin = image(c-range:c+range,c-range:c+range);


    zero_array(count) = data_zoomin(range+1,1001);
    first_array(count) = data_zoomin(range+1,1363);
    second_array(count) = data_zoomin(range+1,1725);
    

    f1 = figure;
    imagesc(data_zoomin,[0 max(data_zoomin(:))])
    colormap turbo
    colorbar
    axis image
    title(sprintf('maximum phase = %d',max_phase))

    f2 = figure;
    plot(1:length(data_zoomin),data_zoomin(range+1,:))
    xlim([0 2*range+1])
    title(sprintf('maximum phase = %d',max_phase))

    path = pwd;
    cd(save_path)
    time = 0.1;
    Generate_GIF(f1,'Zoom_in.gif',time,count)
    Generate_GIF(f2,'Transverse.gif',time,count)
    cd(path)
    count = count + 1;
    close all
end

f3 = figure;
scatter(Max_phase,zero_array,10,'filled');
hold on
scatter(Max_phase,first_array,10,'filled');
hold on
scatter(Max_phase,second_array,10,'filled');
xlim([0 255])
xlabel('Maximum phase')
ylabel('Intensity')
legend('Zero order','First order','Second order')

f4 = figure;
scatter(Max_phase,first_array,10,'filled');
xlim([0 255])
xlabel('Maximum phase')
ylabel('Intensity')
title('First order')

f5 = figure;
scatter(Max_phase,second_array,10,'filled');
xlim([0 255])
xlabel('Maximum phase')
ylabel('Intensity')
title('Second order')


Data = [Max_phase' zero_array' first_array' second_array'];

cd(save_path)
exportgraphics(f3,'Intensity.png')
exportgraphics(f4,'First_order.png')
exportgraphics(f5,'Second_order.png')
writematrix(Data,'Data.csv')
cd(path)


function Generate_GIF(f1,gif_filename,time,count)
    frame = getframe(f1);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    
    if count == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', Inf, 'DelayTime', time);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', time);
    end
end
