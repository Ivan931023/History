function Index = Mask(data_zoomin_analytic,threshold)
    data_zoomin_analytic = data_zoomin_analytic / max(data_zoomin_analytic(:));
    l = round(length(data_zoomin_analytic)/2);
    horizon = data_zoomin_analytic(l,:);
    vertical = data_zoomin_analytic(:,l);

    left_index = find(horizon(1:length(horizon)) >= threshold,1,'first');
    right_index = find(horizon(1:length(horizon)) >= threshold,1,'last');
    up_index = find(vertical(1:length(horizon)) >= threshold,1,'first');
    down_index = find(vertical(1:length(horizon)) >= threshold,1,'last');
    Index = [up_index down_index left_index right_index];
end