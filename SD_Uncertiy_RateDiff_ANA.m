clear all;
clc;

folder = 'D:\project total\Nature_project\Seral_dependence_UG\DG_Group_UG';
pattern = '*UGi_*_1.mat';
fileList = dir(fullfile(folder, pattern));
filenames = {fileList.name};
Sub_num = length(filenames);

fprintf('找到 %d 个文件\n\n', Sub_num);

% 定义所有要分析的比例
all_rates = [0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5];
n_rates = length(all_rates);

% ========== 第一步：识别每个被试的不确定比例点 ==========
fprintf('========== 识别不确定比例点 ==========\n');

all_uncertain_rates = [];
subject_uncertain_rates = struct();

for ni = 1:Sub_num
    tokens = strsplit(filenames{ni}, '_');
    if length(tokens) >= 2
        sub_name = tokens{2};
    else
        sub_name = filenames{ni};
    end
    
    % 加载数据
    data_result = load(fullfile(folder, filenames{ni}));
    result_data = data_result.result;
    
    % 提取有效数据
    n = 0;
    data_temp = [];
    
    for i = 1:125
        n = n + 1;
        data_temp(1,n) = result_data(7,i);  % rates
        data_temp(3,n) = result_data(4,i);  % accept or not
    end
    
    rates = data_temp(1, :);
    accept = data_temp(3, :);
    
    % 找出不确定比例点
    uncertain_for_subject = [];
    
    for rate_val = all_rates
        idx = (abs(rates - rate_val) < 0.001);
        if sum(idx) > 0
            accept_rate = mean(accept(idx));
            if accept_rate > 0 && accept_rate < 1
                uncertain_for_subject = [uncertain_for_subject, rate_val];
                all_uncertain_rates = [all_uncertain_rates, rate_val];
            end
        end
    end
    
    subject_uncertain_rates.(sub_name) = uncertain_for_subject;
    fprintf('被试 %s: 不确定比例点 = %s\n', sub_name, mat2str(uncertain_for_subject));
end

% 统计不确定比例点
unique_uncertain = unique(all_uncertain_rates);
fprintf('\n所有不确定比例点: %s\n', mat2str(unique_uncertain));
for rate = unique_uncertain
    count = sum(all_uncertain_rates == rate);
    fprintf('  %.2f: %d个被试\n', rate, count);
end

% ========== 第二步：针对不确定比例点，按比例差异统计 ==========
fprintf('\n========== 分析不确定比例点的比例差异效应 ==========\n');

% 初始化计数器：[不确定比例点][比例差异] -> {总次数, 接受次数}
uncertain_counts = struct();

for rate = unique_uncertain
    rate_str = sprintf('rate_%.0f', rate * 100);
    uncertain_counts.(rate_str) = struct();
    uncertain_counts.(rate_str).baseline = struct('total', 0, 'accept', 0);
end

