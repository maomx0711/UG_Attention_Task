# 最后通牒任务序列依赖效应分析

# Sequential Dependency Analysis for Ultimatum Game (UG) Task

## 概述 | Overview

本模块实现了四种数学模型，用于验证最后通牒任务（Ultimatum Game）中被试决策的序列依赖效应假设。

This module implements four mathematical models to verify hypotheses about sequential dependency effects in the Ultimatum Game decision-making task.

## 研究假设 | Research Hypotheses

### 假设1 (H1): 仅当前金额影响决策
被试的决策仅依赖当前金额。如果金额达到内在标准则选择接受，否则拒绝。

**Hypothesis 1 (H1): Current offer only**
Decisions depend solely on the current offer amount. If the offer meets an internal threshold, accept; otherwise, reject.

### 假设2 (H2): 当前和先前金额共同影响决策
被试的决策同时受到先前金额和当前金额的影响。存在对比效应或适应性阈值调整。

**Hypothesis 2 (H2): Current and previous offers**
Decisions depend on both previous and current offer amounts. Contrast effects or adaptive threshold adjustment may occur.

### 假设3 (H3): 金额和先前决策共同影响
被试的决策不仅依赖当前和先前金额的影响，还受到先前决策（接受/拒绝）的影响。

**Hypothesis 3 (H3): Offers and previous decisions**
Decisions depend on current/previous amounts AND are influenced by previous decisions (accept/reject).

## 数学模型 | Mathematical Models

### 模型1: 阈值模型 (Threshold Model) - 测试H1

最简单的logistic回归模型，仅考虑当前offer：

```
P(accept | offer) = sigmoid(β₀ + β₁ × offer)
```

**参数:**
- β₀: 截距（决策阈值位置）
- β₁: 敏感度（决策曲线陡峭程度）

### 模型2: 线性历史模型 (Linear History Model) - 测试H2

包含先前trial信息的logistic回归模型：

```
P(accept | offer_t, offer_{t-1}) = sigmoid(β₀ + β₁×offer_t + β₂×offer_{t-1} + β₃×diff)
```

其中 `diff = offer_t - offer_{t-1}` 是对比效应。

**参数:**
- β₀: 截距
- β₁: 当前offer效应
- β₂: 先前offer效应
- β₃: 对比效应

### 模型3: 贝叶斯决策模型 (Bayesian Decision Model) - 测试H2

基于自适应期望的决策模型：

```
P(accept) = sigmoid(β₀ + β₁×(offer - E[offer]) + β₂×offer)
E[offer]_t = (1-α)×E[offer]_{t-1} + α×offer_{t-1}
```

**参数:**
- β₀: 基线接受偏向
- β₁: 期望偏差敏感度
- β₂: offer直接效应
- α: 学习率

### 模型4: 隐马尔可夫模型 (Hidden Markov Model) - 测试H3

状态依赖的决策模型，假设被试处于两种潜在状态之一：
- 状态0: "严格"状态（较低的接受概率）
- 状态1: "宽松"状态（较高的接受概率）

状态转移概率取决于先前决策（接受/拒绝）。

**参数:**
- π: 初始状态分布
- A: 状态转移矩阵（依赖于先前决策）
- β₀, β₁: 每个状态的发射参数

## 模型比较方法 | Model Comparison Methods

### AIC (Akaike Information Criterion)
```
AIC = 2k - 2ln(L)
```
其中 k 是参数数量，L 是似然值。

### BIC (Bayesian Information Criterion)
```
BIC = k×ln(n) - 2ln(L)
```
其中 n 是样本量。

### 交叉验证 (Cross-Validation)
使用k折交叉验证评估模型预测性能。

## 文件说明 | File Description

### Python版本
- `sequential_dependency_models.py`: Python实现的完整模型比较分析

```python
# 使用示例
from sequential_dependency_models import compare_models, load_behavioral_data

# 加载数据
offers, decisions = load_behavioral_data('your_data.csv')

# 比较模型
results = compare_models(offers, decisions, verbose=True)

# 可视化
plot_model_comparison(results)
```

