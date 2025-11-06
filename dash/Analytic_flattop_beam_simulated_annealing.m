clc
clear all
close all

t00 = clock;

% Part.1 Parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %
lambda = 447e-6;
f = 300;
Beam_size = 3.7;     % 1/e^2 intensity
Output_x = 0.4;      % The horizental beam size (1/e^2)
Output_y = 0.4;      % The vertical beam size (1/e^2)

% Ref:Analytical beam shaping with application to laser-diode arrays
a = Beam_size / (2*sqrt(2));
ax1 = a;
ax2 = Output_x / 2;
ay1 = a;
ay2 = Output_y / 2;

% ------------------------------------ %

% ---------- Phase pattern parameter ---------- %
pixel = 1080;
pixel_Zernike = 750;
move_x = -90;
move_y = 130;

% --------------------------------------------- %

% ---------- CCD parameter ---------- %
CCD_mode = 'F7_Mono16_2592x1944_Mode0';
Find_beam_order = 'First_order'; % 'Zero_order' or 'First_order' 
intensity_range = [0 65280];
Shutter = 0.84;
Sharpness = 0;
Exposure = -3.5;
Brightness = 0;
snapshot_times = 5;
CCD_pixel = 2.2e-3; % CCD pixel size (CCD : BFLY-PGE-50A2C-CS)

% ----------------------------------- %

% ---------- Brazed grating parameter ---------- %
theta_deg = -90;     % Grating rotate angle(Deg)
theta_blazed = deg2rad(theta_deg); % deg to rad
max_phase = 255;     % Maximum brazed grating phase
min_phase = 0;       % Minimum brazed grating phase
repeat = 1;          % The number of times the phase is repeated
level = 16; 
% ---------------------------------------------- %

% ---------- Zernike parameter ---------- %
Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);

Z0 = Z;
Z1 = Z0;

% --------------------------------------- %

% ---------- Simulated annealing parameter ---------- %
T1 = 0.1;
T2 = 0.1;
T3 = 0.1;
dT = 0.001;
% step = 0.1;
step1 = 0.1;
step2 = 0.1;
step3 = 0.1;
samples1 = [5];
samples2 = [2 3];
samples3 = [2 3 4 6 9 15];
% sucess = zeros(1,length(samples3));
sucess = zeros(1, number);

times1 = 50;  % For sample1 
times2 = 100; % For sample2 
times = 500;

W0 = [1 0.9 0.6];  % w0 and w1 are the weight of two cost function RMS_all and RMS_2D
W1 = 1-W0;         % w0 -> RMS_all,  w1 -> RMS_2D
% ------------------------------------------ %

% ---------- Other parameter ---------- %
range = 150;
RMS_2D_best = 100;
RMS_best = 100;

% ------------------------------------- %
% ------------------------------------------------------------------------ %



% ================================================================================================================= %
% ================================================================================================================= %
% ================================================================================================================= %
% ================================================================================================================= %


% Part.2 Setup 
% ------------------------------------------------------------------------ %
% ---------- Find first order coordinate ---------- %
[v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
v = round(v);
h = round(h);
position = [v,h,range];

% ---------- Generate hologram phase ---------- %
Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed); % [0 255] -> [0 2pi]
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);
% theta_rad = Circle_analytic_phase(pixel,lambda,f,ax1,ay1)

Total_phase = Angle_z + Blazed_phi + theta_rad;
phase = mod(Total_phase,2*pi);

% ---------- CCD setup ---------- %
vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter;
src.Sharpness = Sharpness;
src.Brightness = Brightness;

% ---------- Theory solution ---------- %
para = [1080 1080 f lambda range];
beam_para = [Beam_size Output_x Output_y];
grating_para = [theta_deg repeat level];
data_zoomin_analytic = Simulate_flattop(para,beam_para,grating_para,CCD_pixel);
data_zoomin_analytic = data_zoomin_analytic / max(data_zoomin_analytic(:));

% ------------------------------------------------------------------------ %





% Part.3 Initialize
% ------------------------------------------------------------------------ %
% ---------- The CCD image before Zernike ---------- %
phase_origin = mod(Blazed_phi + theta_rad,2*pi);
vid = videoinput('pointgrey', 1, 'F7_Mono16_2592x1944_Mode0');
src = getselectedsource(vid);
src.Shutter = Shutter;
src.Brightness = Brightness;

