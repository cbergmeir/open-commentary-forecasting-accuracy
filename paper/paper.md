---
title: "An open commentary about evaluation of point forecast accuracy: the current state of the art, recommendations for both academics and practitioners"
author:
  - "First Author \\ Institution A"
  - "Second Author \\ Institution B"
date: \today
abstract: |
  Point forecast evaluation is often discussed as if it were a matter of choosing a metric from a menu. We argue that this view is too shallow. Any evaluation of point forecasts requires three linked design decisions: which functional of the predictive distribution is being targeted, how errors are normalised, and how performance is aggregated across series or tasks. Confusion in practice and in academia typically arises when one or more of these decisions is made implicitly. This commentary therefore organises the discussion around three questions. First, because forecasting is inherently probabilistic, a point forecast should be understood as a summary of a predictive distribution, and the error measure should be aligned with that summary. Second, scale-free comparison always implies a benchmark, whether explicit or hidden in the denominator, and the suitability of that benchmark depends on the data characteristics, especially trend, seasonality, intermittency, and level changes. Third, any aggregation across series expresses a value judgement about which series or tasks matter more. We use these three questions to explain common misuse of MAPE and related measures, to clarify when measures such as WAPE, MASE, and RMSSE are defensible, and to argue that transparent evaluation design matters as much as the choice of forecasting model itself.
---

# Introduction

In practice, people often ask a simple question: what is the best forecasting method? In academic papers, benchmark studies, and practitioner talks, that question is usually followed immediately by a ranking table. But rankings in forecasting are never purely about forecasting methods. They are also about the evaluation system used to compare them.

This is familiar from sports. It is easy to decide who is best at shot put: whoever throws furthest. It is much harder to decide who is the best all-round athlete, because then performances from different disciplines need to be transformed to a common scale and aggregated. The decathlon solves this with a point system that embodies explicit design choices about baselines, curvature, and aggregation. Forecast evaluation works in exactly the same way. Once we compare methods across horizons, series, datasets, or business units, the winner depends on the scoring system we have chosen, not only on the intrinsic quality of the model.

That distinction matters because practice and academia often have different objectives. In production, stakeholders frequently want a stable and interpretable key performance indicator, often ideally one percentage number that can be tracked over time. In academia, the goal is usually to compare methods as fairly and reproducibly as possible, even if the resulting measure is less intuitive for non-specialists. Neither objective is illegitimate, but they do not lead to the same evaluation design. Many current problems in the literature and in practice come from blurring these objectives, for example by using a metric because it is familiar, while ignoring what it rewards, what it penalises, and what kind of point forecast it implicitly prefers [@Hewamalage2023Forecast].

This commentary focuses on point forecast evaluation. Even so, the starting point is probabilistic. Forecasts are never deterministic statements about the future; they are statements about uncertainty. A point forecast is therefore not “the future value”, but a summary of a predictive distribution. Once this is recognised, three questions structure the evaluation problem.

First, which functional of the predictive distribution do we want the point forecast to represent: the mean, the median, the mode, or something else? Second, if we need scale-free comparison, what benchmark are we using to normalise errors, and is that benchmark reasonable for the series at hand? Third, once per-series errors have been computed, how should they be aggregated across series or tasks, and whose priorities does that aggregation reflect?

The rest of the paper is organised around these three questions. Section 1 argues that all point forecast evaluation starts from a predictive distribution and that an error measure should be coherent with the summary statistic one wants to elicit. Section 2 argues that normalisation is never neutral: every scale-free measure embeds a benchmark and inherits its strengths and weaknesses. Section 3 argues that aggregation across series is an explicit value judgement and should be treated as such. Our main message is simple: there is no universally best error measure, but there are many choices that are poorly aligned with the forecasting problem and should therefore no longer be used by default.

# 1 Forecasting is always probabilistic

Forecasting is fundamentally different from problems in which the target can in principle be predicted almost perfectly. In most forecasting settings there is irreducible uncertainty, and thus there is almost always a non-degenerate distribution for the future value. Whether this distribution is produced explicitly by a probabilistic model or only implicitly by a point forecasting workflow is secondary. Conceptually, the object of interest is the predictive distribution $Y_{t+h} \mid \mathcal{F}_t$, not a single number.

