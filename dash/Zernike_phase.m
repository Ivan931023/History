function Angle_z = Zernike_phase(pixel,pixel_Zernike,Z,Zernike_n)
    circle = pupil(pixel_Zernike);
    ZZ = Zernike_polynomial_superposition_ver2(pixel_Zernike, Z, Zernike_n, circle);
    Angle_z = padding(ZZ, pixel); 
end