close all
move_image_on_screen(move_x, move_y, pixel, phase_origin)
pause(0.1)

image_origin = 0;
for ii = 1:snapshot_times
    % sprintf('Snapshot : %d',ii)
    start(vid);
    data = getdata(vid,1);
    data = double(data);
    stop(vid)
    image_origin = image_origin + data;
end
image_origin = image_origin / snapshot_times;
data_zoomin_origin = image_origin(v-range:v+range,h-range:h+range);
[Shutter,data_zoomin_origin] = Check_shutter(data_zoomin_origin,Shutter,intensity_range,position);
% data_zoomin_origin = data_zoomin_origin(v-range:v+range,h-range:h+range);

% ------------------------------------------------- %

% ---------- Initial Zernike coefficient ---------- %
circle = pupil(pixel_Zernike);
ZZ0 = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z0, Zernike_n, circle);
Angle_z0 = padding(ZZ0, pixel); 

Total_phase0 = Blazed_phi + theta_rad + Angle_z0;
phase0 = mod(Total_phase0,2*pi);

close all
move_image_on_screen(move_x, move_y, pixel, phase0)
pause(0.1)

image = 0;
for ii = 1:snapshot_times
    % sprintf('Snapshot : %d',ii)
    start(vid);
    data = getdata(vid,1);
    data = double(data);
    stop(vid)
    image = image + data;
end
image = image / snapshot_times;

% ------------------------------------------------- %

% ---------- Initial condition ---------- %
data_zoomin = image(v-range:v+range,h-range:h+range);
[Shutter,data_zoomin] = Check_shutter(data_zoomin,Shutter,intensity_range,position);
data_zoomin = data_zoomin / max(data_zoomin(:));

threshold1 = 0.001;
threshold2 = 0.95;
Index1 = Mask(data_zoomin_analytic,threshold1);
Index2 = Mask(data_zoomin_analytic,threshold2);

data_zoomin_2D = data_zoomin(Index2(1):Index2(2),Index2(3):Index2(4));
data_zoomin_2D = data_zoomin_2D / max(data_zoomin_2D(:));
data_zoomin_2D_avg = mean(data_zoomin_2D,'all');
data_zoomin_2D_avg = data_zoomin_2D_avg*ones(size(data_zoomin_2D));

Target = data_zoomin_analytic;
Target_small = Target(Index1(1):Index1(2),Index1(3):Index1(4));
data_zoomin_small = data_zoomin(Index1(1):Index1(2),Index1(3):Index1(4));

RMS00 = RMS_var_ver2(data_zoomin_small, Target_small);
RMS10 = RMS_var_ver2(data_zoomin_2D, data_zoomin_2D_avg);
criteria = 0;
criteria0 = 0;
criteria1 = 0;

change = 0;

% --------------------------------------- %
% ------------------------------------------------------------------------ %