This point is well understood in the statistical forecasting literature [@gneiting2007strictly], but it is still easy to forget when working with leaderboards, forecasting competitions, or business dashboards. A model may output one number, yet that number is meaningful only as a particular summary of uncertainty. Classical state space models estimated by likelihood typically target a conditional mean; quantile methods target specific quantiles; intermittent-demand methods often need special care because the predictive distribution is highly asymmetric and concentrated near zero. Modern machine learning systems may or may not output an explicit distribution, but the same logic applies: the point forecast is only interpretable relative to the loss or scoring rule that defines it.

## 1.1 A point forecast is a summary statistic, not the future itself

Consider a stylised rainfall forecast for tomorrow:

- probability $0.80$ of $0$ mm,
- probability $0.15$ of $5$ mm,
- probability $0.05$ of $40$ mm.

If we insist on reporting one number, several defensible summaries are available. The mode is $0$ mm, because no rain is the most likely single outcome. The median is also $0$ mm, because the cumulative probability already exceeds $0.5$ at zero. The mean is

$$
\mathbb{E}[Y] = 0 \cdot 0.80 + 5 \cdot 0.15 + 40 \cdot 0.05 = 2.75 \text{ mm}.
$$

None of these summaries is “the correct forecast” in isolation. Each is correct for a different purpose. If the decision is whether to carry a small umbrella, the mean may be more relevant than the mode because the small probability of heavy rain matters. If the decision is whether rain is more likely than not, the mode or median may be more natural. The predictive distribution is in principle independent of the downstream decision; the point forecast is not. Choosing a point forecast is therefore already part of decision design.

This observation is central and often underappreciated in practice. People sometimes talk as if the point forecast should be the “most likely value”. That is only true under a very particular loss, namely a 0--1 loss that rewards exact hits and penalises all misses equally. For continuous outcomes that loss is rarely useful. In most business settings, missing by a large amount is worse than missing by a small amount, so the choice of point forecast must depend on how errors are valued.

## 1.2 Different error measures elicit different summaries

Formally, a point forecast solves

$$
\hat{y}_{t+h} = \arg\min_a \mathbb{E}\left[L(a, Y_{t+h})\right],
$$

where $L(a,y)$ is the loss incurred by predicting $a$ when the outcome is $y$. Different losses elicit different optimal summaries of the predictive distribution [@gneiting2007strictly; @kolassa2020best]. For the most common cases:

- squared error $L(a,y)=(a-y)^2$ elicits the mean,
- absolute error $L(a,y)=|a-y|$ elicits the median,
- 0--1 loss elicits the mode.

This immediately implies that the common point forecast measures are not interchangeable. Root mean squared error (RMSE) and mean absolute error (MAE) are not just two different ways of summarising the same notion of accuracy. They reward different forecast targets. If two models produce similar predictive distributions but one is better at estimating the mean while the other is better at estimating the median, RMSE and MAE may rank them differently without either ranking being wrong.

This is one reason why the blanket question “should I use RMSE or MAE?” has no universal answer. If the business decision is approximately linear in the absolute deviation, MAE may be appropriate. If large misses are disproportionately costly and the forecast target is a mean, RMSE may be preferable. If the predictive distribution is symmetric, the distinction is often less consequential because mean and median coincide, which is why RMSE- and MAE-based comparisons can sometimes agree in simple stationary settings [@Hyndman2006Another; @Hewamalage2023Forecast]. But in skewed or intermittent settings the distinction matters a great deal.

## 1.3 Why MAPE and sMAPE remain problematic

The appeal of percentage errors is easy to understand. They seem scale-free and are easy to explain to non-specialists. That appeal, however, should not obscure their conceptual and statistical problems.

Mean absolute percentage error (MAPE) is undefined when the actual value is zero, unstable when the actual value is small, asymmetric in undesirable ways, and not elicitable by a meaningful central functional in general [@Hyndman2006Another; @kolassa2020best]. It therefore does not simply target “the mean in percentage terms” or “the median in percentage terms”. In practical terms, it tends to reward underforecasting in many settings and can produce deeply misleading results when small denominators occur.

