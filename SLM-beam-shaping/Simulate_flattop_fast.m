function data_zoomin = Simulate_flattop_fast(Beam_size,Output_x,Output_y)
    lambda = 447e-6;
    f = 250;
    pixel_pattern = 1080;
    pixel_Zernike = 750;
    CCD_pixel = 2.2e-3;
    theta_deg = -90;
    repeat = 1;
    level = 32; 
    range = 150;

    para = [pixel_pattern pixel_Zernike f lambda range];
    beam_para = [Beam_size Output_x Output_y];
    grating_para = [theta_deg repeat level];

    N = round(para(4)*para(3) / (0.008*CCD_pixel),-1);
    pixel = N;
    pixel_pattern = para(1);
    f = para(3);
    lambda = para(4);
    no_Zernike = 1;
    Zernike_n = 4;
    range = para(5);
    unit_power = 12000;
    
    Beam_size = beam_para(1);
    Output_x = beam_para(2);
    Output_y = beam_para(3);
    
    dx = 8e-3;
    dy = 8e-3;
    x = -pixel/2*dx : dx : (pixel/2-1)*dx;
    y = -pixel/2*dy : dy : (pixel/2-1)*dy;
    [X, Y] = meshgrid(x, -y);
    
    sig_x = Beam_size / 4;
    sig_y = Beam_size / 4;
    Input_beam = exp(-(X.^2/2/sig_x^2+Y.^2/2/sig_y^2));
    Input_beam = Input_beam ./ max(Input_beam(:));
    Input_beam_origin_power = sum(Input_beam,'all');
    r = (unit_power * 10000) / Input_beam_origin_power;
    Input_beam = Input_beam * r;
    
    theta_deg = grating_para(1);
    theta_blazed = deg2rad(theta_deg);
    max_phase = 255;
    min_phase = 0;
    repeat = grating_para(2);
    level = grating_para(3);
    
    Z = zeros(1,15);
    phaseImage = ones(pixel_Zernike);
    [rows, cols] = size(phaseImage);
    [xx, yy] = meshgrid(linspace(-1,1,cols), linspace(1,-1,rows));
    [theta2 rho] = cart2pol(xx, yy);
    ZZ = Zernike_polynomial_superposition(rho, theta2, Z, Zernike_n);
    exp_z = padding(ZZ, pixel); 
    Angle_exp_z = Angle_0_2pi(exp_z);
    
    x1 = 8e-3 * (-pixel_pattern/2:pixel_pattern/2-1);
    y1 = 8e-3 * (-pixel_pattern/2:pixel_pattern/2-1);
    [X1, Y1] = meshgrid(x1,y1);
    
    a = Beam_size / (2*sqrt(2));
    ax1 = a; ax2 = Output_x / 2;
    ay1 = a; ay2 = Output_y / 2;
    
    grat = Blazed_grating_rotate(pixel_pattern, max_phase, min_phase, level, repeat, theta_blazed);
    grat = padding(grat,pixel);
    Blazed_phi = 2*pi/255 * grat;
    
    thetax = (1/lambda/f) * (sqrt(2*pi)*ax1*ax2*exp(-2*(X1/ax1).^2) + 2*pi*ax2*X1.*erf(sqrt(2)/ax1.*X1));
    thetay = (1/lambda/f) * (sqrt(2*pi)*ay1*ay2*exp(-2*(Y1/ay1).^2) + 2*pi*ay2*Y1.*erf(sqrt(2)/ay1.*Y1));
    theta = thetax + thetay;
    theta_rad = mod(theta, 2*pi);
    theta_rad = padding(theta_rad,pixel);
    Total_phase = Blazed_phi + theta_rad + Angle_exp_z;
    phase = mod(Total_phase,2*pi);
    
    ratio = 0.99999;
    no_modulate = 0.01;
    origin_power = sum(abs(IDFT(Input_beam)).^2,'all');
    power_phase = origin_power*(1-no_modulate)*ratio;
    power_amplitude = origin_power*(1-no_modulate)*(1-ratio);
    power_no_modulate = origin_power*no_modulate;
    phase_part = IDFT(Input_beam .* exp(1j*phase));
    amplitude_part = IDFT(Input_beam .* (phase/2/pi));
    no_modulate_part = IDFT(Input_beam);
    phase_part = phase_part * sqrt(power_phase / sum(abs(phase_part).^2, 'all'));
    amplitude_part = amplitude_part * sqrt(power_amplitude / sum(abs(amplitude_part).^2, 'all'));
    no_modulate_part = no_modulate_part * sqrt(power_no_modulate / sum(abs(no_modulate_part).^2, 'all'));
    result = phase_part + amplitude_part + no_modulate_part;
    
    I = abs(result).^2;
    if repeat*level == 32 && pixel == 6350
        data_zoomin = I(2978-range:2978+range,pixel/2-range:pixel/2+range);
    elseif repeat*level == 8 && pixel == 6350
        data_zoomin = I(2380-range:2380+range,pixel/2-range:pixel/2+range);
    else
        parameter = [f lambda dx];
        Mode = 'First_order';
        [v, h] = Find_beam_simulation(parameter,grating_para,Beam_size,Mode);
        data_zoomin = I(v-range:v+range,h-range:h+range);
    end
end

function result = DFT(u)
    result = fftshift(fft2(ifftshift(u)));
end
function result = IDFT(u)
    result = fftshift(ifft2(ifftshift(u)));
end
