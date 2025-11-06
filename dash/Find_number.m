function number = Find_number(Zernike_n)
    array = [];
    for i = 0:Zernike_n
        ii = linspace(-i,i,i+1);
        iii = [array ii];
        array = iii;
    end    
    number = length(iii);
end