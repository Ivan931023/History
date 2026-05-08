function Z = Zernike_polynomial_ver2(n, m, pixel)
    [x, y] = meshgrid(linspace(-1, 1, pixel), linspace(1, -1, pixel));
    [theta, rho] = cart2pol(x, y);
    
    if mod(n - abs(m), 2) ~= 0
        error('Error, n - abs(m) must be even')
    end

    if m == 0
        N = @(m,n) sqrt(2*(n+1)/2);
    else
        N = @(m,n) sqrt(2*(n+1));
    end

    R = ones(size(rho));
    for k = 0:(n - abs(m))/2
        R = R + ((-1)^k * factorial(n - k)) / ...
              (factorial(k) * factorial((n + abs(m)) / 2 - k) * factorial((n - abs(m)) / 2 - k)) * ...
              (rho.^(n - 2*k));
    end
    R = R - 1;

    if m > 0
        Z = N(m,n) * R .* cos(m * theta);
    else
        Z = N(m,n) * R .* sin(abs(m) * theta);
    end

    if m == 0
        Z = N(m,n) * R;
    end

    if m == 0 && n == 0
        Z = R .* sin(-m * theta);
    end
end
