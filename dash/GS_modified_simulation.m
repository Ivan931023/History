clc
clear all
close all

% imaqreset   %%% Reset CCD
% imaqhwinfo
% imaqhwinfo('pointgrey')
% imaqhwinfo('gige')
tic
% Part.1 Parameters
% ------------------------------------------------------------------------ %
% ---------- Beam parameter ---------- %
f = 300;                 % Focal length (mm)
lambda = 447e-6;         % Wave length (mm)
CCD_pixel_size = 2.2e-3; % (mm)
dx = 8e-3;               % (mm)
% pixel = round(lambda*f / (dx*CCD_pixel_size),-1);  % According to Fourier optics
pixel = 1080;          % The phase pattern size(SLM) 
pixel_phase = 50;     % Noise region
% pixel_signal = 400;
Beam_size = 20;           % 1/e^2 intensity (mm)

% ---------- Target parameter ---------- %
w = 20;
l = 20;

% ---------- Other parameter ---------- %
range = 150;         % The size of figure after zoom in
iteration = 100;
e_ratio = 0.3;

% ------------------------------------- %


% ---------- SLM plane ---------- %
Nx = pixel;
Ny = pixel;

dy = dx; % (mm)
Lx = Nx * dx; % (mm)
Ly = Ny * dy; % (mm)
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);


% ---------- Input beam power ---------- %
x0 = 0;
y0 = 0;

sig_x = Beam_size / 4;
sig_y = Beam_size / 4;

Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2)) ; % Gaussian beam
Input_beam = Input_beam ./ max(Input_beam(:));

% ---------- Quadratic phase ---------- %
m = linspace(-pixel_phase/2, pixel_phase/2-1, pixel_phase);
n = linspace(-pixel_phase/2, pixel_phase/2-1, pixel_phase);
[M, N] = meshgrid(m, -n);

r = pi/pixel_phase; % The parameter of quadratic phase
% a = 0.014;
% b = 0.014;
a = r;
b = r;

phi = a*M.^2 + b*N.^2; % The phase of quadratic phase
% phi = a*M.^2; % The phase of quadratic phase
% phi = b*N.^2;
% phi = rand(pixel_phase)*2*pi; % ---- Test random phase
% phi = ones(pixel_phase)*pi;



% ---------- Target ---------- %
center = round(pixel_phase/2);
Target_intensity = zeros(pixel_phase);
Target_intensity(center-l:center+l,center-w:center+w) = 1;
% Target_intensity = Target_intensity * 10000000;

exp_phase = exp(1j*(phi));
Target_phase = padding(exp_phase,pixel);
% circle = pupil(pixel_phase);
% circle = padding(circle,pixel);
% Target_phase = Target_phase .* circle;

% figure
% imshow(Angle_0_2pi(Target_phase),[0 2*pi])

c = round(pixel/2);
spectrum = abs(DFT(Target_phase)).^2;
imagesc_turbo(spectrum)
hold on
rectangle('Position', [c-round(pixel/2), c-round(pixel/2), ...
          pixel, pixel],'EdgeColor', 'r', 'LineWidth', 2);
hold on
rectangle('Position', [c-round(pixel_phase/2), c-round(pixel_phase/2), ...
          pixel_phase, pixel_phase],'EdgeColor', 'b', 'LineWidth', 2);
h1 = plot(NaN, NaN, 'r-', 'LineWidth', 2);
h2 = plot(NaN, NaN, 'b-', 'LineWidth', 2);
legend([h1,h2],{'Noise region','Signal region'})


% path = pwd;
% cd('I:\其他電腦\yan\Files\程式語言\Matlab\Error_diffusion_code\data')
% data = imread('mindy_1080.jpg');
% data = im2gray(data);
% data = im2double(data);
% data = double(data);
% Target_intensity = imresize(data, [150 150], 'bilinear');
% cd(path)





center = pixel_phase/2;
% 
% Target_intensity = zeros(pixel_phase);
% Target_intensity(center-l:center+l,center-w:center+w) = 1;
% 
Target_intensity = padding(Target_intensity,pixel);


% ------ Calculate the first iteration power ------
initial = sum(abs(DFT(Input_beam)).^2,'all');