% Part.4 Metropolis algorithm
% ------------------------------------------------------------------------ %
% ---------- Metropolis ---------- %
t0 = clock;
count = 1;
for i = 1:times
    % sprintf('i : %d, Virtual temperature : %g',i,T)
    tic
    % beta = 1/T;

        if i < times1
            samples = samples1; 
            step = step1;
            w0 = W0(1);
            w1 = W1(1);
            if i == 1
                T = T1;
                beta = 1/T;
            end
        elseif i >= times1 && i < times2
            samples = samples2;
            step = step2;
            w0 = W0(2);
            w1 = W1(2);
            if i == times1
                T = T2;
                beta = 1/T;
            end
        else
            samples = samples3;
            step = step3;
            w0 = W0(3);
            w1 = W1(3);
            if i == times2
                T = T3;
                beta = 1/T;
            end
        end
    sprintf('i : %d, Virtual temperature : %g',i,T)

    if i > 1
        n = mod(i,length(samples))+1;
        % R = [-0.03 -0.02 -0.01 0.01 0.02 0.03];
        % r = R(randi(numel(R)));
        r = (rand()-0.5)*2;
        old_z = Z1(samples(n));
        Z_before = Z1;
        Z1(samples(n)) = Z1(samples(n)) + round(step*r,2);
        % Z1(samples(n)) = Z1(samples(n)) + r;
        Z_best1 = Z1;
        new_z = Z1(samples(n));
    end
    
    if i > 1
        ZZ1 = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z1, Zernike_n, circle);
        Angle_z1 = padding(ZZ1, pixel); 
    
        Total_phase1 = Blazed_phi + theta_rad + Angle_z1;
        phase1 = mod(Total_phase1,2*pi);
    
        close all
        move_image_on_screen(move_x, move_y, pixel, phase1)
        pause(0.1)
        
        image1 = 0;
        for ii = 1:snapshot_times
            % sprintf('Snapshot : %d',ii)
            start(vid);
            data1 = getdata(vid,1);
            data1 = double(data1);
            stop(vid)
            image1 = image1 + data1;
        end
        image1 = image1 / snapshot_times;
        data_zoomin1 = image1(v-range:v+range,h-range:h+range);
        [Shutter,data_zoomin1] = Check_shutter(data_zoomin1,Shutter,intensity_range,position);

        data_zoomin1_origin = data_zoomin1;
        data_zoomin1 = data_zoomin1 / max(intensity_range);

        data_zoomin1_small = data_zoomin1(Index1(1):Index1(2),Index1(3):Index1(4));

        data_zoomin1_2D = data_zoomin1(Index2(1):Index2(2),Index2(3):Index2(4));
        data_zoomin1_2D = data_zoomin1_2D / max(data_zoomin1_2D(:));
        data_zoomin1_2D_avg = mean(data_zoomin1_2D,'all');
        data_zoomin1_2D_avg = data_zoomin1_2D_avg*ones(size(data_zoomin1_2D));

        RMS01 = RMS_var_ver2(data_zoomin1_small, Target_small);
        RMS11 = RMS_var_ver2(data_zoomin1_2D, data_zoomin1_2D_avg);
    end

    if i > 1
        P00 = exp(-beta*RMS00);
        P01 = exp(-beta*RMS01);
        P10 = exp(-beta*RMS10);
        P11 = exp(-beta*RMS11);        
        criteria0 = min(1,P01/P00);
        criteria1 = min(1,P11/P10);
        criteria = criteria0*w0 + criteria1*w1;

        sprintf('All region RMS var : %g -> %g',RMS00,RMS01)
        sprintf('2D region RMS var : %g -> %g',RMS10,RMS11)
        sprintf('criteria0 : %g, criteria1 : %g, criteria : %g',criteria0,criteria1,criteria)
    end

    if criteria >= 1 &&  i > 1
        T = T - dT;
        if RMS_2D_best > RMS11
            data_zoomin_best = data_zoomin1_origin;
            Z_best = Z_best1;
            RMS_2D_best = RMS11;
            RMS_best = RMS01;
        end

        % Z_best = Z0;
        RMS00 = RMS01;
        RMS10 = RMS11;
        % RMS20 = RMS21;
        change = 1;
        sucess(samples(n)) = sucess(samples(n)) + 1;
        sprintf('Z(%g) : %g -> %g,  Sucess!',samples(n),old_z,new_z)
    end

    if criteria < 1 && criteria0 > 0.01 && criteria1 > 0.01 && i > 1
        c = criteria;

        ran = rand();
        if c > ran
            if RMS_2D_best > RMS11
                data_zoomin_best = data_zoomin1_origin;
                Z_best = Z_best1;
                RMS_2D_best = RMS11;
                RMS_best = RMS01;
            end

            T = T - dT;
            RMS00 = RMS01;
            RMS10 = RMS11;
            change = 1;
            sucess(samples(n)) = sucess(samples(n)) + 1;
            sprintf('Z(%g) : %g -> %g,  Sucess!',samples(n),old_z,new_z)
        else
            Z1 = Z_before;
            change = 0;
            sprintf('Z(%g) : %g -> %g,  Fail!',samples(n),old_z,new_z)
        end
    elseif criteria < 1 && (criteria0 <= 0.01 || criteria1 <= 0.01) && i > 1
        Z1 = Z_before;
        change = 0;
        sprintf('Z(%g) : %g -> %g,  Fail!',samples(n),old_z,new_z)
    end

    Elapsed_time = etime(clock,t0);

    RMS00_array(i) = RMS00;
    RMS10_array(i) = RMS10;
    Data(i,:) = [i T Z1 RMS00 RMS10 criteria0 criteria1 criteria change Elapsed_time];

    toc
end


% ------------------------------------------------------------------------ %





