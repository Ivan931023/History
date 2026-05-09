clc
clear all

N = 1000;
dx = 2e-3; % (mm)
range = 5;
x = linspace(-range/2, range/2, N);
% ox = linspace(-2, 2, N/5);
ox = linspace(-range/2, range/2, N);
n = length(x);

L = 0.5;
gamma = 5;
U = cos(2*pi*gamma*x);
sig = 0.1;
% U = exp(-(x.^2/2/(sig)^2)) ;
for t = 1:length(U)
    if abs(x(t)) > L
        U(t) = 0;
    end
end

sigx = 0.5; % Target
sig = 0.3; % initial_profile
sigx = 0.5; % Target
sig = 0.5; % initial_profile
px = 5;
x0 = 0;
A = 1;
wl = 447e-6;
% wl = 505.7e-6;
k = 2*pi/wl;
f = 275;
iteration = 100;
z = 10;

initial_profile = A*exp(-((x-x0).^2/2/(sig)^2)) ; % Gaussian beam
Target = SuperGaussian(1, ox, 0, sigx, px);

f1 = figure;
f2 = figure;

figure(f1)
y = initial_profile;
plot(x, y)
hold on

plot(ox, Target)

% DOE = rand(1, n)*2*pi;
DOE = ones(1, n)*pi;
DOEphase = exp(1j * DOE);
y_focal = sqrt((dx/(1j*wl*z)))*exp((1j*pi*ox.^2)/(wl*z)).*...
          (U.*exp((1j*pi*x.^2)/(wl*z))* ...
          exp((-1j*2*pi)/(wl*z) * transpose(x)*ox ));
y_focal = y_focal / max(y_focal,[],'all');

figure(f2)
% ------------------- GS algorithm ------------------
for t = 1:iteration
    DOEphase = exp(1j * DOE);
    y_focal = FourierTransform(x, ox, initial_profile .* DOEphase, f, wl);
    y_focal_phase = angle(y_focal);
    y_focal_intensity = abs(y_focal).^2;
    y_focal_intensity = y_focal_intensity / max(y_focal_intensity,[],'all');
    exp_focal_phase = exp(1j*y_focal_phase);

    %----------------Inverse Fourier transform------ focal->SLM plane
    y_SLM = InverseFourierTransform(x, ox, Target .* exp_focal_phase, f, wl);
    y_SLM_phase = angle(y_SLM);
    DOE = y_SLM_phase;
    pause('on')
    pause(0.05)
    pause('off')
    plot(ox, y_focal_intensity)
    hold on
    t
    error = sum(y_focal_intensity - Target)/sum(Target)*100
end

f3 = figure();
figure(f3)
plot(ox, y_focal_intensity)
hold on
plot(ox, Target)

error = (y_focal_intensity - Target)/Target*100


function SG = SuperGaussian(A, x, x0, sigx, px)
    SG = A*exp(-((x-x0).^2/2/sigx^2).^px);
end

function FT = FourierTransform(x, ox, func, f, l)
    factor = f * l;
    u = ox / factor;
    u_x = exp(-1j*2*pi*(x' * u));
    FT = func*u_x ;
end

function INFT = InverseFourierTransform(x, ox, func, f, l)
    factor = f * l;
    u = x / factor;
    u_x = exp(1j*2*pi*(ox' * u));
    INFT = func*u_x ;
end
