clc
clear all

r = 0.011;
a = r;
b = r;

pixel = 256; % For quadratic phase

m = linspace(-pixel/2, pixel/2-1, pixel); % Coordinate value
n = linspace(-pixel/2, pixel/2-1, pixel);
[M, N] = meshgrid(m, -n);

p = m;
q = n;

% ------ Quadratic phase ------
phi = a*M.^2 + b*N.^2;
exp_phase = exp(1j*(phi));
exp_phase_angle = Angle_0_2pi(exp_phase); % Convert angle:[-pi pi] to [0 2*pi]

exp_pm = exp(-1j*2*pi*(p' * m / pixel));
exp_qn = exp(-1j*2*pi*(q' * n / pixel));
result = exp_pm * exp_phase * exp_qn ;


result_intensity = abs(result).^2;
result_intensity = result_intensity / max(result_intensity,[],'all');

result_angle = Angle_0_2pi(result);
subplot(1,2,1)
imshow(mat2gray(exp_phase_angle))
subplot(1,2,2)
imshow(mat2gray(result_angle))

function FT = FourierTransform(x, y, ox, oy, func, f, l)
    factor = f * l;
    u = ox / factor;
    v = oy / factor;
    u_x = exp(-1j*2*pi*(x' * u));
    v_y = exp(-1j*2*pi*(v' * y));
    FT = v_y*func*u_x ;
end