Symmetric MAPE (sMAPE) does not resolve the underlying problem. It fixes one notion of asymmetry by changing the denominator, but introduces others, remains problematic around zeros, and can assign extreme penalties in intermittent-demand settings precisely when many actual values are zero. Adding arbitrary constants or ad hoc lower bounds to these denominators may improve numerical stability, but then one loses any clear understanding of what functional the measure is eliciting. Once the denominator is engineered by hand, the metric may remain computable while ceasing to have a clean decision-theoretic interpretation.

For these reasons, we argue that MAPE should no longer be used as a default point forecast measure, and that sMAPE should not be treated as its clean fix. Their continued use is best explained historically and institutionally, not statistically.

## 1.4 The training loss and the evaluation measure should usually align

The same logic extends from evaluation to model estimation. If a model is estimated under a criterion that targets the conditional mean, then evaluating it primarily with RMSE-type measures is coherent. This is one reason why likelihood-based ARIMA and ETS models are naturally associated with mean-oriented evaluation. By contrast, evaluating all methods only with MAE or MASE may inadvertently favour methods that are better at predicting medians, even when the competing models were not designed to do so.

This does not mean that train and test losses must always be identical. In finite samples, robustness considerations can justify departures, and in some applications the eventual business loss is only approximately known. But such departures should be explicit. If the point forecast target is unknown, reporting several measures can be sensible, provided one measure is clearly designated as primary and the others are used as sensitivity analysis rather than as an undisciplined metric buffet. In other words, multiple measures are useful when they answer different questions, not when they are used in the hope that one will make the preferred method look good.

# 2 Normalisation is choosing a benchmark

Scale-dependent measures such as MAE and RMSE are perfectly meaningful when evaluating one series in its own units. In fact, this is often the cleanest situation because the results remain directly interpretable. Problems arise when we want to compare errors across series with different units or scales, or when we want to aggregate performance across many series. Then we need to normalise.

Normalisation is often presented as a technical afterthought, but it is not. Any normalisation divides forecast errors by something, and that “something” acts as a benchmark. Once this is recognised, many apparent disagreements between measures become easier to understand.

## 2.1 Why there is no universal denominator

Suppose we want to compare two models across many series. A raw MAE of $10$ is large for a low-volume SKU and negligible for a national energy load series. So we divide by a scale term. The crucial question is what that scale term represents.

If we divide by the actual value at each time point, we obtain percentage errors, with the problems discussed above. If we divide by the sum of absolute actuals over the test set, we obtain WAPE. If we divide by the mean absolute first difference in the training set, we obtain MASE [@Hyndman2006Another]. If we divide by the error of an explicit benchmark method, we obtain relative measures such as rMAE or rRMSE [@Davydenko2013Measuring]. These are not minor algebraic variants. They correspond to different notions of what a “large” error is.

There is therefore no denominator that is automatically appropriate for every series. A good denominator for stationary intermittent demand can be a bad denominator for strongly trended macroeconomic or financial series. A denominator that works well for seasonal retail demand may be a poor choice for event-driven web traffic or for bounded physical processes such as wind power capacity factors. The right way to think about normalisation is not to ask which scaled measure is universally best, but which benchmark makes forecast errors meaningfully comparable for the data-generating features at hand.

## 2.2 WAPE is interpretable because it uses a simple benchmark

Weighted absolute percentage error,

$$
\text{WAPE} = \frac{\sum_t |y_t-\hat{y}_t|}{\sum_t |y_t|},
$$

is often attractive to practitioners because it is easy to communicate. But its interpretability comes from a very particular choice of benchmark. As noted by Hyndman [@Hyndman2025WAPE], WAPE can be read as a relative MAE with a constant-zero forecast in the denominator. That benchmark is sensible only when a zero forecast is a meaningful baseline.

