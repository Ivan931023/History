function theta_rad = Circle_analytic_phase(pixel,lambda,f,ax1,ay1)
    % ---------- Analytic solution ---------- %
    %%% Paper : Analytical beam shaping with application to laser-diode arrays %%%
    %%% The analytic below is a special case where n1 = 2, n2 = Inf            %%%
    x = 8e-3 * (-pixel/2:pixel/2-1);
    y = 8e-3 * (-pixel/2:pixel/2-1);
    [X, Y] = meshgrid(x,y);
    
    % ---------------- Circular flat top beam ------------------- %
    rho = sqrt(X.^2 + Y.^2);
    theta = (1/lambda/f) * (sqrt(2*pi)*ax1*ay1*exp(-2*(rho/ax1).^2) + 2*pi*ay1*rho.*erf(sqrt(2)/ax1.*rho));
    
    theta_rad = mod(theta, 2*pi);
end