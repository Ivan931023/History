function [v, h] = Find_beam(theta_deg,repeat1,level1,Mode,CCD_mode)
    pixel = 1080;
    Shutter = 0.2;
    snapshot_times = 5;
    F = sprintf('First_order');
    Z = sprintf('Zero_order');
    M = sprintf('First_order_minus');
    
    if strcmp(Mode,F)
        theta_blazed = deg2rad(theta_deg);
        max_phase = 255;
        min_phase = 0;
        repeat = repeat1;
        level = level1; 
    end

    if strcmp(Mode,Z)
        theta_blazed = deg2rad(theta_deg);
        max_phase = 255;
        min_phase = 255;
        repeat = repeat1;
        level = level1; 
    end

    if strcmp(Mode,M)
        theta_blazed = deg2rad(theta_deg);
        max_phase = 255;
        min_phase = 0;
        repeat = repeat1;
        level = level1; 
    end

    if repeat*level ~= repeat1*level1
        error(['Please check the function "Find_beam.m" parameter : repeat or level'])
    end
    
    grat = Blazed_grating_rotate(pixel, max_phase, min_phase, level, repeat, theta_blazed);
    Blazed_phi = 2*pi/255 * grat;
    phase = Blazed_phi;
    
    close all
    move_image_on_screen(0, 0, pixel, phase)
    pause(0.1)
    
    vid = videoinput('pointgrey', 1, CCD_mode);
    src = getselectedsource(vid);
    src.Shutter = Shutter;
    
    image = 0;
    for i = 1:snapshot_times
        start(vid);
        data = getdata(vid,1);
        data = double(data);
        stop(vid)
        image = image + data;
    end
    image = image / snapshot_times;
    
    [centers, radii] = imfindcircles(image,[6 200]);
    [value, index] = max(radii);
    centers = centers(index,:)
    if length(centers) ~= 2
        error('Find more than one beam')
    end

    h = centers(1);
    v = centers(2);
end