Target_power_before = sum(abs(Target_intensity).^2,'all');  % Test the power before power correction
Target_power_before
r = initial / Target_power_before;        % The relation between before and after power correction
Target_intensity = Target_intensity * sqrt(r) * sqrt(e_ratio);      % Power correction use the function "Calculate_initial_power"
Target_power_after = sum(abs(Target_intensity).^2,'all');   % Test the power after power correction
Target_power_after
% ------------------------------ GS algorithm --------------------------------------

Target = Target_intensity .* Target_phase;


u = Target;
uu = u;

% sum(abs(uu).^2,'all')

f1 = figure;
for t = 1:iteration
    % t
    % ------ Focal plane --> hologram_plane ------
    SLM_field = IDFT(u);  
    % sum(abs(SLM_field).^2,'all')
    SLM_phase = Angle_0_2pi(SLM_field);
    SLM_intensity = abs(SLM_field).^2;

    % ------ hologram_plane --> Focal plane ------
    focal_field = DFT(Input_beam.*exp(1j*SLM_phase));
    % focal_field = DFT(exp(1j*SLM_phase));
    focal_field_before = focal_field;
    focal_field_before_small = focal_field(c-center+2:c+center-2,c-center+2:c+center-2);
    eta(t) = sum(abs(focal_field_before_small).^2,'all');
    % eta_all_before(t) = sum(abs(focal_field_before).^2,'all');
    focal_field_intensity = abs(focal_field).^2;

    %------ Define signal and noise region ------
    for xx = 1:pixel
        for yy = 1:pixel
            if xx > (pixel-pixel_phase)/2 && xx < (pixel+pixel_phase)/2 && yy > (pixel-pixel_phase)/2 && yy < (pixel+pixel_phase)/2
                focal_field(xx,yy) = uu(xx,yy);
            end
        end
    end

    % focal_field_before = focal_field;
    % x1 = (pixel-pixel_phase)/2+1;
    % x2 = (pixel+pixel_phase)/2;
    % y1 = (pixel-pixel_phase)/2 + (pixel_phase-pixel_signal)/2 + 1;
    % y2 = (pixel-pixel_phase)/2 + (pixel_phase+pixel_signal)/2;
    % for xx = x1:x2
    %     for yy = x1:x2
    %         if xx > y1 && xx < y2 && yy > y1 && yy < y2
    %             focal_field(xx,yy) = uu(xx,yy);
    %         end
    %     end
    % end
    
    r1 = sum(abs(focal_field_before).^2,'all') / sum(abs(focal_field).^2,'all');
    focal_field = focal_field * sqrt(r1);
    focal_field_after = focal_field;
    % eta_all_after(t) = sum(abs(focal_field_after).^2,'all');
    
    u = focal_field;


    % T1 = focal_field_before(pixel/2,:);
    figure(f1)
    L1 = pixel/2-pixel_phase/2+1:pixel/2+pixel_phase/2-1;
    T1 = focal_field_before(pixel/2,L1);
    T1 = T1 / max(T1(:));
    plot(1:length(L1),abs(T1).^2)
    xlim([1 length(L1)])
    title(sprintf('iteration = %d',t))
end


% hold on
% plot(1:iteration,eta_all_before)
% hold on
% plot(1:iteration,eta_all_after)




% L1 = pixel/2-pixel_phase/2+1:pixel/2+pixel_phase/2-1;
% T1 = focal_field_before(pixel/2,L1);
% T2 = focal_field_after(pixel/2,L1);
% figure
% yyaxis left
% plot(1:length(L1),abs(T1).^2)
% hold on
% yyaxis right
% plot(1:length(L1),abs(T2).^2)



c = round(pixel/2);
figure
imagesc(Input_beam)
colormap turbo
colorbar
axis image
hold on
rectangle('Position', [c-round(pixel/2), c-round(pixel/2), ...
          pixel, pixel],'EdgeColor', 'r', 'LineWidth', 2);
hold on
rectangle('Position', [c-round(pixel_phase/2), c-round(pixel_phase/2), ...
          pixel_phase, pixel_phase],'EdgeColor', 'b', 'LineWidth', 2);
