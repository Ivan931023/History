function circle = pupil(pixel)
    [x, y] = meshgrid(linspace(-1, 1, pixel), linspace(1, -1, pixel));
    [theta, rho] = cart2pol(x, y);
    
    circle = [];
    for i = 1:pixel
        for j = 1:pixel
            if round(rho(i,j),3) > 1
                circle(i,j) = 0;
            else
                circle(i,j) = 1;
            end
        end
    end
end
