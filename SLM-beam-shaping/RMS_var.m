function rms_var = RMS_var(Data, Target)
    [mm nn] = size(Data);
    Data_average = sum(Data,'all') / (mm*nn);
    rms_var = sqrt(1/(mm*nn)* sum((Data - Target).^2 ,'all')) / Data_average * 100;
    [x1 y1] = size(Data);
    [x2 y2] = size(Target);
    if x1 ~= x2 && y1 ~= y2
        sprintf('Data size [%g %g]',x1,y1)
        sprintf('Target size [%g %g]',x2,y2)
        error('The size between target and data is different. Please check the matrix element')
    end
end
