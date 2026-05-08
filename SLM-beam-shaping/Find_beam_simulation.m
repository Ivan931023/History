function [v, h] = Find_beam_simulation(parameter,grating_para,Beam_size,Mode)
    f = parameter(1);
    lambda = parameter(2);
    dx = parameter(3);
    dy = parameter(3);
    N = round(lambda*f / (dx*2.2e-3),-1);
    Nx = N;
    Ny = N;
    x = -Nx/2*dx : dx : (Nx/2-1)*dx;
    y = -Ny/2*dy : dy : (Ny/2-1)*dy;
    [X, Y] = meshgrid(x, -y);
    
    pixel = N;
    pixel_pattern = 1080;
    
    x0 = 0;
    y0 = 0;
    sig_x = Beam_size / 4;
    sig_y = Beam_size / 4;
    
    Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2));
    
    if strcmp(Mode,'First_order')
        theta_blazed = deg2rad(grating_para(1));
        max_phase = 255;
        min_phase = 0;
        repeat = grating_para(2);
        level = grating_para(3); 
    end

    if strcmp(Mode,'Zero_order')
        theta_blazed = deg2rad(grating_para(1));
        max_phase = 255;
        min_phase = 255;
        repeat = grating_para(2);
        level = grating_para(3); 
    end

    grat = Blazed_grating_rotate(pixel_pattern, max_phase, min_phase, level, repeat, theta_blazed);
    grat = padding(grat,pixel);
    Blazed_phi = 2*pi/255 * grat;
    
    Total_phase = Blazed_phi;
    phase = mod(Total_phase,2*pi);
    
    result = IDFT(Input_beam .* exp(1j*phase));
    I = abs(result).^2;
    
    [centers, radii] = imfindcircles(I,[7 200]);
    [~, index] = max(radii);
    centers = centers(index,:);
    h = centers(1);
    v = centers(2);
end
