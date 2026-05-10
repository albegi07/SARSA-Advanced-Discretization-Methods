clear; close all;
projectRoot = getProjectRoot();

folder = fullfile(projectRoot, 'results_sin_0_2_rad_s');

% Define model prefixes (longest to shortest to avoid substring conflicts)
models = {'exponential', 'uniform', 'quadratic', 'mu_law', 'A_law'};
wind_types = {'uniform', 'weibull'};

files = dir(fullfile(folder, '*.mat'));

P_ref = 1.5;        % Reference power [MW]
nBoot = 1000;       % Bootstrap samples
alpha = 0.05;       % 95% CI

% Containers
rmse_mean = nan(numel(models), numel(wind_types));
ci_lower  = nan(numel(models), numel(wind_types));
ci_upper  = nan(numel(models), numel(wind_types));

fprintf('Processing files...\n');

for mi = 1:numel(models)
    for wi = 1:numel(wind_types)

        % Collect all power samples for this model/wind combo
        all_p = [];

        for i = 1:numel(files)
            fname = files(i).name;

            % --- Model match ---
            if ~contains(lower(fname), lower(models{mi}))
                continue;
            end

            % --- Wind match ---
            if wi == 2 && ~contains(lower(fname), 'weibull')
                continue;
            elseif wi == 1 && contains(lower(fname), 'weibull')
                continue;
            end

            % Load file
            try
                data = load(fullfile(folder, fname));
                if ~isfield(data, 'simOut'), continue; end

                Res = data.simOut;
                p_raw = Res.get('power_output').Data;
                p = squeeze(p_raw);

                % Remove transient
                if numel(p) > 300
                    p = p(300:end);
                end

                % Convert to MW
                p = p / 1e6;

                % Accumulate samples
                all_p = [all_p; p(:)];

            catch ME
                fprintf('Error in %s: %s\n', fname, ME.message);
            end
        end

        if isempty(all_p)
            continue;
        end

        % ---- Mean RMSE ----
        rmse_func = @(x) sqrt(mean((x - P_ref).^2));
        rmse_mean(mi, wi) = rmse_func(all_p);

        % ---- Bootstrap over TIME samples ----
        bootstat = bootstrp(nBoot, rmse_func, all_p);
        ci = quantile(bootstat, [alpha/2, 1 - alpha/2]);

        ci_lower(mi, wi) = ci(1);
        ci_upper(mi, wi) = ci(2);

        fprintf('%s | %s | N = %d samples\n', ...
            models{mi}, wind_types{wi}, numel(all_p));
    end
end

%% Plotting
figure('Color','w','Position',[100 100 1000 600]);
hold on;

x = 1:numel(models);
b = bar(x, rmse_mean, 'grouped');
cols = lines(2);

for k = 1:2
    xOffset = b(k).XEndPoints;
    errorbar(xOffset, rmse_mean(:,k), ...
        rmse_mean(:,k) - ci_lower(:,k), ...
        ci_upper(:,k) - rmse_mean(:,k), ...
        'k.', 'LineWidth', 1.3);
end

set(gca, 'XTick', x, 'XTickLabel', models);
set(gca, 'TickLabelInterpreter', 'none');
ylabel('RMSE [MW]');
legend(wind_types, 'Location', 'northwest');
grid on;
title('Model Comparison: RMSE with 95% Bootstrap CI (Time-domain)');
