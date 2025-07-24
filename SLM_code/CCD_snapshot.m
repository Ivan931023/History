% ---------- Put phase pattern to SLM ---------- %
close all
move_image_on_screen(move_x, move_y, pixel, phase)
pause(0.1)

% ---------- CCD setup ---------- %
vid = videoinput('pointgrey', 1, CCD_mode);
src = getselectedsource(vid);
src.Shutter = Shutter;
src.Sharpness = Sharpness;
src.Brightness = Brightness;
src.Exposure = Exposure;
src.Gain = Gain;

% ---------- Snapshots ---------- %
image = 0;
for i = 1:snapshot_times
    sprintf('Snapshot : %d',i)
    start(vid);
    data = getdata(vid,1);
    data = double(data);
    stop(vid)
    image = image + data;
    pause(0.05)
end
image = image / snapshot_times;

data_zoomin = image(v-range:v+range,h-range:h+range);
if Check_Shutter == 1
    [Shutter,data_zoomin] = Check_shutter(data_zoomin,Shutter,intensity_range,position);
end
