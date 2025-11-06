function result = imagesc_turbo(data)
    figure
    % data = data / max(data(:));
    imagesc(data)
    colormap turbo
    colorbar
    axis image
end