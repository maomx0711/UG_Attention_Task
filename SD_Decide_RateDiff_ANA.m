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

% 初始化总的results_table（包含所有被试）
all_results_table = table();

% 处理每个被试
for ni = 1:Sub_num
    tokens = strsplit(filenames{ni}, '_');
    if length(tokens) >= 2
        sub_name = tokens{2};
    else
        sub_name = filenames{ni};
    end
    fprintf('========== [%d/%d] 处理被试: %s ==========\n', ni, Sub_num, sub_name);
    
    % 加载数据
    data_result = load(fullfile(folder, filenames{ni}));
    result_data = data_result.result;
    
    % 提取有效数据
    n = 0;
    data_temp = [];
    
    for i = 1:125
        n = n + 1;
        data_temp(1,n) = result_data(7,i);  % rates
        data_temp(2,n) = result_data(9,i);  % self money
        data_temp(3,n) = result_data(4,i);  % accept or not
        data_temp(4,n) = result_data(10,i); % other money
        data_temp(5,n) = result_data(5,i);  % reaction time
    end
    
    % 提取数据
    rates = data_temp(1, :);
    accept = data_temp(3, :);
    
    % 为该被试初始化计数器
    % 结构：[当前比例][比例差异][前一试次决策] -> {总次数, 接受次数}
    subject_counts = struct();
    subject_baseline = struct();
    
    for rate_idx = 1:n_rates
        rate_str = sprintf('rate_%.0f', all_rates(rate_idx) * 100);
        subject_baseline.(rate_str) = struct('total', 0, 'accept', 0);
    end
    
    % 遍历所有试次，统计该被试的基线接受率和条件接受率
    for i = 2:125  % 从第2个试次开始
        current_rate = rates(i);
        prev_rate = rates(i-1);
        current_accept = accept(i);
        prev_accept = accept(i-1);
        
        % 只保留当前比例和前一比例都在0.1-0.5范围内的试次
        if current_rate < 0.1 || current_rate > 0.5 || prev_rate < 0.1 || prev_rate > 0.5
            continue;
        end
        
        % 使用容差匹配比例
        tolerance = 0.001;
        current_rate_matched = NaN;
        prev_rate_matched = NaN;
        
        for r = 1:n_rates
            if abs(current_rate - all_rates(r)) < tolerance
                current_rate_matched = all_rates(r);
            end
            if abs(prev_rate - all_rates(r)) < tolerance
                prev_rate_matched = all_rates(r);
            end
        end
        
        if isnan(current_rate_matched) || isnan(prev_rate_matched)
            continue;
        end
        
        % 更新基线计数
        rate_str = sprintf('rate_%.0f', current_rate_matched * 100);
        subject_baseline.(rate_str).total = subject_baseline.(rate_str).total + 1;
        subject_baseline.(rate_str).accept = subject_baseline.(rate_str).accept + current_accept;
        
        % 计算比例差异：前一试次 - 当前试次
        rate_diff = prev_rate_matched - current_rate_matched;
        rate_diff = round(rate_diff / 0.05) * 0.05;  % 四舍五入到0.05
        
        % 根据前一试次决策创建键名
        if rate_diff >= 0
            diff_base = sprintf('diff_%.0f', rate_diff * 100);
        else
            diff_base = sprintf('diff_neg_%.0f', abs(rate_diff) * 100);
        end
        
        % 区分前一试次接受/拒绝
        if prev_accept == 1
            diff_str = [diff_base '_prevAccept'];
        else
            diff_str = [diff_base '_prevReject'];
        end
        
        % 初始化结构（如果不存在）
        if ~isfield(subject_counts, rate_str)
            subject_counts.(rate_str) = struct();
        end
        if ~isfield(subject_counts.(rate_str), diff_str)
            subject_counts.(rate_str).(diff_str) = struct('total', 0, 'accept', 0);
        end
        
        % 更新计数
        subject_counts.(rate_str).(diff_str).total = subject_counts.(rate_str).(diff_str).total + 1;
        subject_counts.(rate_str).(diff_str).accept = subject_counts.(rate_str).(diff_str).accept + current_accept;
    end
    
    % 为该被试创建结果表
    rate_fields = fieldnames(subject_counts);
    
    for r = 1:length(rate_fields)
        rate_str = rate_fields{r};
        current_rate = str2double(rate_str(6:end)) / 100;
        
        % 计算基线接受率
        baseline_total = subject_baseline.(rate_str).total;
        baseline_accept = subject_baseline.(rate_str).accept;
        if baseline_total > 0
            baseline_accept_rate = baseline_accept / baseline_total;
        else
            baseline_accept_rate = NaN;
        end
        
        % 获取所有条件（比例差异×前一决策）
        diff_fields = fieldnames(subject_counts.(rate_str));
        
        for d = 1:length(diff_fields)
            diff_str = diff_fields{d};
            
            % 解析比例差异值和前一试次决策
            if ~isempty(strfind(diff_str, 'prevAccept'))
                prev_decision = 'Accept';
                diff_str_clean = strrep(diff_str, '_prevAccept', '');
            elseif ~isempty(strfind(diff_str, 'prevReject'))
                prev_decision = 'Reject';
                diff_str_clean = strrep(diff_str, '_prevReject', '');
            else
                continue;
            end
            
            % 解析比例差异值
            if ~isempty(strfind(diff_str_clean, 'neg'))
                rate_diff = -str2double(regexp(diff_str_clean, '\d+', 'match', 'once')) / 100;
            else
                rate_diff = str2double(regexp(diff_str_clean, '\d+', 'match', 'once')) / 100;
            end
            
            % 获取该条件的统计
            cond_total = subject_counts.(rate_str).(diff_str).total;
            cond_accept = subject_counts.(rate_str).(diff_str).accept;
            
            if cond_total > 0
                % 计算条件接受率
                cond_accept_rate = cond_accept / cond_total;
                
                % 计算与自己基线的偏差
                deviation_from_own = cond_accept_rate - baseline_accept_rate;
                
                % 添加到总表（暂时不计算与平均基线的偏差）
                new_row = {sub_name, current_rate, rate_diff, prev_decision, ...
                    baseline_total, baseline_accept, baseline_accept_rate, ...
                    cond_total, cond_accept, cond_accept_rate, ...
                    deviation_from_own, NaN};  % 最后一列是与平均基线的偏差
                all_results_table = [all_results_table; new_row];
            end
        end
    end
    
    fprintf('被试 %s 处理完成\n\n', sub_name);
