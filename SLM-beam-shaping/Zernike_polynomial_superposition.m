function Zernike = Zernike_polynomial_superposition(rho, theta, Z, n)
    array = [];
    for nn = 0:n
        mm = linspace(-nn,nn,nn+1);
        m = [array mm];
        array = m;
    end
    
    array = [];
    for i = 1:(n+1)
        nn = ones(1,i)*(i-1);
        n = [array nn];
        array = n;
    end

    mm = m;
    nn = n;

    if length(Z) ~= length(nn)
        sprintf('Error, The size of Z must be 1*%d.',length(nn))
        return
    end

    Zernike = 0;
    count = 0;
    for i = 1:length(mm)
        p = zernike_polynomial(nn(i), mm(i), rho, theta);
        Zernike = Zernike + p*Z(i);
        if Z(i) == 0
            count = count + 1;
        end
    end
    Zernike = (Zernike + 1) * pi;
    Zernike = exp(1j*Zernike);

    [xx yy] = size(rho);
    pixel = xx;
    for i = 1:xx
        for j = 1:yy
            if sqrt((pixel/2-i)^2+(pixel/2-j)^2) > pixel/2
                Zernike(i,j) = 0; 
            end
        end
    end
    if count == length(nn)
        Zernike = ones(pixel);
    end
end
