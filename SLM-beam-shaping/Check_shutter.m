function [Shutter,data_zoomin1] = Check_shutter(data_zoomin0,Shutter,intensity_range,position)
    v = position(1);
    h = position(2);
    range = position(3);
    Max = 0.999;
    Min = 0.95;
    i1 = 1;
    i2 = 1;
    dS = 0.02;
    data_zoomin1 = data_zoomin0;
    while max(data_zoomin0(:)) <= max(intensity_range)*Min || max(data_zoomin0(:)) >= max(intensity_range)*Max
        i = 1;
        if max(data_zoomin0(:)) >= max(intensity_range)*Max
            Shutter_before1 = Shutter;
            Shutter = Shutter - dS;
            data_zoomin0 = SnapShot(Shutter);
            data_zoomin0 = data_zoomin0(v-range:v+range,h-range:h+range);
            data_zoomin01 = data_zoomin0;
            data_zoomin1 = data_zoomin01;
            sprintf('Overexpose! change shutter from %g to %g',Shutter_before1,Shutter)
            i = 0;
            i1 = i1 + 1;
        end
        if (max(data_zoomin0(:)) <= max(intensity_range)*Min) && i == 1
            Shutter_before2 = Shutter;
            Shutter = Shutter + dS;
            data_zoomin0 = SnapShot(Shutter);
            data_zoomin0 = data_zoomin0(v-range:v+range,h-range:h+range);
            data_zoomin02 = data_zoomin0;
            data_zoomin1 = data_zoomin02;
            sprintf('Underexpose! change shutter from %g to %g',Shutter_before2,Shutter)
            i2 = i2 + 1;
        end
        if (i1>=4 && i2>=4)
            data_zoomin1 = (data_zoomin01 + data_zoomin02)/2;
            break
        end
        if Shutter == 0.04
            break
        end
    end

    while max(data_zoomin1(:)) == max(intensity_range)
        Shutter = Shutter - dS;
        data_zoomin0 = SnapShot(Shutter);
        data_zoomin0 = data_zoomin0(v-range:v+range,h-range:h+range);
    end
    data_zoomin1 = data_zoomin0;
    
end

function image = SnapShot(Shutter)
    vid = videoinput('pointgrey', 1, 'F7_Mono16_2592x1944_Mode0');
    src = getselectedsource(vid);
    src.Shutter = Shutter;
    src.Brightness = 0;
    image = 0;
    snapshot_times = 1;
    for i = 1:snapshot_times
        start(vid);
        data = getdata(vid,1);
        data = double(data);
        stop(vid)
        image = image + data;
    end
    image = image / snapshot_times;
end
