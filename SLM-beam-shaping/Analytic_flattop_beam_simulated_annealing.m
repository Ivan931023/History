clc
clear all
close all

t00 = clock;

lambda = 447e-6; f = 300;
Beam_size = 3.7;
Output_x = 0.4; Output_y = 0.4;
a = Beam_size / (2*sqrt(2));
ax1 = a; ax2 = Output_x / 2; ay1 = a; ay2 = Output_y / 2;

pixel = 1080; pixel_Zernike = 750;
move_x = -90; move_y = 130;

CCD_mode = 'F7_Mono16_2592x1944_Mode0';
Find_beam_order = 'First_order';
intensity_range = [0 65280];
Shutter = 0.84; Sharpness = 0; Exposure = -3.5; Brightness = 0;
snapshot_times = 5;
CCD_pixel = 2.2e-3;

theta_deg = -90; theta_blazed = deg2rad(theta_deg);
max_phase = 255; min_phase = 0; repeat = 1; level = 16;

Zernike_n = 4;
number = Find_number(Zernike_n);
Z = zeros(1,number);
Z0 = Z; Z1 = Z0;

T1 = 0.1; T2 = 0.1; T3 = 0.1; dT = 0.001;
step1 = 0.1; step2 = 0.1; step3 = 0.1;
samples1 = [5]; samples2 = [2 3]; samples3 = [2 3 4 6 9 15];
sucess = zeros(1, number);
times1 = 50; times2 = 100; times = 500;
W0 = [1 0.9 0.6]; W1 = 1-W0;

range = 150;
RMS_2D_best = 100; RMS_best = 100;

[v, h] = Find_beam(theta_deg,repeat,level,Find_beam_order,CCD_mode);
v = round(v); h = round(h);
position = [v,h,range];

Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n);
Blazed_phi = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed);
theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2);
Total_phase = Angle_z + Blazed_phi + theta_rad;
phase = mod(Total_phase,2*pi);

vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter; src.Sharpness = Sharpness; src.Brightness = Brightness;

para = [1080 1080 f lambda range];
beam_para = [Beam_size Output_x Output_y];
grating_para = [theta_deg repeat level];
data_zoomin_analytic = Simulate_flattop(para,beam_para,grating_para,CCD_pixel);
data_zoomin_analytic = data_zoomin_analytic / max(data_zoomin_analytic(:));

% Initialize
phase_origin = mod(Blazed_phi + theta_rad,2*pi);
close all
move_image_on_screen(move_x, move_y, pixel, phase_origin)
pause(0.1)
image_origin = 0;
for ii = 1:snapshot_times
    start(vid); data = getdata(vid,1); data = double(data); stop(vid)
    image_origin = image_origin + data;
end
image_origin = image_origin / snapshot_times;
data_zoomin_origin = image_origin(v-range:v+range,h-range:h+range);
[Shutter,data_zoomin_origin] = Check_shutter(data_zoomin_origin,Shutter,intensity_range,position);

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
    start(vid); data = getdata(vid,1); data = double(data); stop(vid)
    image = image + data;
end
image = image / snapshot_times;

data_zoomin = image(v-range:v+range,h-range:h+range);
[Shutter,data_zoomin] = Check_shutter(data_zoomin,Shutter,intensity_range,position);
data_zoomin = data_zoomin / max(data_zoomin(:));

threshold1 = 0.001; threshold2 = 0.95;
Index1 = Mask(data_zoomin_analytic,threshold1);
Index2 = Mask(data_zoomin_analytic,threshold2);

data_zoomin_2D = data_zoomin(Index2(1):Index2(2),Index2(3):Index2(4));
data_zoomin_2D = data_zoomin_2D / max(data_zoomin_2D(:));
data_zoomin_2D_avg = mean(data_zoomin_2D,'all') * ones(size(data_zoomin_2D));

Target = data_zoomin_analytic;
Target_small = Target(Index1(1):Index1(2),Index1(3):Index1(4));
data_zoomin_small = data_zoomin(Index1(1):Index1(2),Index1(3):Index1(4));

RMS00 = RMS_var_ver2(data_zoomin_small, Target_small);
RMS10 = RMS_var_ver2(data_zoomin_2D, data_zoomin_2D_avg);
criteria = 0; criteria0 = 0; criteria1 = 0; change = 0;