This explains both the strengths and the weaknesses of WAPE. For sparse intermittent series without pronounced trend, a zero baseline may be defensible, and WAPE can work reasonably well. This is one reason why it remains popular in inventory contexts [@Kolassa2007Advantages]. But the same logic also shows why WAPE is a poor universal default. When the series has trend, level changes, or strong seasonality, the denominator changes with the holdout sample in ways that have little to do with forecasting skill. A method can produce the same absolute errors on two different test windows and still appear better on the later window merely because the series level has drifted upward.

The key point is not that WAPE is always wrong. The key point is that its denominator hard-codes a specific baseline, whether or not the user acknowledges it. If zero is not a serious benchmark, the measure is misaligned with the forecasting task.

## 2.3 MASE and RMSSE make the benchmark explicit

MASE and RMSSE are often stronger defaults for research comparison because they scale by in-sample performance of a naive benchmark rather than by the realised magnitude of the holdout. For a non-seasonal series, MASE uses the average absolute first difference in the training sample; for a seasonal series, a seasonal analogue can be used [@Hyndman2006Another]. RMSSE applies the same logic in squared-error form.

These measures have two major advantages. First, they retain a clear connection to the forecast target: MASE is median-oriented and RMSSE is mean-oriented. Second, they are typically less distorted by trend in the holdout sample because the denominator is estimated from the training data rather than from the realised test values. This is the core reason why benchmark-based scaling is often preferable in academic comparisons and in large benchmark datasets, as also stressed in recent practitioner-oriented summaries of the state of the art.

That said, benchmark-based scaling is not magic either. MASE is only as meaningful as the naive benchmark embodied in its denominator. If a simple naive method is structurally inappropriate for the series, then the scaled error inherits that weakness. For example, if the series follows a strong exponential trend, then a one-step naive benchmark may be much less informative than on a weakly dependent stationary series. The same principle applies more generally: scaled and relative measures should be designed around a benchmark that represents a credible fallback forecast.

## 2.4 Trend, seasonality, intermittency, and boundedness require different defaults

The main practical implication is that normalisation should start from the data characteristics.

For one series in one operational setting, scale-dependent measures may be best because they remain interpretable in the original units. For collections of series with similar scale and direct business comparability, an aggregate scale-dependent measure may also be acceptable if high-volume series are intentionally meant to matter more.

For stationary or approximately stationary collections where cross-series comparison is required, MASE or RMSSE are often defensible defaults. For intermittent demand, percentage-type measures are especially dangerous because zeros and small values dominate the denominator; WAPE may be acceptable in some stationary sparse settings, but MAE-type measures can also be problematic because they elicit the median, which is often zero. For trending or level-shifting series, any measure whose denominator depends directly on the magnitude of the test set should be treated with caution. For seasonal series, the benchmark should usually be seasonal as well.

The deeper lesson is that scale-free evaluation is never a property of the numerator alone. It depends just as much on the benchmark in the denominator. Asking “how should I normalise?” is therefore equivalent to asking “relative to what baseline behaviour should this error be judged?”

# 3 Aggregation across series is a value judgement

Once an error has been computed per forecast, or per series, a final question remains: how should these quantities be summarised? This is the least discussed step and often the one with the largest practical consequences.

Aggregation is not merely descriptive. It determines which failures count, which successes dominate, and which kinds of methods are favoured. In that sense it plays the same role as the decathlon point system: it defines what kind of all-round performance is rewarded.

## 3.1 Equal weighting and value weighting answer different questions

Suppose we evaluate a method on a large panel of series. If we compute a scale-free measure per series and then take a simple average or median, every series receives equal weight. This is appropriate when every series is regarded as one forecasting problem of equal scientific importance.

If instead we compute an aggregate error over all observations first, as in a global WAPE or MAE, then high-volume series dominate. This is appropriate when business value is roughly proportional to scale: a one-unit error on a large-revenue series may indeed matter more than a one-unit error on a tiny series. In that case, the weighting is intentional, not a flaw.

Neither approach is universally correct. They answer different questions. Scale-free per-series aggregation asks whether the method performs well across forecasting problems. Global aggregation in original units asks whether the method performs well where the volume is largest. In practice, many organisations want something between these extremes: not complete equality across series, but also not a metric in which one giant series overwhelms thousands of smaller yet still relevant ones.