% 遍历所有被试，统计不确定比例点的数据
for ni = 1:Sub_num
    tokens = strsplit(filenames{ni}, '_');
    if length(tokens) >= 2
        sub_name = tokens{2};
    else
        sub_name = filenames{ni};
    end
    
    % 加载数据
    data_result = load(fullfile(folder, filenames{ni}));
    result_data = data_result.result;
    
    % 提取有效数据
    n = 0;
    data_temp = [];
    
    for i = 1:125
        n = n + 1;
        data_temp(1,n) = result_data(7,i);  % rates
        data_temp(3,n) = result_data(4,i);  % accept or not
    end
    
    rates = data_temp(1, :);
    accept = data_temp(3, :);
    
    % 获取该被试的不确定比例点
    if ~isfield(subject_uncertain_rates, sub_name)
        continue;
    end
    uncertain_for_subject = subject_uncertain_rates.(sub_name);
    
    % 遍历试次
    for i = 3:125
        current_rate = rates(i);
        prev_rate = rates(i-2);
        current_accept = accept(i);
        
        % 当前试次必须是不确定比例点
        if ~any(abs(current_rate - uncertain_for_subject) < 0.001)
            continue;
        end
        
        % 匹配到标准比例
        current_rate_matched = NaN;
        for r = 1:n_rates
            if abs(current_rate - all_rates(r)) < 0.001
                current_rate_matched = all_rates(r);
                break;
            end
        end
        
        if isnan(current_rate_matched)
            continue;
        end
        
        rate_str = sprintf('rate_%.0f', current_rate_matched * 100);
        
        % 更新基线计数（所有该不确定比例点的试次）
        uncertain_counts.(rate_str).baseline.total = ...
            uncertain_counts.(rate_str).baseline.total + 1;
        uncertain_counts.(rate_str).baseline.accept = ...
            uncertain_counts.(rate_str).baseline.accept + current_accept;
        
        % 检查前一试次是否在0.1-0.5范围内
        if prev_rate < 0.1 || prev_rate > 0.5
            continue;
        end
        
        % 匹配前一试次比例
        prev_rate_matched = NaN;
        for r = 1:n_rates
            if abs(prev_rate - all_rates(r)) < 0.001
                prev_rate_matched = all_rates(r);
                break;
            end
        end
        
        if isnan(prev_rate_matched)
            continue;
        end
        
        % 计算比例差异
        rate_diff = prev_rate_matched - current_rate_matched;
        rate_diff = round(rate_diff / 0.05) * 0.05;
        
        % 创建差异键名
        if rate_diff >= 0
            diff_str = sprintf('diff_%.0f', rate_diff * 100);
        else
            diff_str = sprintf('diff_neg_%.0f', abs(rate_diff) * 100);
        end
        
        % 初始化（如果不存在）
        if ~isfield(uncertain_counts.(rate_str), diff_str)
            uncertain_counts.(rate_str).(diff_str) = struct('total', 0, 'accept', 0);
        end
        
        % 更新计数
        uncertain_counts.(rate_str).(diff_str).total = ...
            uncertain_counts.(rate_str).(diff_str).total + 1;
        uncertain_counts.(rate_str).(diff_str).accept = ...
            uncertain_counts.(rate_str).(diff_str).accept + current_accept;
    end
end

% ========== 第三步：计算接受率和偏差 ==========
fprintf('\n========== 计算结果 ==========\n\n');

results_table = table();

rate_fields = fieldnames(uncertain_counts);

for r = 1:length(rate_fields)
    rate_str = rate_fields{r};
    current_rate = str2double(rate_str(6:end)) / 100;
    
    % 计算基线接受率
    baseline_total = uncertain_counts.(rate_str).baseline.total;
    baseline_accept = uncertain_counts.(rate_str).baseline.accept;
    
    if baseline_total > 0
        baseline_accept_rate = baseline_accept / baseline_total;
    else
        continue;
    end
    
    fprintf('========================================\n');
    fprintf('不确定比例点 = %.2f\n', current_rate);
    fprintf('基线: 总次数=%d, 接受次数=%d, 接受率=%.4f\n', ...
        baseline_total, baseline_accept, baseline_accept_rate);
    fprintf('========================================\n');
    
    % 获取所有比例差异
    diff_fields = fieldnames(uncertain_counts.(rate_str));
    diff_fields = diff_fields(~strcmp(diff_fields, 'baseline'));
    
    for d = 1:length(diff_fields)
        diff_str = diff_fields{d};
        
        % 解析比例差异值
        if ~isempty(strfind(diff_str, 'neg'))  % 使用 strfind 代替 contains
            rate_diff = -str2double(regexp(diff_str, '\d+', 'match', 'once')) / 100;
        else
            rate_diff = str2double(regexp(diff_str, '\d+', 'match', 'once')) / 100;
        end
        
        % 获取条件统计
        cond_total = uncertain_counts.(rate_str).(diff_str).total;
        cond_accept = uncertain_counts.(rate_str).(diff_str).accept;
        
        if cond_total > 0
            cond_accept_rate = cond_accept / cond_total;
            deviation_from_own_baseline = cond_accept_rate - baseline_accept_rate;
            
            % 添加到结果表（暂时使用当前比例的基线，后面会更新为平均基线）
            new_row = {current_rate, rate_diff, ...
                baseline_total, baseline_accept, baseline_accept_rate, ...
                cond_total, cond_accept, cond_accept_rate, ...
                deviation_from_own_baseline, NaN};  % 最后一列是与平均基线的偏差，稍后计算
            results_table = [results_table; new_row];
            
            fprintf('  差异=%.2f: 总次数=%d, 接受次数=%d, 条件接受率=%.4f, 偏差=%.4f\n', ...
                rate_diff, cond_total, cond_accept, cond_accept_rate, deviation_from_own_baseline);
        end
    end
    fprintf('\n');
