function [data_zoomin, I] = Simulate_phase_pattern(phase,para,Beam_size,grating_para,CCD_pixel)
    % para = [pixel_pattern pixel_Zernike f lambda range]
    % grating_para = [theta_deg repeat level];

    N = round(para(4)*para(3) / (0.008*CCD_pixel),-1);
    pixel = N;
    pixel_pattern = para(1);
    pixel_Zernike = para(2);
    f = para(3);
    lambda = para(4);
    range = para(5);
    unit_power = 12000;
    
    Nx = pixel;
    Ny = pixel;
    dx = 8e-3;
    dy = 8e-3;
    x = -Nx/2*dx : dx : (Nx/2-1)*dx;
    y = -Ny/2*dy : dy : (Ny/2-1)*dy;
    [X, Y] = meshgrid(x, -y);
    
    x0 = 0;
    y0 = 0;
    sig_x = Beam_size / 4;
    sig_y = Beam_size / 4;
    
    Input_beam = exp(-((X-x0).^2/2/(sig_x)^2+(Y-y0).^2/2/(sig_y)^2));
    Input_beam = Input_beam ./ max(Input_beam(:));
    Input_beam_origin_power = sum(Input_beam,'all');
    ratio = (unit_power * 10000) / Input_beam_origin_power;
    Input_beam = Input_beam * ratio;
    
    theta_deg = grating_para(1);
    theta_blazed = deg2rad(theta_deg);
    max_phase = 255;
    min_phase = 0;
    repeat = grating_para(2);
    level = grating_para(3);
    
    grat = Blazed_grating_rotate(pixel_pattern, max_phase, min_phase, level, repeat, theta_blazed);
    grat = padding(grat,pixel);
    phase = padding(phase,pixel);
    Blazed_phi = 2*pi/255 * grat;
    Total_phase = Blazed_phi + phase;
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
    elseif repeat*level == 64 && pixel == 7620
        data_zoomin = I(3692-range:3692+range,pixel/2-range:pixel/2+range);
    else
        parameter = [f lambda dx];
        Mode = 'First_order';
        [v, h] = Find_beam_simulation(parameter,grating_para,Beam_size,Mode);
        v = round(v);
        h = round(h);
        data_zoomin = I(v-range:v+range,h-range:h+range);
    end
end

function result = DFT(u)
    result = fftshift(fft2(ifftshift(u)));
end
function result = IDFT(u)
    result = fftshift(ifft2(ifftshift(u)));
end
