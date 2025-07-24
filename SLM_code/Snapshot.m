function image = Snapshot(Shutter)
    intensity_range = [0 65280];
    vid = videoinput('pointgrey', 1, 'F7_Mono16_2592x1944_Mode0');
    
    src = getselectedsource(vid);
    src.Shutter = Shutter;
    
    image = 0;
    snapshot_times = 5;
    for i = 1:snapshot_times
        sprintf('Snapshot : %d',i)
        start(vid);
        data = getdata(vid,1);
        data = double(data);
        stop(vid)
        image = image + data;
    end
    image = image / snapshot_times;
    figure
    imagesc(image)
    axis image
    colormap turbo
    colorbar
end