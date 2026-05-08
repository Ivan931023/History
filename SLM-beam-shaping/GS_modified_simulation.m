clc
clear all
close all
tic

f = 300;
lambda = 447e-6;
dx = 8e-3;
pixel = 1080;
pixel_phase = 50;
Beam_size = 20;
w = 20; l = 20;
range = 150;
iteration = 100;
e_ratio = 0.3;

Nx = pixel; Ny = pixel;
dy = dx;
x = -Nx/2*dx : dx : (Nx/2-1)*dx;
y = -Ny/2*dy : dy : (Ny/2-1)*dy;
[X, Y] = meshgrid(x, -y);

sig_x = Beam_size / 4;
sig_y = Beam_size / 4;
Input_beam = exp(-(X.^2/2/sig_x^2+Y.^2/2/sig_y^2));
Input_beam = Input_beam ./ max(Input_beam(:));

m = linspace(-pixel_phase/2, pixel_phase/2-1, pixel_phase);
n_v = linspace(-pixel_phase/2, pixel_phase/2-1, pixel_phase);
[M, N] = meshgrid(m, -n_v);
r = pi/pixel_phase;
a = r; b = r;
phi = a*M.^2 + b*N.^2;

center_s = round(pixel_phase/2);
Target_intensity = zeros(pixel_phase);
Target_intensity(center_s-l:center_s+l,center_s-w:center_s+w) = 1;

exp_phase = exp(1j*(phi));
Target_phase = padding(exp_phase,pixel);
c = round(pixel/2);
spectrum = abs(DFT(Target_phase)).^2;
imagesc_turbo(spectrum)

Target_intensity = padding(Target_intensity,pixel);
initial = sum(abs(DFT(Input_beam)).^2,'all');
Target_power_before = sum(abs(Target_intensity).^2,'all');
r_pow = initial / Target_power_before;
Target_intensity = Target_intensity * sqrt(r_pow) * sqrt(e_ratio);
Target_power_after = sum(abs(Target_intensity).^2,'all');

Target = Target_intensity .* Target_phase;
u = Target;
uu = u;
eta = zeros(1,iteration);

f1 = figure;
for t = 1:iteration
    SLM_field = IDFT(u);
    SLM_phase = Angle_0_2pi(SLM_field);
    focal_field = DFT(Input_beam.*exp(1j*SLM_phase));
    focal_field_before = focal_field;
    L1 = pixel/2-pixel_phase/2+1:pixel/2+pixel_phase/2-1;
    focal_field_before_small = focal_field(pixel/2,L1);
    eta(t) = sum(abs(focal_field(c-center_s+2:c+center_s-2,c-center_s+2:c+center_s-2)).^2,'all');
    focal_field_intensity = abs(focal_field).^2;
    for xx = 1:pixel
        for yy = 1:pixel
            if xx > (pixel-pixel_phase)/2 && xx < (pixel+pixel_phase)/2 && yy > (pixel-pixel_phase)/2 && yy < (pixel+pixel_phase)/2
                focal_field(xx,yy) = uu(xx,yy);
            end
        end
    end
    r1 = sum(abs(focal_field_before).^2,'all') / sum(abs(focal_field).^2,'all');
    focal_field = focal_field * sqrt(r1);
    focal_field_after = focal_field;
    u = focal_field;
    figure(f1)
    T1 = focal_field_before(pixel/2,L1);
    T1 = T1 / max(T1(:));
    plot(1:length(L1),abs(T1).^2)
    xlim([1 length(L1)])
    title(sprintf('iteration = %d',t))
end

eta_nor = eta / max(eta(:));
f2 = figure;
plot(1:iteration,eta_nor)
hold on
plot(1:iteration,ones(1,iteration)*Target_power_after / max(eta(:)))
ylim([0 1])
xlabel('Iteration'); ylabel('Normalized intensity')
legend('Current intensity','Target intensity')

c1 = round(pixel/2);
r1_s = (pixel_phase/2) - 2;
focal_field_before_small = focal_field_before(c1-r1_s:c1+r1_s,c1-r1_s:c1+r1_s);
focal_field_before_small = focal_field_before_small / max(focal_field_before_small(:));

f3 = figure;
I = abs(focal_field_before).^2;
imagesc(I,[0 max(I(:))]); axis image; colormap turbo

f4 = figure;
imagesc(abs(focal_field_before_small).^2,[0 1]); axis image; colormap turbo

toc

function result = DFT(u)
    result = fftshift(fft2(ifftshift(u)));
end
function result = IDFT(u)
    result = fftshift(ifft2(ifftshift(u)));
end
