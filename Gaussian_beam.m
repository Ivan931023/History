function Input_beam = Gaussian_beam(Beam_size,pixel,dx)
    % --------- SLM plane ---------
    Nx = pixel;
    Ny = pixel;
    
    % dx = 8e-3; % (mm)
    dy = dx; % (mm)
    x = -Nx/2*dx : dx : (Nx/2-1)*dx;
    y = -Ny/2*dy : dy : (Ny/2-1)*dy;
    [X, Y] = meshgrid(x, -y);
    
    % --------- Set the Parameter of input beam ---------
    x0 = 0;
    y0 = 0;
    sig_x = Beam_size / 4;
    sig_y = Beam_size / 4;
    
    Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2)) ; % Gaussian beam
    Input_beam = Input_beam ./ max(Input_beam(:));