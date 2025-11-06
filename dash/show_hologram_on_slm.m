function show_hologram_on_slm(phase)
% 顯示 phase hologram 到 SLM 顯示器（非主螢幕）

    % 取得所有螢幕資訊
    monitors = get(0, 'MonitorPositions');
    num_monitors = size(monitors, 1);

    if num_monitors == 1
        warning('僅偵測到一個螢幕，無法自動送到 SLM，將顯示於主螢幕。');
        slm_pos = monitors(1, :);
    else
        % 假設 SLM 為「面積最大、非主螢幕」的顯示器
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

        % 如果找不到，就用第二螢幕
        if isempty(slm_pos)
            slm_pos = monitors(2, :);
        end
    end

    % 顯示 figure 並送到指定螢幕（SLM）
    fig = figure('MenuBar', 'none', 'ToolBar', 'none', ...
                 'Units', 'pixels', ...
                 'Position', slm_pos, ...
                 'Color', 'k', ...
                 'NumberTitle', 'off', ...
                 'Name', 'SLM Hologram');

    axes('Position', [0 0 1 1]);           % 滿版
    imshow(phase, [0 2*pi]);               % 顯示相位圖
    colormap(gray);                        % 灰階相位
    axis off;
    drawnow;
end
