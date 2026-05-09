function show_hologram_on_slm(phase)
% Display a phase hologram on the SLM monitor (non-primary screen)

    % Get all screen info
    monitors = get(0, 'MonitorPositions');
    num_monitors = size(monitors, 1);

    if num_monitors == 1
        warning('Only one screen detected. Displaying on primary screen.');
        slm_pos = monitors(1, :);
    else
        % Assume SLM is the largest non-primary monitor
        main_monitor = monitors(1, :);
        slm_pos = [];
        max_area = 0;

        for i = 2:num_monitors
            pos = monitors(i, :);
            area = pos(3) * pos(4);
            if area > max_area
                slm_pos = pos;
                max_area = area;
            end
        end

        if isempty(slm_pos)
            slm_pos = monitors(2, :);
        end
    end

    fig = figure('MenuBar', 'none', 'ToolBar', 'none', ...
                 'Units', 'pixels', ...
                 'Position', slm_pos, ...
                 'Color', 'k', ...
                 'NumberTitle', 'off', ...
                 'Name', 'SLM Hologram');

    axes('Position', [0 0 1 1]);
    imshow(phase, [0 2*pi]);
    colormap(gray);
    axis off;
    drawnow;
end