### MATLAB版本
- `SD_Models_Comparison.m`: MATLAB实现的模型比较分析
- `SD_UG.m`: 原始实验程序
- `SD_Decide_RateDiff_ANA.m`: 基于决策和金额差异的分析
- `SD_Uncertiy_RateDiff_ANA.m`: 基于不确定金额的分析

## 数据格式要求 | Data Format Requirements

### CSV格式
需要包含以下列（或类似命名）：
- `offer` / `rate` / `discount`: offer比例 (0-1)
- `decision` / `accept`: 决策 (1=接受, 0=拒绝)

### MAT格式（MATLAB）
需要包含 `result` 矩阵：
- `result(7,:)`: discount rate (offer proportion)
- `result(4,:)`: decision (1=accept, 0=reject)

## 安装依赖 | Dependencies

### Python
```bash
pip install numpy pandas scipy matplotlib
```

### MATLAB
- MATLAB R2016b 或更新版本
- Optimization Toolbox

## 使用示例 | Usage Example

### Python示例

```python
#!/usr/bin/env python3
from sequential_dependency_models import *

# 1. 使用模拟数据进行演示
offers, decisions, true_params = simulate_ug_data(
    n_trials=200, 
    true_model='H2',  # 数据从H2模型生成
    seed=42
)

# 2. 比较四个模型
results = compare_models(offers, decisions, verbose=True)

# 3. 查看结果
print(results['comparison'])

# 4. 绘制心理物理曲线
plot_psychometric_curves(results, offers, decisions)

# 5. 交叉验证
cv_results = cross_validate_models(offers, decisions, n_folds=5)
```

### MATLAB示例

```matlab
% 运行完整的模型比较分析
run('SD_Models_Comparison.m')

% 或者单独调用函数
[params, nll, aic, bic] = fit_threshold_model(offers, decisions, options);
```

## 结果解读 | Interpreting Results

### 1. 查看AIC/BIC值
- 较低的AIC/BIC值表示更好的模型
- ΔAIC或ΔBIC > 10通常表示强烈支持更好的模型

### 2. AIC权重
- 权重表示每个模型是真实模型的相对可能性
- 权重 > 0.9 表示强烈支持该模型

### 3. 假设结论
- 如果阈值模型最优 → 支持H1
- 如果线性历史或贝叶斯模型最优 → 支持H2
- 如果HMM最优 → 支持H3

## 示例输出 | Example Output

```
==============================================================
                    MODEL COMPARISON RESULTS                   
==============================================================

Model                  Params  Log_Likelihood       AIC       BIC    Weight
Threshold (H1)              2         -89.32    182.64    187.64     0.023
Linear History (H2)         4         -82.15    172.30    182.30     0.312
Bayesian (H2)               4         -81.78    171.56    181.56     0.453
HMM (H3)                    9         -80.92    179.84    204.84     0.212

Best model by AIC: Bayesian (H2)
Best model by BIC: Bayesian (H2)

==============================================================
                       HYPOTHESIS SUPPORT                      
==============================================================

Supported Hypothesis: H2
→ Decisions depend on BOTH current and previous offer amounts
  Sequential effects on decision-making are present.
```

## 理论背景 | Theoretical Background

最后通牒任务（Ultimatum Game）是研究公平决策和社会偏好的经典范式。在这个任务中，一方提出分配方案，另一方决定接受或拒绝。

序列依赖效应（Serial Dependence）是指当前决策受到先前刺激或决策的影响，这种效应在许多认知任务中都有发现。在UG任务中，序列依赖可能表现为：

1. **对比效应**: 如果先前收到较高offer，当前较低offer可能更容易被拒绝
2. **适应性阈值**: 决策阈值可能随经验动态调整
3. **状态依赖**: 先前的接受/拒绝决策可能影响当前的决策状态

## 参考文献 | References

1. Güth, W., Schmittberger, R., & Schwarze, B. (1982). An experimental analysis of ultimatum bargaining. Journal of Economic Behavior & Organization.

2. Fischer, J., & Whitney, D. (2014). Serial dependence in visual perception. Nature Neuroscience.

3. Burnham, K. P., & Anderson, D. R. (2002). Model selection and multimodel inference: A practical information-theoretic approach.

## 作者 | Author

Sequential Dependency Analysis Module
Date: 2026-01-05

## 许可证 | License

This project is for research purposes.
