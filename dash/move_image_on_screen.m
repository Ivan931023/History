function move_image_on_screen(move_x, move_y, pixel, exp_phi_angle)
    fff = figure;
    screens = get(0, 'MonitorPositions');
    screen2_position = screens(1, :);
    screen_width = screen2_position(3);
    screen_height = screen2_position(4);
    set(fff, 'Position', screen2_position);
    set(fff, 'MenuBar', 'none', 'ToolBar', 'none', 'NumberTitle', 'off');
    set(fff, 'Color', 'white');
    set(fff, 'WindowState', 'fullscreen');

    x_offset = (screen_width - pixel) / 2 + move_x;
    y_offset = (screen_height - pixel) / 2 + move_y;

    axes('Position', [x_offset/screen_width, y_offset/screen_height, pixel/screen_width, pixel/screen_height]);
    imshow(exp_phi_angle, [0 2*pi]);
end