end

% 设置列名
if ~isempty(results_table)
    results_table.Properties.VariableNames = {'Uncertain_Rate', 'Rate_Diff', ...
        'Baseline_Total', 'Baseline_Accept', 'Baseline_Accept_Rate', ...
        'Cond_Total', 'Cond_Accept', 'Cond_Accept_Rate', ...
        'Deviation_From_Own_Baseline', 'Deviation_From_Average_Baseline'};
    
    % ===== 计算每行的平均基线偏差 =====
    fprintf('\n========== 计算与平均基线的偏差 ==========\n');
    
    all_diffs = unique(results_table.Rate_Diff);
    
    for d = 1:length(all_diffs)
        diff_val = all_diffs(d);
        
        % 找出该差异的所有行
        diff_rows_idx = (results_table.Rate_Diff == diff_val);
        diff_data = results_table(diff_rows_idx, :);
        
        % 计算该差异下所有涉及的当前比例的平均基线接受率
        unique_rates_in_diff = unique(diff_data.Uncertain_Rate);
        total_baseline_trials_for_diff = 0;
        total_baseline_accepts_for_diff = 0;
        
        for ur = 1:length(unique_rates_in_diff)
            rate_val = unique_rates_in_diff(ur);
            rate_rows = diff_data(diff_data.Uncertain_Rate == rate_val, :);
            % 每个当前比例的基线只计算一次
            total_baseline_trials_for_diff = total_baseline_trials_for_diff + rate_rows.Baseline_Total(1);
            total_baseline_accepts_for_diff = total_baseline_accepts_for_diff + rate_rows.Baseline_Accept(1);
        end
        
        if total_baseline_trials_for_diff > 0
            average_baseline_accept_rate = total_baseline_accepts_for_diff / total_baseline_trials_for_diff;
        else
            average_baseline_accept_rate = NaN;
        end
        
        % 更新该差异所有行的平均基线偏差
        results_table.Deviation_From_Average_Baseline(diff_rows_idx) = ...
            results_table.Cond_Accept_Rate(diff_rows_idx) - average_baseline_accept_rate;
        
        fprintf('差异=%.2f: 平均基线接受率=%.4f (基于%d个不确定点)\n', ...
            diff_val, average_baseline_accept_rate, length(unique_rates_in_diff));
    end
    
    % 排序
    results_table = sortrows(results_table, {'Uncertain_Rate', 'Rate_Diff'});
    
    % 显示完整结果表
    fprintf('\n========== 完整结果表 ==========\n');
    disp(results_table);
    
    % 保存结果
    writetable(results_table, 'Two_uncertain_rates_rate_diff_analysis.csv');
    fprintf('\n结果已保存: uncertain_rates_rate_diff_analysis.csv\n');
    assignin('base', 'uncertain_rate_diff_results', results_table);
    
    % ========== 第四步：按比例差异汇总（跨所有不确定比例点）==========
    fprintf('\n========== 按比例差异汇总（跨所有不确定比例点）==========\n\n');
    
    all_diffs = unique(results_table.Rate_Diff);
    all_diffs = sort(all_diffs);
    
    summary_table = table();
    
    for d = 1:length(all_diffs)
        diff_val = all_diffs(d);
        
        % 筛选该差异的所有数据
        diff_data = results_table(results_table.Rate_Diff == diff_val, :);
        
        % 计算汇总统计
        total_cond_trials = sum(diff_data.Cond_Total);
        total_cond_accepts = sum(diff_data.Cond_Accept);
        
        % 计算该差异下所有涉及的当前比例的平均基线接受率（方法2）
        unique_rates_in_diff = unique(diff_data.Uncertain_Rate);
        total_baseline_trials_for_diff = 0;
        total_baseline_accepts_for_diff = 0;
        
        for ur = 1:length(unique_rates_in_diff)
            rate_val = unique_rates_in_diff(ur);
            rate_rows = diff_data(diff_data.Uncertain_Rate == rate_val, :);
            % 每个当前比例的基线只计算一次
            total_baseline_trials_for_diff = total_baseline_trials_for_diff + rate_rows.Baseline_Total(1);
            total_baseline_accepts_for_diff = total_baseline_accepts_for_diff + rate_rows.Baseline_Accept(1);
        end
        
        if total_baseline_trials_for_diff > 0
            average_baseline_accept_rate = total_baseline_accepts_for_diff / total_baseline_trials_for_diff;
        else
            average_baseline_accept_rate = NaN;
        end
        
        if total_cond_trials > 0
            overall_cond_accept_rate = total_cond_accepts / total_cond_trials;
            
            % 使用平均基线接受率计算偏差
            overall_deviation = overall_cond_accept_rate - average_baseline_accept_rate;
            
            % 计算该差异下所有条目的平均偏差（与平均基线）
            mean_deviation_from_avg = mean(diff_data.Deviation_From_Average_Baseline);
            std_deviation_from_avg = std(diff_data.Deviation_From_Average_Baseline);
            
            n_uncertain_rates = height(diff_data);
            
            new_row = {diff_val, total_cond_trials, total_cond_accepts, overall_cond_accept_rate, ...
                average_baseline_accept_rate, overall_deviation, ...
                mean_deviation_from_avg, std_deviation_from_avg, n_uncertain_rates};
            summary_table = [summary_table; new_row];
            
            fprintf('差异=%.2f: 试次=%d, 条件接受率=%.4f, 平均基线=%.4f, 偏差=%.4f (涉及%d个不确定点)\n', ...
                diff_val, total_cond_trials, overall_cond_accept_rate, ...
                average_baseline_accept_rate, overall_deviation, n_uncertain_rates);
        end
    end
    
    % 设置列名
    if ~isempty(summary_table)
        summary_table.Properties.VariableNames = {'Rate_Diff', ...
            'Total_Cond_Trials', 'Total_Cond_Accepts', 'Overall_Cond_Accept_Rate', ...
            'Average_Baseline_Accept_Rate', 'Overall_Deviation', ...
            'Mean_Deviation', 'Std_Deviation', 'N_Uncertain_Rates'};
        
        fprintf('\n========== 汇总表 ==========\n');
        disp(summary_table);
        
        % 保存汇总
        writetable(summary_table, 'Two_uncertain_rates_rate_diff_summary.csv');
        fprintf('\n汇总已保存: uncertain_rates_rate_diff_summary.csv\n');
        assignin('base', 'uncertain_rate_diff_summary', summary_table);
        
        % 绘图建议
        fprintf('\n========== 可视化建议 ==========\n');
        fprintf('绘制偏差曲线:\n');
        fprintf('  figure;\n');
        fprintf('  plot(summary_table.Rate_Diff, summary_table.Overall_Deviation, ''o-'', ''LineWidth'', 2, ''MarkerSize'', 8);\n');
        fprintf('  xlabel(''Rate Difference (Prev - Current)'');\n');
        fprintf('  ylabel(''Accept Rate Deviation'');\n');
        fprintf('  title(''Sequential Effect on Uncertain Rates'');\n');
        fprintf('  grid on;\n');
        fprintf('  yline(0, ''--'', ''Color'', ''k'');\n');
        fprintf('\n说明:\n');
        fprintf('  - Average_Baseline_Accept_Rate: 该差异涉及的所有当前比例的平均基线接受率\n');
        fprintf('  - Overall_Deviation: 条件接受率 - 平均基线接受率\n');
        fprintf('  - results_table中的Deviation_From_Average_Baseline列存储了每行与平均基线的偏差\n');
    end
else
    fprintf('未找到不确定比例点的有效数据\n');
end

fprintf('\n分析完成！\n');