end

% 设置列名
if ~isempty(all_results_table)
    all_results_table.Properties.VariableNames = {'Subject', 'Current_Rate', 'Rate_Diff', 'Prev_Decision', ...
        'Baseline_Total', 'Baseline_Accept', 'Baseline_Accept_Rate', ...
        'Cond_Total', 'Cond_Accept', 'Cond_Accept_Rate', ...
        'Deviation_From_Own_Baseline', 'Deviation_From_Average_Baseline'};
    
    % ===== 计算每行与平均基线的偏差 =====
    fprintf('\n========== 计算与平均基线的偏差 ==========\n');
    
    all_diffs = unique(all_results_table.Rate_Diff);
    all_decisions = unique(all_results_table.Prev_Decision);
    
    % 对每个（比例差异，前一决策）组合计算平均基线
    for d = 1:length(all_diffs)
        diff_val = all_diffs(d);
        
        for dec = 1:length(all_decisions)
            decision = all_decisions{dec};
            
            % 找出该（差异，决策）组合的所有行
            cond_rows_idx = (all_results_table.Rate_Diff == diff_val) & ...
                           strcmp(all_results_table.Prev_Decision, decision);
            cond_data = all_results_table(cond_rows_idx, :);
            
            if isempty(cond_data)
                continue;
            end
            
            % 计算该条件下所有涉及的当前比例的平均基线接受率
            unique_rates_in_cond = unique(cond_data.Current_Rate);
            
            % 对每个当前比例，计算跨被试的总基线
            total_baseline_trials_for_cond = 0;
            total_baseline_accepts_for_cond = 0;
            
            for ur = 1:length(unique_rates_in_cond)
                rate_val = unique_rates_in_cond(ur);
                rate_rows = cond_data(cond_data.Current_Rate == rate_val, :);
                
                % 跨被试汇总该比例的基线
                total_baseline_trials_for_cond = total_baseline_trials_for_cond + sum(rate_rows.Baseline_Total);
                total_baseline_accepts_for_cond = total_baseline_accepts_for_cond + sum(rate_rows.Baseline_Accept);
            end
            
            if total_baseline_trials_for_cond > 0
                average_baseline_accept_rate = total_baseline_accepts_for_cond / total_baseline_trials_for_cond;
            else
                average_baseline_accept_rate = NaN;
            end
            
            % 更新该条件所有行的平均基线偏差
            all_results_table.Deviation_From_Average_Baseline(cond_rows_idx) = ...
                all_results_table.Cond_Accept_Rate(cond_rows_idx) - average_baseline_accept_rate;
            
            fprintf('差异=%.2f, 前一决策=%s: 平均基线接受率=%.4f (基于%d个当前比例)\n', ...
                diff_val, decision, average_baseline_accept_rate, length(unique_rates_in_cond));
        end
    end
    
    % 排序：按被试、当前比例、比例差异、前一决策
    all_results_table = sortrows(all_results_table, {'Subject', 'Current_Rate', 'Rate_Diff', 'Prev_Decision'});
    
    % 显示结果表
    fprintf('\n========== 完整结果表（前30行）==========\n');
    disp(all_results_table(1:min(30, height(all_results_table)), :));
    
    % 保存结果
    writetable(all_results_table, 'rate_diff_by_subject_and_prev_decision.csv');
    fprintf('\n被试级别结果已保存: rate_diff_by_subject_and_prev_decision.csv\n');
    
    % 保存到工作区
    assignin('base', 'subject_rate_diff_results', all_results_table);
    
    % ========== 按（比例差异，前一决策）汇总（跨所有被试）==========
    fprintf('\n========== 按比例差异和前一决策汇总 ==========\n\n');
    
    all_diffs = sort(unique(all_results_table.Rate_Diff));
    summary_table = table();
    
    for d = 1:length(all_diffs)
        diff_val = all_diffs(d);
        
        for dec = 1:length(all_decisions)
            decision = all_decisions{dec};
            
            % 筛选该（差异，决策）组合的所有数据
            cond_data = all_results_table((all_results_table.Rate_Diff == diff_val) & ...
                                         strcmp(all_results_table.Prev_Decision, decision), :);
            
            if isempty(cond_data)
                continue;
            end
            
            % 计算总的条件接受率
            total_cond_trials = sum(cond_data.Cond_Total);
            total_cond_accepts = sum(cond_data.Cond_Accept);
            
            % 计算该条件下所有涉及的当前比例的平均基线接受率
            unique_rates_in_cond = unique(cond_data.Current_Rate);
            total_baseline_trials_for_cond = 0;
            total_baseline_accepts_for_cond = 0;
            
            for ur = 1:length(unique_rates_in_cond)
                rate_val = unique_rates_in_cond(ur);
                rate_rows = cond_data(cond_data.Current_Rate == rate_val, :);
                total_baseline_trials_for_cond = total_baseline_trials_for_cond + sum(rate_rows.Baseline_Total);
                total_baseline_accepts_for_cond = total_baseline_accepts_for_cond + sum(rate_rows.Baseline_Accept);
            end
            
            if total_baseline_trials_for_cond > 0
                average_baseline_accept_rate = total_baseline_accepts_for_cond / total_baseline_trials_for_cond;
            else
                average_baseline_accept_rate = NaN;
            end
            
            if total_cond_trials > 0
                overall_cond_accept_rate = total_cond_accepts / total_cond_trials;
                overall_deviation = overall_cond_accept_rate - average_baseline_accept_rate;
                
                mean_deviation_from_avg = mean(cond_data.Deviation_From_Average_Baseline, 'omitnan');
                std_deviation_from_avg = std(cond_data.Deviation_From_Average_Baseline, 'omitnan');
                n_current_rates = length(unique_rates_in_cond);
                n_subjects = length(unique(cond_data.Subject));
                n_data_points = height(cond_data);
                
                new_row = {diff_val, decision, total_cond_trials, total_cond_accepts, overall_cond_accept_rate, ...
                    average_baseline_accept_rate, overall_deviation, ...
                    mean_deviation_from_avg, std_deviation_from_avg, ...
                    n_current_rates, n_subjects, n_data_points};
                summary_table = [summary_table; new_row];
                
                fprintf('差异=%.2f, 前一决策=%s: 试次=%d, 条件接受率=%.4f, 平均基线=%.4f, 偏差=%.4f (涉及%d个比例, %d名被试)\n', ...
                    diff_val, decision, total_cond_trials, overall_cond_accept_rate, ...
                    average_baseline_accept_rate, overall_deviation, n_current_rates, n_subjects);
            end
        end
    end
    
    % 设置列名
    if ~isempty(summary_table)
        summary_table.Properties.VariableNames = {'Rate_Diff', 'Prev_Decision', ...
            'Total_Cond_Trials', 'Total_Cond_Accepts', 'Overall_Cond_Accept_Rate', ...
            'Average_Baseline_Accept_Rate', 'Overall_Deviation', ...
            'Mean_Deviation', 'Std_Deviation', ...
            'N_Current_Rates', 'N_Subjects', 'N_Data_Points'};
        
        % 显示汇总表
        fprintf('\n========== 汇总表 ==========\n');
        disp(summary_table);
        
        % 保存汇总
        writetable(summary_table, 'rate_diff_summary_by_prev_decision.csv');
        fprintf('\n汇总已保存: rate_diff_summary_by_prev_decision.csv\n');
        
        % 保存到工作区
        assignin('base', 'rate_diff_summary', summary_table);
        
        % 绘图建议
        fprintf('\n========== 可视化建议 ==========\n');
        fprintf('绘制两条偏差曲线（区分前一试次决策）:\n');
        fprintf('  figure;\n');
        fprintf('  hold on;\n');
        fprintf('  accept_data = summary_table(strcmp(summary_table.Prev_Decision, ''Accept''), :);\n');
        fprintf('  reject_data = summary_table(strcmp(summary_table.Prev_Decision, ''Reject''), :);\n');
        fprintf('  plot(accept_data.Rate_Diff, accept_data.Overall_Deviation, ''o-'', ''LineWidth'', 2, ''DisplayName'', ''前接受'');\n');
        fprintf('  plot(reject_data.Rate_Diff, reject_data.Overall_Deviation, ''s-'', ''LineWidth'', 2, ''DisplayName'', ''前拒绝'');\n');
        fprintf('  xlabel(''Rate Difference (Prev - Current)'');\n');
        fprintf('  ylabel(''Accept Rate Deviation'');\n');
        fprintf('  title(''Sequential Effect by Previous Decision'');\n');
        fprintf('  legend;\n');
        fprintf('  grid on;\n');
        fprintf('  yline(0, ''--'', ''Color'', ''k'');\n');
    end
else
    fprintf('未找到有效数据\n');
end

fprintf('\n分析完成！\n');