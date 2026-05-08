function none = Generate_GIF(f1,gif_filename,time,count)
    frame = getframe(f1);
    im = frame2im(frame);
    [imind, cm] = rgb2ind(im, 256);
    
    if count == 1
        imwrite(imind, cm, gif_filename, 'gif', 'Loopcount', Inf, 'DelayTime', time);
    else
        imwrite(imind, cm, gif_filename, 'gif', 'WriteMode', 'append', 'DelayTime', time);
    end
end
