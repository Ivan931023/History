function theta_rad = Rectangle_analytic_phase(pixel,lambda,f,ax1,ax2,ay1,ay2)
    x = 8e-3 * (-pixel/2:pixel/2-1);
    y = 8e-3 * (-pixel/2:pixel/2-1);
    [X, Y] = meshgrid(x,y);
    
    thetax = (1/lambda/f) * (sqrt(2*pi)*ax1*ax2*exp(-2*(X/ax1).^2) + 2*pi*ax2*X.*erf(sqrt(2)/ax1.*X));
    thetay = (1/lambda/f) * (sqrt(2*pi)*ay1*ay2*exp(-2*(Y/ay1).^2) + 2*pi*ay2*Y.*erf(sqrt(2)/ay1.*Y));
    theta = sqrt(thetax.^2 + thetay.^2);
    
    theta_rad = mod(theta, 2*pi);
end
