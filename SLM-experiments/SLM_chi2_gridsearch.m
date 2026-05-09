clc;
clear;
close all;

% ------------------------ Parameters ------------------------ %
pixel = 108;
x = linspace(-1, 1, pixel);
y = linspace(-1, 1, pixel);
[X, Y] = meshgrid(x, y);

a = 12;             % Grating amplitude [rad]
Lambda = 1;         % Grating period [normalized units]
a_2pi = 206;        % Voltage-to-2pi scale factor
alpha_peak = 12;    % Max cavity offset (rad)

% True values for simulation
r_true = 0.055;
w_true = 0.75;

% ------------------ Ground truth simulation ------------------ %
% Step 1: θ(x,y) — phase grating along y
theta_true = a / a_2pi * mod(2 * pi * Y / Lambda, 2 * pi);

% Step 2: Gaussian crosstalk kernel
g_true = fspecial('gaussian', 2*ceil(5*w_true)+1, w_true);

% Step 3: Convolution θ * g
theta_conv_true = conv2(theta_true, g_true, 'same');

% Step 4: α(x,y) — cavity phase shift (elliptical paraboloid)
alpha_true = alpha_peak * (1 - (X.^2 + 0.5*Y.^2));

% Step 5: φ(x,y) = θ * g + α
phi_true = theta_conv_true + alpha_true;

% Step 6: E(x,y) — cavity-enhanced field
E_true = (r_true + exp(1i * phi_true)) ./ (1 + r_true * exp(1i * phi_true));

% Step 7: Target intensity (measurement)
I_target = abs(E_true).^2;

% ------------------------ Grid Search ------------------------ %
r_list = 0.01:0.01:0.10;
w_list = 0.2:0.1:1.4;
Chi2 = zeros(length(r_list), length(w_list));

% Begin grid search
for i = 1:length(r_list)
    r = r_list(i);
    for j = 1:length(w_list)
        w = w_list(j);
        
        % Create PSF kernel
        g = fspecial('gaussian', 2*ceil(5*w)+1, w);
        
        % Convolve theta
        theta_conv = conv2(theta_true, g, 'same');
        phi = theta_conv + alpha_true;
        
        % Compute field
        E = (r + exp(1i * phi)) ./ (1 + r * exp(1i * phi));
        I_sim = abs(E).^2;
        
        % Compute average chi^2
        chi2 = mean(((I_target(:) - I_sim(:)).^2) ./ I_target(:));
        Chi2(i, j) = chi2;
    end
end

% -------------------- Find best (r,w) -------------------- %
[min_val, min_idx] = min(Chi2(:));
[i_opt, j_opt] = ind2sub(size(Chi2), min_idx);
r_opt = r_list(i_opt);
w_opt = w_list(j_opt);

fprintf('Best r = %.3f\n', r_opt);
fprintf('Best w = %.3f\n', w_opt);
fprintf('Minimum chi^2 = %.3e\n', min_val);

% -------------------- Plot heatmap -------------------- %
figure;
imagesc(w_list, r_list, log10(Chi2));
xlabel('w (pixels)');
ylabel('r');
title('log_{10}(\chi^2) for different (r,w)');
colorbar;
