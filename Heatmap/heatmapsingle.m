clc;
clear;
close all;

% Folder containing the .xlsx files
folderPath = 'C:\Users\hseyyedzadeh\Documents\Heatmap\'; % Update with your folder path

% Thresholds for color scaling 
minThreshold = 0;   
maxThreshold = 2000;  

% Get list of .xlsx files in folder
fileList = dir(fullfile(folderPath, '*.xlsx'));

% Loop through each file to generate a separate heatmap
for i = 1:length(fileList)
    % Read Excel file
    data = readtable(fullfile(folderPath, fileList(i).name));

    % Extract X0 and Y0 columns
    if ismember('X0', data.Properties.VariableNames) && ismember('Y0', data.Properties.VariableNames)
        X = data.X0(:);
        Y = data.Y0(:);
    else
        warning('File %s does not contain required columns (X0, Y0)', fileList(i).name);
        continue;
    end

    % Remove values above 130 before scaling
    validIdx = X <= 125;
    X = X(validIdx);
    Y = Y(validIdx);

    % Scale X and Y values 
    maxWidth = 30;
    maxLength = 120;
    scaleFactorX = maxLength / max(X);
    scaleFactorY = maxWidth / max(Y);
    X = X * scaleFactorX;
    Y = Y * scaleFactorY;

    % Define bin edges
    edgesX = linspace(0, maxLength, 401); 
    edgesY = linspace(0, maxWidth, 101); 

    % Calculate density for the current file
    [counts, ~, ~] = histcounts2(X, Y, edgesX, edgesY);

    % Apply logarithmic scaling to density
    logCounts = log10(counts + 1); % Add 1 to avoid log10(0)

    % Normalize the log-scaled density values
    logMinThreshold = log10(minThreshold + 1); 
    logMaxThreshold = log10(maxThreshold + 1); 
    normalizedDensity = (logCounts - logMinThreshold) / (logMaxThreshold - logMinThreshold);
    normalizedDensity(normalizedDensity < 0) = 0; 
    normalizedDensity(normalizedDensity > 1) = 1; 

    % Generate bin centers for plotting
    binWidthX = edgesX(2) - edgesX(1);
    binWidthY = edgesY(2) - edgesY(1);
    binCentersX = edgesX(1:end-1) + binWidthX / 2;
    binCentersY = edgesY(1:end-1) + binWidthY / 2;

    % Plot heatmap for the current file
    figure('Units', 'pixels', 'Position', [100, 100, 1200, 300]);
    imagesc(binCentersX, binCentersY, normalizedDensity');
    set(gca, 'YDir', 'normal'); 
    caxis([0 1]); % Ensure colormap uses full range
    colormap parula;
    colorbar('Ticks', [0 1], 'TickLabels', arrayfun(@(x) sprintf('%.1f', x), linspace(minThreshold, maxThreshold, 5), 'UniformOutput', false));
    title(sprintf('Density Scatter Plot for %s (Logarithmic Scaling)', fileList(i).name));
    xlabel('X');
    ylabel('Y');

    % Save the heatmap as an image
    [~, fileName, ~] = fileparts(fileList(i).name);
    saveas(gcf, fullfile(folderPath, sprintf('%s_density_scatter_log_scaled.png', fileName)));
end