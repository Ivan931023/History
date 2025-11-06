function theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2)
    % ---------- Analytic solution ---------- %
    %%% Paper : Analytical beam shaping with application to laser-diode arrays %%%
    %%% The analytic below is a special case where n1 = 2, n2 = Inf            %%%
    x = 8e-3 * (-pixel/2:pixel/2-1);
    y = 8e-3 * (-pixel/2:pixel/2-1);
    [X, Y] = meshgrid(x,y);
    
    % ---------------- Rectangle flat top beam ------------------ %
    thetax = (1/lambda/f) * (sqrt(2*pi)*ax1*ax2*exp(-2*(X/ax1).^2) + 2*pi*ax2*X.*erf(sqrt(2)/ax1.*X));
    thetay = (1/lambda/f) * (sqrt(2*pi)*ay1*ay2*exp(-2*(Y/ay1).^2) + 2*pi*ay2*Y.*erf(sqrt(2)/ay1.*Y));
    theta = sqrt(thetax.^2 + thetay.^2);
    
    % ---------------- Circular flat top beam ------------------- %
    % rho = sqrt(X.^2 + Y.^2);
    % theta = (1/lambda/f) * (sqrt(2*pi)*ay1*ay2*exp(-2*(rho/ay1).^2) + 2*pi*ay2*rho.*erf(sqrt(2)/ay1.*rho));
    
    theta_rad = mod(theta, 2*pi);
end