## 3.2 Competition leaderboards make these choices visible

Recent benchmark datasets make the issue very concrete. In practitioner settings it is increasingly common to evaluate methods over large heterogeneous collections of series and then publish a single leaderboard score. But that single number is the output of several design decisions.

Consider a leaderboard that computes MASE per series, then takes a median within each task, then normalises relative to a benchmark, and finally aggregates across tasks using a geometric mean. This design rewards methods that are broadly reliable and penalises those that fail badly on a subset of tasks. That may be exactly the intended objective. But it also means that the final ranking depends strongly on how tasks are defined and weighted. A single river-flow series represented at daily, weekly, and monthly frequencies can end up with more influence on the final ranking than a much larger collection of economically important series if each task receives equal weight. This is not an error in arithmetic. It is a value judgement embedded in the evaluation design.

The lesson is the same as in the decathlon analogy from the introduction. Once we aggregate across heterogeneous tasks, we are no longer asking only “which method forecasts best?” We are asking “which method forecasts best under this specific weighting of failures, scales, and domains?” Leaderboards are useful, but their scoring rules should be interpreted as part of the benchmark, not as neutral facts.

## 3.3 What should count more in practice?

For practical forecast evaluation, the weighting scheme should be chosen deliberately and explained in business terms.

If all series are equally important, use scale-free per-series measures and aggregate them with a mean or median. If larger series matter more because they drive revenue, inventory cost, or service levels, use explicit weights that reflect those stakes. If some strategic series are disproportionately important, assign those weights directly rather than hoping that an off-the-shelf metric will encode the priority by accident. And if robustness matters, report sensitivity to several aggregation choices.

This is especially important when communicating results between technical and non-technical audiences. A scientist may prefer equal weighting because it is methodologically clean. A business stakeholder may prefer value weighting because it aligns with cost. Both positions are reasonable. Problems arise only when the weighting is implicit and the resulting single number is treated as if it carried an objective meaning independent of those priorities.

## 3.4 Recommendations for summarising performance

Three practical rules follow.

First, separate the within-series error measure from the across-series aggregation step. They solve different problems and should not be conflated.

Second, make the weighting scheme explicit. “Equal weight per series”, “equal weight per task”, and “weight proportional to revenue” are all defensible choices, but they describe different objectives.

Third, avoid reporting only one grand average whenever the result could be driven by a few atypical tasks or by a hidden weighting effect. At minimum, a primary aggregate should be accompanied by a small amount of distributional information, such as a median together with a mean, or task-level summaries that make obvious where the method wins and where it fails.

# Conclusion

Point forecast evaluation is often made unnecessarily confusing because three different design choices are mixed together. The first is elicitation: which summary of the predictive distribution should the point forecast represent? The second is normalisation: relative to which benchmark should errors be judged? The third is aggregation: which series or tasks should carry more weight in the final summary?

Once these questions are separated, many long-running debates become more tractable. RMSE and MAE are not rivals in search of one winner; they target different functionals. WAPE is not a universally interpretable percentage measure; it is a relative error built around a zero benchmark and therefore appropriate only in some settings. MASE and RMSSE are often strong defaults for comparative work because they make the benchmark explicit and are less sensitive to holdout scale, but they still depend on the relevance of the naive baseline. And any summary across many series is inevitably a statement about what matters more.

Our recommendations are therefore straightforward. Start from the predictive distribution and the decision problem, not from a familiar metric. Avoid MAPE and do not treat sMAPE as a general repair. When normalisation is needed, choose a benchmark that is defensible for the data characteristics of the series. When aggregating across many series, state clearly whether the goal is equality across forecasting problems, weighting by business value, or something in between.

The broader implication is that evaluation design is itself part of forecasting methodology. A leaderboard, a benchmark table, or a business KPI is only as meaningful as the choices that produced it. If forecasting is to improve in both academia and practice, those choices need to become explicit, technically defensible, and aligned with the decision context they are meant to serve.