% ------------------------------------------------------------------------ %
data_zoomin_best_2D = data_zoomin_best / max(data_zoomin_best(:));
data_zoomin_best_2D = data_zoomin_best_2D(Index2(1):Index2(2),Index2(3):Index2(4));
data_zoomin_best_2D_avg = ones(size(data_zoomin_best_2D))*mean(data_zoomin_best_2D,'all');

f1 = figure;
imagesc(data_zoomin_best,intensity_range)
axis image
colormap turbo
colorbar
title('CCD image')
xlabel(sprintf('2.2\\mum/pixel'));ylabel(sprintf('2.2\\mum/pixel'));

f2 = figure;
plot(1:length(data_zoomin_best),data_zoomin_best(round(range),:))
xlabel(sprintf('2.2\\mum/pixel')); ylabel('Intensity')
xlim([0 2*range+1])
title('Transverse plane')

f3 = figure;
yyaxis left
scatter(1:times,RMS00_array,10','filled')
ylabel('RMSva var.')
yyaxis right
scatter(1:times,RMS10_array,10','filled')
legend('All region','2D region')
xlabel('Times'); ylabel('RMSva var.')
title('Times - RMS var.')

f4 = figure;
bar(1:number,sucess)
xlabel('Zernike mode', 'Interpreter','latex')
ylabel('Change times', 'Interpreter','latex')

f5 = figure;
subplot(1,3,1)
imagesc(data_zoomin_origin,intensity_range)
axis image
title('Before Zernike')
subplot(1,3,2)
imagesc(data_zoomin_best,intensity_range)
axis image
title('After Zernike')
subplot(1,3,3)
imagesc(Target)
axis image
colormap turbo
title('Target')

f6 = figure;
subplot(1,2,1)
imagesc(data_zoomin_best_2D,[0.8 1])
axis image
title('After Zernike')
colorbar
subplot(1,2,2)
imagesc(data_zoomin_best_2D_avg,[0.8 1])
axis image
colormap turbo
title('Average')
colorbar

f7 = figure;
contour_height1 = 0.8;
contour_height2 = 0.3;

data_zoomin_max = max(data_zoomin_best(:));
data_zoomin_analytic_max = max(data_zoomin_analytic(:));

contour(data_zoomin_best, [contour_height1*data_zoomin_max, contour_height1*data_zoomin_max], 'LineColor', 'black', 'LineWidth', 1); 
hold on
contour(data_zoomin_analytic, [contour_height1*data_zoomin_analytic_max, contour_height1*data_zoomin_analytic_max], 'LineColor', 'r', 'LineWidth', 1);
legend('CCD data contour','Analytic result contour')
title(sprintf('Contour line height : %g',contour_height1))
axis image

f8 = figure;
yyaxis left
scatter(1:times,RMS00_array,10','filled')
set(gca, 'YScale', 'log')
ylabel('RMS var.')
yyaxis right
scatter(1:times,RMS10_array,10','filled')
legend('All region','2D region')
xlabel('Times'); ylabel('RMS var.')
title('Times - RMS var.')

RMS_BSET = [RMS_best RMS_2D_best];




% -------------- Save the results -------------- %
% path = pwd;
% cd('G:\Other computers\yan\Files\Lab\Experiment_records\20250522_square_circle_flat_top')
% exportgraphics(f1,append('Best_CCD_image_',Get_time(),'.png'))
% exportgraphics(f2,append('Best_transverse_plane_',Get_time(),'.png'))
% exportgraphics(f3,append('Times_RMSvar_',Get_time(),'.png'))
% exportgraphics(f4,append('Sucess_bar_',Get_time(),'.png'))
% exportgraphics(f5,append('Before_and_After_',Get_time(),'.png'))
% exportgraphics(f6,append('2D_region_',Get_time(),'.png'))
% exportgraphics(f7,append('Contour_line_',Get_time(),'.png'))
% exportgraphics(f8,append('Times_RMSvar_log_',Get_time(),'.png'))
% writematrix(Z_best,append('Z_best_',Get_time(),'.csv'))
% writematrix(data_zoomin_best,append('Data_',Get_time(),'.csv'))
% writematrix(Data,append('Detail_data_',Get_time(),'.csv'))
% writematrix(RMS_BSET,append('RMS_best_',Get_time(),'.csv'))
% cd(path)

Elapsed_time1 = etime(clock,t00)





function time = Get_time()
    t = clock;
    time = sprintf('%g_%g_%g_%g_%g_%g',t(1),t(2),t(3),t(4),t(5),t(6));
end

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