% Metropolis loop
t0 = clock;
for i = 1:times
    tic
    if i < times1
        samples = samples1; step = step1; w0 = W0(1); w1 = W1(1);
        if i == 1; T = T1; beta = 1/T; end
    elseif i >= times1 && i < times2
        samples = samples2; step = step2; w0 = W0(2); w1 = W1(2);
        if i == times1; T = T2; beta = 1/T; end
    else
        samples = samples3; step = step3; w0 = W0(3); w1 = W1(3);
        if i == times2; T = T3; beta = 1/T; end
    end

    if i > 1
        n = mod(i,length(samples))+1;
        r = (rand()-0.5)*2;
        old_z = Z1(samples(n));
        Z_before = Z1;
        Z1(samples(n)) = Z1(samples(n)) + round(step*r,2);
        Z_best1 = Z1;
        new_z = Z1(samples(n));

        ZZ1 = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z1, Zernike_n, circle);
        Angle_z1 = padding(ZZ1, pixel);
        Total_phase1 = Blazed_phi + theta_rad + Angle_z1;
        phase1 = mod(Total_phase1,2*pi);
        close all
        move_image_on_screen(move_x, move_y, pixel, phase1)
        pause(0.1)
        image1 = 0;
        for ii = 1:snapshot_times
            start(vid); data1 = getdata(vid,1); data1 = double(data1); stop(vid)
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
        data_zoomin1_2D_avg = mean(data_zoomin1_2D,'all') * ones(size(data_zoomin1_2D));
        RMS01 = RMS_var_ver2(data_zoomin1_small, Target_small);
        RMS11 = RMS_var_ver2(data_zoomin1_2D, data_zoomin1_2D_avg);

        P00 = exp(-beta*RMS00); P01 = exp(-beta*RMS01);
        P10 = exp(-beta*RMS10); P11 = exp(-beta*RMS11);
        criteria0 = min(1,P01/P00);
        criteria1 = min(1,P11/P10);
        criteria = criteria0*w0 + criteria1*w1;
    end

    if criteria >= 1 && i > 1
        T = T - dT;
        if RMS_2D_best > RMS11
            data_zoomin_best = data_zoomin1_origin; Z_best = Z_best1;
            RMS_2D_best = RMS11; RMS_best = RMS01;
        end
        RMS00 = RMS01; RMS10 = RMS11; change = 1;
        sucess(samples(n)) = sucess(samples(n)) + 1;
    end

    if criteria < 1 && criteria0 > 0.01 && criteria1 > 0.01 && i > 1
        ran = rand();
        if criteria > ran
            if RMS_2D_best > RMS11
                data_zoomin_best = data_zoomin1_origin; Z_best = Z_best1;
                RMS_2D_best = RMS11; RMS_best = RMS01;
            end
            T = T - dT; RMS00 = RMS01; RMS10 = RMS11; change = 1;
            sucess(samples(n)) = sucess(samples(n)) + 1;
        else
            Z1 = Z_before; change = 0;
        end
    elseif criteria < 1 && (criteria0 <= 0.01 || criteria1 <= 0.01) && i > 1
        Z1 = Z_before; change = 0;
    end

    Elapsed_time = etime(clock,t0);
    RMS00_array(i) = RMS00;
    RMS10_array(i) = RMS10;
    Data(i,:) = [i T Z1 RMS00 RMS10 criteria0 criteria1 criteria change Elapsed_time];
    toc
end

% Plot results
f1 = figure; imagesc(data_zoomin_best,intensity_range); axis image; colormap turbo; colorbar; title('Best CCD image')
f3 = figure;
yyaxis left; scatter(1:times,RMS00_array,10,'filled'); ylabel('RMS var.')
yyaxis right; scatter(1:times,RMS10_array,10,'filled'); legend('All region','2D region'); xlabel('Times')
f4 = figure; bar(1:number,sucess); xlabel('Zernike mode'); ylabel('Change times')

Elapsed_time1 = etime(clock,t00)

function time = Get_time()
    t = clock;
    time = sprintf('%g_%g_%g_%g_%g_%g',t(1),t(2),t(3),t(4),t(5),t(6));
end
