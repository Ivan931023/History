function grat = Grating_phase(pixel, max_phase, min_phase, level, repeat, theta_blazed)
    grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, theta_blazed);
    grat = 2*pi/255 * grat;
end