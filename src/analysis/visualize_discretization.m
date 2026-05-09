%% Visualization of ObservationMapper Discretization Methods
% Prepared for Scientific Publication
close all; clear; clc;
% Initialize the mapper
om = ObservationMapper();
% Extract different sequences for comparison
% Note: We normalize or scale them for visual comparison on the same axes
methods = {
'Uniform', om.generate_sequence_uniform();
'Quadratic', om.generate_sequence_quadratic();
'Exponential', om.generate_sequence_exponential();
'Mu-Law', om.generate_sequence_mu_law();
'A-Law', om.generate_sequence_A_law();
};
% Figure setup for paper (Single column width usually ~3.5 inches)
figure('Units', 'inches', 'Position', [1, 1, 7, 5], 'Color', 'w');
hold on;
colors = lines(size(methods, 1));
num_methods = size(methods, 1);
for i = 1:num_methods
    name = methods{i,1};
    data = methods{i,2};
    % Fix quadratic to include symmetric negative bins
    if strcmp(name, 'Quadratic')
        % Assume data is sorted ascending >=0; make symmetric around zero
        if data(1) == 0
            negative = -data(end:-1:2);  % Exclude zero to avoid duplication
        else
            negative = -data(end:-1:1);
        end
        data = sort([negative, data]);
    end
% Normalize data to [-1, 1] for visual alignment in the paper
% This highlights the "distribution strategy" rather than the raw units
    norm_data = (data - min(data)) / (max(data) - min(data)) * 2 - 1;
% Plot the discretization points as vertical stems
% Offset each method on the Y-axis for clarity
    y_offset = num_methods - i + 1;
    stem(norm_data, ones(size(norm_data)) * 0.4, ...
'BaseValue', 0, 'Marker', 'o', 'LineWidth', 1.2, ...
'Color', colors(i,:), 'MarkerFaceColor', colors(i,:));
% Label the method
    text(-1.05, y_offset, name, 'FontSize', 11, 'FontWeight', 'bold', ...
'HorizontalAlignment', 'right', 'Interpreter', 'tex');
% Shift the stem plot to its Y-offset
    h = findobj(gca, 'Type', 'stem');
    h(1).YData = h(1).YData + y_offset - 0.2;
    h(1).BaseValue = y_offset - 0.2;
end
% Aesthetics
set(gca, 'YTick', [], 'XGrid', 'on', 'TickDir', 'out');
xlabel('Normalized State Space Range [-1, 1]', 'FontSize', 12);
title('Comparison of State Space Discretization Methods', 'FontSize', 14);
ylim([0.5, num_methods + 1]);
xlim([-1.2, 1.1]);
box off;
% Add a note about density
text(0, 0.6, 'High density near zero (center) provides better control resolution', ...
'FontSize', 10, 'FontAngle', 'italic', 'HorizontalAlignment', 'center');
% Save for paper (High Resolution)
% print('Discretization_Methods','-dpng','-r300');