h1 = plot(NaN, NaN, 'r-', 'LineWidth', 2);
h2 = plot(NaN, NaN, 'b-', 'LineWidth', 2);
legend([h1,h2],{'Noise region','Signal region'})


c1 = round(pixel/2);
r1 = (pixel_phase/2) - 2;
focal_field_before_small = focal_field_before(c1-r1:c1+r1,c1-r1:c1+r1);
focal_field_after_small = focal_field_after(c1-r1:c1+r1,c1-r1:c1+r1);

% figure
% subplot(1,2,1)
% imagesc(abs(focal_field_before).^2)
% axis image
% colormap turbo
% colorbar
% title('Focal field (before)')
% subplot(1,2,2)
% imagesc(abs(focal_field_after).^2)
% axis image
% colormap turbo
% colorbar
% title('Focal field (after)')

% figure
% subplot(1,2,1)
% imagesc(abs(focal_field_before_small).^2)
% axis image
% colormap turbo
% colorbar
% title('Focal field (before)')
% subplot(1,2,2)
% imagesc(abs(focal_field_after_small).^2)
% axis image
% colormap turbo
% colorbar
% title('Focal field (after)')


% figure
% subplot(1,2,1)
% imshow(Angle_0_2pi(focal_field_before),[0 2*pi])
% axis image
% axis on
% colorbar
% subplot(1,2,2)
% imshow(Angle_0_2pi(focal_field_after),[0 2*pi])
% axis image
% colorbar
% axis on

focal_field_intensity = focal_field_intensity / max(focal_field_intensity(:));


eta_nor = eta / max(eta(:));
f2 = figure;
plot(1:iteration,eta_nor)
hold on
plot(1:iteration,ones(1,iteration)*Target_power_after / max(eta(:)))
ylim([0 1])
xlabel('Iteration')
ylabel('Normalized intensity')
legend('Current intensity','Target intensity')

f3 = figure;
I = abs(focal_field_before).^2;
imagesc(abs(focal_field_before).^2,[0 max(I(:))])
axis image
colormap turbo
% set(gca,'XTick',[0 200 400 600 800 1000])
% set(gca,'YTick',[0 200 400 600 800 1000])

focal_field_before_small = focal_field_before_small / max(focal_field_before_small(:));
f4 = figure;
imagesc(abs(focal_field_before_small).^2,[0 1])
axis image
colormap turbo
% set(gca,'XTick',[0 20 40 60 80 100])
% set(gca,'YTick',[0 20 40 60 80 100])

% path = pwd;
% cd('I:\其他電腦\yan\Files\Lab\Experiment_records\GS_modified_important\Square')
% exportgraphics(f1,'Transverse_eratio_%g_signal_%g.png',e_ratio,pixel_phase)
% exportgraphics(f2,'Intensity_iteration_%g_signal_%g.png',e_ratio,pixel_phase)
% exportgraphics(f3,'Image_eratio_%g_signal_%g.png',e_ratio,pixel_phase)
% exportgraphics(f4,'Image_zoomin_eratio_%g_signal_%g.png',e_ratio,pixel_phase)
% cd(path)

toc


% ------ DFT ------
function result = DFT(u, pixel)
    result = fftshift(fft2(ifftshift(u)));
end

% ------ IDFT ------
function result = IDFT(u, pixel)
    result = fftshift(ifft2(ifftshift(u)));
end

function initial = Calculate_initial_power(Input_beam,Target,pixel,pixel_phase,exp_phase_pad)
    Target_pad = padding(Target,pixel);
    u = Target_pad .* exp_phase_pad;
    function_holo = IDFT(u);
    function_holo_phase = Angle_0_2pi(function_holo);
    function_holo_exp_phase = exp(1j*function_holo_phase);
    function_focal = DFT(Input_beam .* function_holo_exp_phase);
    % function_focal = DFT(function_holo_exp_phase);
    power_before1 = 0;
    % Only calculate signal region
    for xx = 1:pixel
        for yy = 1:pixel
            if xx > (pixel-pixel_phase)/2 && xx <= (pixel+pixel_phase)/2 && yy > (pixel-pixel_phase)/2 && yy <= (pixel+pixel_phase)/2
                power_before1 = power_before1 + abs(function_focal(xx,yy).^2);
            end
        end  
    end
    initial = power_before1;
end

