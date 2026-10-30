---
title: "DRAFT: A commentary about evaluation of point forecast accuracy: the current state of the art, recommendations for both academics and practitioners"
author:
  - "First Author \\ Institution A"
  - "Second Author \\ Institution B"
date: \today
abstract: |
  Point forecast evaluation is often discussed as if it were a matter of choosing a metric from a menu. We argue that this view is too shallow. Any evaluation of point forecasts requires three linked design decisions: which functional of the predictive distribution is being targeted, how errors are normalised, and how performance is aggregated across series or tasks. Confusion in practice and in academia typically arises when one or more of these decisions is made implicitly. This commentary therefore organises the discussion around three questions. First, because forecasting is inherently probabilistic, a point forecast should be understood as a summary of a predictive probability distribution, and the error measure should be aligned with that summary. Second, scale-free comparison always implies a benchmark, whether explicit or hidden in the denominator, and the suitability of that benchmark depends on the data characteristics, especially trend, seasonality, intermittency, and level changes. Third, any aggregation across series expresses a value judgement about which series or tasks matter more. We use these three questions to explain common misuse of MAPE and related measures, to clarify when measures such as WAPE, MASE, and RMSSE are defensible, and to argue that transparent evaluation design matters as much as the choice of forecasting model itself.
---

# Introduction

Let us ask a question: "Who is the world's best athlete?" Though the question is simple, the answer is highly subjective. Which categories should define "best," and how much weight should each receive? Is Michael Jordan "better" than Lionel Messi because he dominated one sport and also played professionally in another? Is Michael Phelps better because he achieved 28 Olympic medals, more than anyone else? Lionel Messi has 1 Olympic medal. The question remains open-ended because everyone brings a different set of criteria and priorities.

To make it more concrete, let's consider the decathlon. It combines ten disciplines, such as sprinting, long-distance running, shot put, and javelin. Athletes score points in each event over two days, and the highest total wins. While more tangible, even here, value judgements are unavoidable. While each discipline has a clear local criterion (for example, farther javelin throws are better), aggregating across disciplines requires a mapping to a common scale. The decathlon resolves this through a point system that encodes explicit design choices about baselines, curvature, and aggregation.

The same logic applies to forecasting: "Which is the best forecasting method?" is a question that is easy to ask and difficult to answer. Once we ask which method is "best" across horizons, series, datasets, or business units, the answer depends not only on model quality but also on the scoring system used to compare methods.

Rankings appear quickly in both academic studies and practitioner reports, as they provide a single summary of performance. Yet that summary is never neutral. Every ranking reflects a set of evaluation choices about what is measured, how it is scaled, and how results are aggregated.

This matters for many reasons, one being that practice and academia often have different objectives. In production, stakeholders frequently want a stable and interpretable key performance indicator, often ideally one percentage number that can be tracked over time. In academia, the goal is usually to compare methods as fairly and reproducibly as possible, even if the resulting measure is less intuitive for non-specialists. Neither objective is illegitimate, but they do not lead to the same evaluation design.

Thus, while we want to argue that in principle there is no universal one-size-fits-all forecast evaluation pipeline, there are evaluation methodologies that are clearly better than others, and methodologies that have been shown decades ago to be flawed, yet their use is still widespread. We aim to reflect as well as possible a consensus between many leading researchers in the field of forecasting about what evaluations are best practice in different scenarios, and which ones should be avoided. We'll also reflect in this paper where we as a group of authors disagree on certain standpoints, so that the reader can get a picture of which practices to avoid, which ones to follow, and for which ones there may be both good arguments for or against a certain course of action.

Some examples we will cover are the use of MAPE and sMAPE, which nearly always should be avoided, or normalisations such as mean normalisation for series that have no stable mean, like series with (stochastic) trends, for example from finance [@Hewamalage2023Forecast].

A further source of confusion, particularly in recent years, is the implication by many papers that their single benchmark suite or leaderboard can characterise "time series forecasting" as a whole. The term covers an enormous variety of problems, such as electricity readings, retail sales, web traffic, macroeconomic indicators, or financial prices, that differ dramatically in their statistical properties, relevant horizons, appropriate error measures, and business stakes. A particular example of this is a pocket of research in the machine learning forecasting literature, where a narrow set of time series dominated by the Electricity Transformer Temperature (ETT) datasets [@zhou2021informer] serves as a near-universal benchmark. Papers evaluate methods at fixed long horizons (96, 192, 336, and 720 steps ahead) with diffuse claims of why such long horizons are more important than shorter ones, and they make broad claims about forecasting performance. The papers also typically normalise each series by its training-set mean before computing RMSE and MAE. This choice may make sense for the specific characteristics of these datasets, but it is never made explicit as a limitation. As discussed in Section \ref{sec-normalisation}, such mean-based normalisation is problematic for many real-world time series that have trends, structural breaks, or unstable means.
However, a simple linear model designed for this particular regime (as opposed to generic poorly tuned classical versions of ARIMA) could match or outperform many Transformer architectures on these benchmarks [@Zeng2023Are], which exposes the fundamental problem.
A suite limited to specific data characteristics, frequencies, horizon regimes, and normalisation choices will inherently favour methods that exploit that combination without demonstrating any broader forecasting capability.
The same issue arises when classical statistical models such as ARIMA and ETS are benchmarked in settings they were not designed for. Both handle only a single seasonal period and are primarily suited to lower-frequency series such as monthly or quarterly data. They also target the conditional mean, which aligns them naturally with squared-error evaluation. Comparisons that include them in high-frequency or multi-seasonal benchmarks say little about their performance on the tasks they were actually designed for. Finally, it is worth noting that practitioners rarely need a single model that solves every forecasting problem simultaneously. The quest for a universal best method is largely an academic framing that may not reflect real operational priorities.

This commentary focuses on point forecast evaluation. Even so, the starting point is probabilistic. Forecasts are never deterministic statements about the future; they are statements about uncertainty. A point forecast is therefore not "the future value", but a summary of a predictive probability distribution. Once this is recognised, three questions structure the evaluation problem. First, which functional of the predictive distribution do we want the point forecast to represent: the mean, the median, the mode, or something else? Second, if we need scale-free comparison, what benchmark are we using to normalise errors, and is that benchmark reasonable for the series at hand? Third, once per-series errors have been computed, how should they be aggregated across series or tasks, and whose priorities does that aggregation reflect?

The rest of the paper is organised around these three questions. Section \ref{sec-probabilistic} argues that all point forecast evaluation starts from a predictive probability distribution and that an error measure should be coherent with the summary statistic one wants to elicit. Section \ref{sec-normalisation} argues that normalisation is never neutral: every scale-free measure embeds a benchmark and inherits its strengths and weaknesses. Section \ref{sec-aggregation} argues that aggregation across series is an explicit value judgement and should be treated as such. Throughout, we provide recommendations for two distinct settings: academic benchmark evaluation and practitioner decision support. Our main message is simple: there is no universally best evaluation methodology, but there are methodologies that are clearly better and more generally applicable than others. There are best practices that we try to outline, and there are many choices that are poorly aligned with the forecasting problem and should therefore not be used by default. All error measures referenced in the main text are defined formally in the Appendix (Section \ref{app-measures}).

# Forecasting is always probabilistic {#sec-probabilistic}

Forecasting differs fundamentally from tasks where near-perfect performance is achievable in principle, like many image or language processing tasks. For example, in many image classification tasks, most images have a clear correct label, humans achieve strong performance which gives us a good sense of what accuracies are achievable, and thus sufficiently capable algorithms can approach perfect accuracy with high confidence.

Forecasting, by contrast, involves irreducible uncertainty about future outcomes, and thus there is almost always a non-degenerate distribution for the future value. Whether this distribution is produced explicitly by a probabilistic model or only implicitly by a point forecasting workflow is secondary. Conceptually, the object of interest is not a single number, but the predictive distribution $Y_{t+h} \mid \mathcal{I}_t$, where $\mathcal{I}_t$ contains all relevant information at time $t$.

This point is well understood in the statistical forecasting literature [@gneiting2007strictly], but it is still easy to forget when working with leaderboards, forecasting competitions, or business dashboards. A model may output one number, yet that number is meaningful only as a particular summary of uncertainty. For example, classical state space models estimated by likelihood typically target a conditional mean; quantile methods target specific quantiles; intermittent-demand methods often need special care because the predictive distribution is highly asymmetric and concentrated near zero. Modern machine learning systems may or may not output an explicit distribution, but the same logic applies: the point forecast is only interpretable relative to the loss or scoring rule that defines it.

This is a central point in forecasting. If all stakeholders understand it, significant progress can follow. For instance, stakeholders are often uncomfortable with flat-line forecasts, which sometimes leads forecasters to add noise to the forecasts, slightly degrading accuracy, simply to help some stakeholders accept the forecast. Understanding that a point forecast is a summary statistic that necessarily differs from any particular realisation drawn from that distribution of future values clarifies why the eventual outcome will always appear to diverge from the forecast. The future is one particular draw from the predictive distribution, whereas a point forecast is a number that aims to best summarise the distribution of all possible futures.

## A point forecast is a summary statistic, not the future itself

Consider a stylised rainfall forecast for tomorrow:

- probability $0.80$ of $0$ mm,
- probability $0.15$ of $5$ mm,
- probability $0.05$ of $40$ mm.

If we insist on reporting one number, several defensible summaries are available. The mode is $0$ mm, because no rain is the most likely single outcome. The median is also $0$ mm, because the cumulative probability already exceeds $0.5$ at zero. The mean is
$$
  \mathbb{E}[Y] = 0 \cdot 0.80 + 5 \cdot 0.15 + 40 \cdot 0.05 = 2.75 \text{ mm}.
$$

None of these summaries is "the correct forecast" in isolation. Each is correct for a different purpose. If the decision is whether to carry a small umbrella, the mean may be more relevant than the mode because the small probability of heavy rain may matter more than the downside of carrying around the umbrella all day without needing it. If the decision is whether rain is more likely than not, the mode or median may be more natural. The predictive distribution is in principle independent of the downstream decision; the point forecast is not. Choosing a point forecast is therefore already part of decision design.

This observation is central and often underappreciated in practice. People sometimes talk as if the point forecast should be the "most likely value". However, that is only true under a very particular loss, namely a 0--1 loss that rewards exact hits and penalises all misses equally, and only for discrete outcomes [@gneiting2011making]. In most business settings, missing by a large amount is worse than missing by a small amount, so the choice of point forecast must depend on how errors are valued.

## Different error measures elicit different summaries {#sec-elicitation}

Formally, a point forecast solves
$$
  \hat{y}_{t+h} = \arg\min_a \mathbb{E}\left[L(a, Y_{t+h})\right],
$$
where $L(a,y)$ is the loss incurred by predicting $a$ when the outcome is $y$. Different losses elicit different optimal summaries of the predictive distribution [@gneiting2007strictly; @kolassa2020best]. For the most common cases:

- squared error $L(a,y)=(a-y)^2$ elicits the mean,
- absolute error $L(a,y)=|a-y|$ elicits the median,
- 0--1 loss $L(a,y) = 1 - \mathbf{1}(a=y)$ elicits the mode for discrete outcomes.

Short derivations are provided in the Appendix (Section \ref{app-elicitation}).

Mean optimality here concerns expected squared error. A square root applied after pooling squared errors preserves their ordering, while averaging separately rooted finite-window scores can change the elicited target (Section \ref{sec-root-aggregation}).

This immediately implies that the common point forecast measures are not interchangeable. Root mean squared error (RMSE) and mean absolute error (MAE) are not just two different ways of summarising the same notion of accuracy; they reward different forecast targets. If two models produce similar predictive distributions but one is better at estimating the mean while the other is better at estimating the median, RMSE and MAE may rank them differently without either ranking being wrong.

This is one reason why the blanket question "should I use RMSE or MAE?" has no universal answer. If the business decision is approximately linear in the absolute deviation, MAE may be appropriate. If large misses are disproportionately costly and the forecast target is a mean, RMSE may be preferable.
If forecasts need to add up, e.g., in a hierarchical setting, they also need to be conditional means. If the data is intermittent (namely, if over 50% of the data is zero), the median will be zero, so beating a constant zero forecast under MAE is often not possible in this setting.

If the predictive distribution is symmetric, the distinction is often less consequential because mean and median coincide, which is why RMSE- and MAE-based comparisons can agree in simple stationary settings [@Hyndman2006Another; @Hewamalage2023Forecast]. But in skewed or intermittent settings the distinction can matter a great deal.

Another option worth mentioning, which is used less often, is the Root Mean Squared Logarithmic Error [RMSLE, @Tofallis2015Better], which is RMSE calculated on the logarithms of the actual values and the forecasts (see the Appendix, Section \ref{app-measures}). It is minimised by the geometric mean of the predictive distribution, so it is appropriate when the geometric mean is the target of the point forecast. As it relies on logarithms, it can only be applied when both the actual values and the forecasts are positive.

Furthermore, in many real-world business settings the preferred loss is often at least partly unknown. Should outliers be penalised heavily, and if so, how heavily? RMSE has a particularly clean interpretation under Gaussian error assumptions, where squared loss arises naturally from maximum-likelihood arguments. But that is an assumption about the error distribution, not a universal property of the metric itself. If forecast errors are not approximately normal, then squared error has no special status by default. It is appropriate only when its penalty structure matches the decision problem. If one wanted to penalise large errors even more strongly, higher-order losses such as fourth powers could be considered as well. In these situations, the real question is often how robust a forecast is across different error measures and modelling assumptions. A method that is consistently preferable across a range of plausible measures is very different from one whose ranking changes sharply as soon as the evaluation criterion changes.

## Bias deserves separate attention

Accuracy measures such as RMSE and MAE mix two different components of error: systematic bias and random variation. For squared error this is explicit, as $\mathrm{MSE}=\mathrm{bias}^2+\mathrm{variance}$ of the errors, where bias is the mean error $\frac{1}{n}\sum_t e_t$. Two methods with the same RMSE can therefore behave very differently: one may err randomly in both directions, while the other consistently over- or underforecasts.

In practice this distinction is often important. A persistent bias is rarely tolerated in industry: consistent overforecasting ties up inventory and capital, consistent underforecasting causes stock-outs and lost service, and in both cases stakeholders lose trust in the forecasts. Random errors of similar magnitude are easier to accept, as they average out over time and can be buffered, for example with safety stock. Bias is also easier to correct than random error, which makes it an informative diagnostic. We therefore recommend reporting a signed measure in addition to an accuracy measure, for example the mean error, or the mean error scaled by a suitable reference such as the mean of the actuals, and monitoring it over time, for example with a tracking signal (cumulative error divided by MAE) that flags when bias becomes persistent. The sign convention must always be stated.

Bias is also tied to the elicited functional. A forecast that targets the median is not unbiased in the mean when the predictive distribution is skewed, and this is the usual situation for intermittent or strictly positive data. Whether a given forecast counts as biased therefore depends on the functional we want to elicit, which is another reason to state that target explicitly.

## You should not use MAPE and sMAPE except for legacy comparisons

It has long been established in the forecasting literature that MAPE and sMAPE are problematic measures that should be retired [@Hyndman2006Another; @Armstrong2006Findings; @Kolassa2007Advantages; @Goodwin2011High].
The appeal of percentage errors is easy to understand. They seem scale-free and are easy to explain to non-specialists. That appeal, however, should not obscure their conceptual and statistical problems.
Many researchers have argued that MAPE should no longer be used as a default point forecast measure, and that sMAPE should not be treated as its clean fix. We support this argument. The continued use of these measures is best explained historically and institutionally, not statistically.

### Problems of MAPE and sMAPE

Mean absolute percentage error (MAPE) is undefined when the actual value is zero, unstable when the actual value is small, uninterpretable if the data is not on a ratio scale, asymmetric in undesirable ways, and not elicitable by a meaningful central functional in general [@Hyndman2006Another; @kolassa2020best], which means that if we try to achieve the minimal MAPE, we optimise for something we very likely do not want to optimise for. It does not simply target "the mean in percentage terms" or "the median in percentage terms". In practical terms, it tends to reward underforecasting in many settings and can produce deeply misleading results when small denominators occur. See @kolassa2020best for an illustrative example where MAPE is minimised by a forecast that heavily underpredicts, which is most likely not what a practitioner would want to achieve.

Symmetric MAPE (sMAPE) does not resolve the underlying problem. It fixes one notion of asymmetry by changing the denominator, but introduces others, remains problematic around zeros, and can assign extreme penalties in intermittent-demand settings precisely when many actual values are zero [@Hyndman2006Another; @Kim2016new; @Kolassa2007Advantages].
Adding arbitrary constants or ad hoc lower bounds to these denominators may improve numerical stability, as in the modified sMAPE (msMAPE) [@Suilin2017kaggle; @Smyl2025SparseProof], but then one loses any clear understanding of what functional the measure is eliciting. Once the denominator is engineered by hand, the metric may remain computable while ceasing to have a clean decision-theoretic interpretation.

<!-- Expand this with the papers in Foresight Issue 78, and S. Kolassa's post on Stackoverflow.-->

### Legacy comparisons

We acknowledge that it is justifiable, for example, to use sMAPE to compare a new method with historical results of the M3 and M4 forecasting competitions in a fair way. As the original competition participants knew they were going to be evaluated by this metric, it is plausible that they optimised their forecasts towards it, so now using different measures to compare to these original results would be unfair.
This argument may also be valid in a business setting where we compare with a legacy system. However, we see that in practice this argument should be used with caution, as it is often an easy excuse for stakeholders to stick to business as usual and to outdated practices that clearly have been shown by research to be flawed.

### Why sMAPE is still attractive to practitioners {#sec-smape-attractive}

Despite its problems, sMAPE remains popular among practitioners, and it is worth understanding why. The first reason, especially in some machine learning settings, is that it is bounded between 0 and 200 [@Smyl2025SparseProof], so a single badly forecast series cannot dominate the aggregate. However, boundedness can also be obtained in other ways, for example by applying a monotone bounded transform such as a logit transform to a better-grounded primary measure such as RMSE or MAE.

Second, it is a percentage-style measure, which stakeholders often ask for (see the discussion of what stakeholders mean by MAPE below), and its modified version with a minimum imposed on the denominator (msMAPE) is numerically stable and can always be computed. Third, it does not depend on a training-set scaling term, so it avoids the problems that MASE and RMSSE have on very short or sparse series, where the in-sample naive benchmark can be close to zero or unrepresentative of the test period. Practitioners dealing with large collections of such series, for example short and sparse retail series, may find MASE and RMSSE difficult to use, while msMAPE can always be computed.

These are real operational concerns. Still, none of them requires sMAPE, because there is a simple family of measures that addresses them without losing the connection to an elicited functional: error measures divided by the in-sample mean of the series [@Kolassa2007Advantages; @Petropoulos2015Forecast]. Dividing MAE by the mean of the training data gives the scaled MAE (sMAE), also known as the MAD/MEAN ratio and often called "weighted MAPE" by practitioners. Doing the same with RMSE gives the scaled RMSE (sRMSE):
$$
  \mathrm{sMAE}=\frac{\mathrm{MAE}}{\bar y}, \quad
  \mathrm{sRMSE}=\frac{\mathrm{RMSE}}{\bar y}, \quad
  \bar y=\frac{1}{T}\sum_{t=1}^T y_t .
$$
sMAE is a close relative of WAPE, discussed in Section \ref{sec-wape}: both divide MAE by the level of the series, and thus both rely on the zero forecast as an implicit benchmark. The only difference is that sMAE calculates the level on the training data rather than on the test set. These measures address the same issues mentioned above that sMAPE addresses:

1. They are percentage-style measures, showing the error relative to the average level of the series, which is close to what stakeholders have in mind when they ask for a percentage error;
2. They can be calculated whenever the in-sample mean is not zero, which only requires one non-zero observation, and they do not rely on in-sample differences, so they work on short and sparse series. On stationary intermittent demand, the mean is also a natural reference level, while the naive forecast behind MASE and RMSSE is a poor benchmark;
3. The denominator is a constant for each series, so the measures are minimised by the same statistics as the underlying ones: the median for sMAE and the mean for sRMSE. In the case of msMAPE, the minimiser is unknown and depends on the arbitrary floor imposed on the denominator;
4. The denominator does not depend on the actual values in the test set, so the measures are neither inflated by small actual values nor biased towards underforecasting.

The main limitation of sMAE and sRMSE is that the in-sample mean is a meaningful scale only when the series is stationary. For example, if sales grow, the mean grows with them, and the error measure will decline over time even if the model does not improve. This is the same issue that WAPE has (Figure \ref{fig:wape-shortcomings}). So, for trending or rapidly growing series, for example in a technology company, RMSSE or a relative measure computed over the test set (such as rRMSE or the FVA discussed in Section \ref{sec-fva}) is more appropriate. In both cases, the measure should be accompanied by a signed measure of bias. This way, the practical attractions of sMAPE are served by measures with a clear interpretation, which leaves the comparison with legacy results as the only remaining reason to report sMAPE.

### If MAPE must be reported, and what stakeholders actually mean by it

If MAPE must be reported, for example due to the preferences of senior business stakeholders, there are some tweaks to consider. One can floor the denominator by setting the minimum of the actual values to 1, which keeps the measure computable but is exactly the kind of ad hoc engineering discussed above. Furthermore, we recommend that it be aggregated using the median rather than the mean (i.e., the median absolute percentage error across time points or series). The median is far less sensitive to the extreme percentages produced by small denominators, so a few near-zero actuals no longer dominate the result. This mitigates the instability but does not remove the other problems of percentage errors, so such a figure should be reported alongside a better-grounded measure, and not be used for model selection or optimisation.

It is also worth clarifying what business stakeholders actually mean when they ask for "MAPE". In our experience, they often have in mind a growth error, $(\hat y_t - y_t)/y_{t_0}$, where $y_{t_0}$ is the actual value at the forecast origin. This stems from planning processes: if the plan assumed 20% growth and the business actually grew 15%, the error is 5 percentage points. Because the denominator is fixed at the origin and the sign is retained, this quantity is essentially a scaled bias (see the discussion of bias above), even though business stakeholders may call it the forecast error, and it avoids the small-denominator problem of MAPE as long as the value at the origin is not near zero. It is a legitimate planning KPI, but it answers a different question than MAPE, and it should be called by a different name. Being signed, it should be aggregated without taking absolute values if bias is the target, and with absolute values if overall accuracy relative to the planning baseline is of interest. Agreeing with stakeholders on which of these is meant can remove the need to report MAPE altogether. And if what they need is simply a percentage showing whether the forecasts are getting better, the forecast value added against an agreed benchmark (Section \ref{sec-fva}) provides one with a clear interpretation.

## Training loss and evaluation target should be explicit {#sec-training-loss}

The same logic extends from evaluation to model estimation. If a model is estimated under a criterion that targets the conditional mean, then evaluating it primarily with RMSE-type measures is coherent. This is one reason why likelihood-based ARIMA and ETS models are naturally associated with mean-oriented evaluation. By contrast, evaluating all methods only with MAE or MASE may inadvertently favour methods that are better at predicting medians, even when the competing models were not designed to do so.

Training and evaluation losses need not be identical, but the forecast produced and the primary evaluation score must be interpreted in relation to the target that matters. For example, a probabilistic model trained with CRPS can provide a predictive distribution from which a quantile is extracted and evaluated with pinball loss. Alternatively, a model can estimate the conditional mean under squared error and, given an explicit distributional assumption, derive a quantile to evaluate with pinball loss. By contrast, if a model directly outputs a conditional-mean forecast, it can still be scored using MAE, but MAE is minimized by the conditional median. Such an evaluation therefore measures absolute-error performance; it should be the primary criterion only if median-oriented performance is what the study or application intends to reward.

This distinction matters when comparing classical statistical models with machine learning methods. Likelihood-based ARIMA and ETS models are often mean-oriented under their model assumptions; L1 loss targets the median, quantile (pinball) loss targets a specified quantile, and the target of a Huber loss depends on its threshold and the conditional distribution. A single score can therefore favour one model because it estimates a different functional, not because it is better for every use. Studies comparing such methods should state the target functional and primary score, and may report complementary scores such as RMSE and MAE to show how rankings change across targets.

Extreme observations require particular care. If they are genuine outcomes relevant to the decision, they are part of the predictive distribution and can materially affect the conditional mean; downweighting them changes the target and should not be justified merely as a way to make a mean forecast more robust. If they are measurement errors or arise from a distinct contamination process, address that issue in the data or model explicitly. Robust losses such as Huber can still be useful for estimation or optimisation, but their use does not by itself establish that the resulting forecast is optimal for a mean-oriented objective. State the reason for the training loss and ensure the primary evaluation reflects the intended target.

# Normalisation is choosing a benchmark {#sec-normalisation}

Scale-dependent measures such as MAE and RMSE are perfectly meaningful when evaluating one series in its own units. In fact, this is often the cleanest situation because the results remain directly interpretable. So, if you don't need a scale-free measure, stick to the scaled, non-normalised measures.
Problems arise when we want to compare errors across series with different units or scales, or when we want to aggregate performance across many series. Then we need to normalise. And already in a single series, if there are strong trends and level shifts, normalisation may be needed both during training and evaluation. A good example would be the bitcoin price that has changed its scale dramatically over the years. Other financial time series have similar properties.

In many machine learning forecasting papers, this step is treated as largely technical, with default preprocessing such as z-score standardisation or related mean-variance scaling applied uniformly across tasks [for example @zhou2021informer; @wu2021autoformer; @nie2023patchtst]. This can work well on many benchmark datasets, in particular the ones used as standard benchmarking suites by many papers from the machine learning community. But it should not be mistaken for a universally valid solution to normalisation in forecasting. In particular, for many financial and other near-unit-root series, the conditional mean is weakly predictable at best and often unstable over time, so the in-sample mean is not a meaningful long-run reference level. Normalising by that mean therefore does not provide a meaningful benchmark for forecast error comparison [@Hewamalage2023Forecast].

To summarise, normalisation is often presented as a technical afterthought, but it is not. Any normalisation divides forecast errors by something, and that "something" acts as a benchmark. Once this is recognised, many apparent disagreements between measures become easier to understand.

This also implies different defaults for different objectives. In academic benchmark studies, the objective is usually broad, method-level comparison across many heterogeneous tasks, so a benchmark-scaled measure with stable cross-series behaviour is desirable. For that purpose, we recommend RMSSE as the primary default and MASE as a useful robustness check. In practitioner settings, by contrast, the objective is usually decision support in a specific business context. There, interpretability, cost alignment, and communication often matter more than benchmark comparability, so scale-dependent measures (e.g., MAE or RMSE in business units) or carefully chosen business-weighted aggregates may be preferable.

## Why there is no universal denominator

Suppose we want to compare two models across many series. A raw MAE of $10$ is large for a low-volume SKU and negligible for a national energy load series. So we divide by a scale term. The crucial question is what that scale term represents.

If we divide by the actual value at each time point, we obtain percentage errors, with the problems discussed above. If we divide by the sum of absolute actuals over the test set, we obtain WAPE. If we divide by the mean absolute first difference in the training set, we obtain MASE [@Hyndman2006Another]. If we divide by the error of an explicit benchmark method, we obtain relative measures such as rMAE/RelMAE [@Hyndman2006Another] or rRMSE/RelRMSE [@Stock2004Combination]. These are not minor algebraic variants. They correspond to different notions of what a "large" error is.

There is therefore no denominator that is appropriate for every series. A good denominator for stationary intermittent demand can be a bad denominator for strongly trended macroeconomic or financial series. A denominator that works well for seasonal retail demand may be a poor choice for event-driven web traffic or for bounded physical processes such as wind power capacity factors. The right way to think about normalisation is not to ask which scaled measure is universally best, but which benchmark makes forecast errors meaningfully comparable for the data-generating features at hand.

Thus, scale-free evaluation is never a property of the numerator alone. It depends just as much on the benchmark in the denominator. Asking "how should I normalise?" is therefore equivalent to asking "relative to what baseline behaviour should this error be judged?"

## An example: WAPE is interpretable because it uses a simple benchmark {#sec-wape}

Weighted absolute percentage error,
$$
  \text{WAPE} = \frac{\sum_t |y_t-\hat{y}_t|}{\sum_t |y_t|},
$$
is often attractive to practitioners because it is easy to communicate. But its interpretability comes from a very particular choice of benchmark. As noted by Hyndman [@Hyndman2025WAPE], WAPE can be read as a relative MAE with a constant-zero forecast in the denominator. That benchmark is sensible only when a zero forecast is a meaningful baseline.

This explains both the strengths and the weaknesses of WAPE. For sparse intermittent series without pronounced trend, a zero baseline may be defensible, and WAPE can work reasonably well. This is one reason why it remains popular in inventory contexts [@Kolassa2007Advantages]. But the same logic also shows why WAPE is a poor universal default. When the series has trend, level changes, or strong seasonality, the denominator changes with the holdout sample in ways that have little to do with forecasting skill. A method can produce comparable absolute errors on two different test windows and still appear better on the later window merely because the series level has drifted upward (Figure \ref{fig:wape-shortcomings}) [@Hyndman2025WAPE].

\begin{figure}[htbp]
\centering
\includegraphics[width=\linewidth]{paper/images/wape_shortcomings.pdf}
\caption{A strongly trended series (top) with a forecast that produces similar MAE and RMSE in an early low-level stretch (red) and a late high-level stretch (blue). The bar chart (bottom) shows that while MAE and RMSE are similar, WAPE more than doubles in the early stretch solely because the denominator (the sum of actuals) is much smaller there.}
\label{fig:wape-shortcomings}
\end{figure}

A close relative of WAPE is the scaled MAE (sMAE), which divides MAE by the mean of the training data rather than of the test set [@Petropoulos2015Forecast] and which practitioners also often call "weighted MAPE". For non-negative data, the in-sample mean is the MAE of the zero forecast on the training data, so sMAE relies on the same zero benchmark as WAPE, but evaluated in-sample, in the same way as MASE evaluates the naive benchmark in-sample. This makes the denominator independent of the specific test window, which is useful when the test set is short, and it means that sMAE is minimised by the median, as MAE is. Its squared-error counterpart, sRMSE, is minimised by the mean. These measures are a much safer percentage-style alternative to MAPE and sMAPE (Section \ref{sec-smape-attractive}). Still, moving the denominator to the training data does not solve the issue with trend: if the level of the series drifts, the in-sample mean drifts with it, and the error measure changes for reasons unrelated to forecasting skill.

The key point is not that WAPE is always wrong. The key point is that its denominator hard-codes a specific baseline, whether or not the user acknowledges it. If zero is not a serious benchmark, the measure is misaligned with the forecasting task.

## MASE and RMSSE make the benchmark explicit

MASE and RMSSE scale by the in-sample performance of a naive benchmark rather than, e.g., by the realised magnitude of the holdout. For a non-seasonal series, MASE uses the mean absolute first difference in the training sample; for a seasonal series, a seasonal analogue can be used [@Hyndman2006Another]. RMSSE applies the same logic in squared-error form.

The key advantage of this design is that the first (seasonal) difference of a series (which equals the error of a naive forecast) is far more likely to be stationary than the level of the series itself. MASE and RMSSE therefore handle many common non-stationary situations more gracefully than measures whose denominator depends on the magnitude of the series. A further benefit is that using the training set for scaling, rather than the test set, reduces sensitivity to short or unrepresentative test windows (see also Section \ref{sec-aggregation}).

That said, these measures also have drawbacks. At first glance they appear interpretable: a value greater than one means the method performs worse out-of-sample than the naive baseline does in-sample on the training set, so we might expect MASE to lie between 0 and 1 for any useful model. In practice, however, forecasters typically predict multi-step output windows whose horizon does not coincide with the single-step naive forecast used in the denominator, so values above one are common and do not indicate poor performance per se.

More fundamentally, the measures are only as meaningful as the naive benchmark in their denominator. If the training and test sets have very different statistical properties, or if a naive forecast is not a reasonable baseline for the domain, the scaled error values lose their intended reference point. For example, when a series has a strong predictable trend, a one-step naive benchmark can be much less informative than in a weakly dependent stationary setting. A related issue appeared in the M5 forecasting competition: some product-level series had near-zero values for most of the training period and then rose sharply in the test period. Because naive forecasts look very accurate on long zero stretches, methods are penalised heavily for missing the subsequent regime change under MASE and RMSSE, giving such series disproportionate influence in the aggregated score.

<!-- TODO: This argument should be strengthened. Hopefully get some input from Rob and Ivan. -->
Regarding the choice between MASE and RMSSE, it is, in essence, the same as the choice between MAE and RMSE: should the target be the median of the predictive distribution or the mean? MASE was originally introduced using absolute errors partly to stay close to MAPE, easing the transition away from percentage errors for practitioners. In practice, however, users willing to move beyond MAPE have generally also been comfortable with squared-error measures.

There are also substantive reasons to prefer RMSSE as the default. First, it is the safe choice in both cases. As discussed in Section \ref{sec-elicitation}, if the predictive distribution is symmetric, the mean and the median coincide and the two measures will recommend similar methods, so nothing is lost by using RMSSE. If it is skewed, the two measures can disagree, and in the majority of applications it is the mean that is needed. Second, most forecasting approaches produce conditional means: ETS and ARIMA estimated via likelihood, as well as machine learning approaches trained with MSE. So, evaluating them with RMSSE measures what they actually produce. Third, the difference matters most on intermittent data. MASE inherits the property of MAE discussed in Section \ref{sec-elicitation}: when more than half of the observations are zero, the zero forecast minimises it. For example, @Svetunkov2024Point shows an intermittent series on which the zero forecast has a lower MAE than the mean (8.85 vs 10.32) but a much higher RMSE (13.76 vs 10.54). A recommendation not to replenish stock for intermittent demand at all is hardly a useful outcome of an evaluation. Finally, if forecasts need to add up across a hierarchy, they need to be means, and RMSSE is consistent with this requirement. This is also one of the reasons why RMSSE was adopted in the M5 competition [@Makridakis2020M5], which dealt with a hierarchy of mostly intermittent retail series, as recommended originally by @Athanasopoulos2023Evaluation.

We therefore recommend RMSSE as the default for broad comparative evaluation (as in many academic settings), with MASE as a useful complement when the median is the intended target. The mean-oriented interpretation requires stating where the root is taken: for short windows, an average of separately computed RMSSE scores need not be minimised in expectation by conditional means (Section \ref{sec-root-aggregation}). Note that the lower sensitivity of MASE to large errors is not by itself a reason to prefer it: as argued in Section \ref{sec-training-loss}, if the extreme observations are genuine outcomes, downweighting them changes the target rather than making the evaluation more robust.

In sum, when the goal is to compare methods across many forecasting problems, which is the typical setup in academic research, RMSSE should be the default. Any departure from this default should be accompanied by a clear explanation of why a different measure better suits the evaluation context.

## Forecast value added: make the benchmark the headline {#sec-fva}

If every scale-free measure embeds a benchmark, a natural question is: why not make the benchmark explicit and report the improvement over it directly? This is the idea behind the "Forecast Value Added" (FVA) framework, which has become popular among practitioners [@Gilliland2010Business; @Gilliland2023Twenty]. Instead of trying to find a threshold for an error measure (is an RMSSE of 1.14 good or bad?), we measure by how much our forecasting approach improves upon a benchmark:
$$
  \mathrm{FVA} = 1 - \frac{\mathrm{Error}_a}{\mathrm{Error}_b},
$$
where $\mathrm{Error}_a$ is an error measure (e.g., RMSE) of the approach under consideration and $\mathrm{Error}_b$ is the same measure for the benchmark. With RMSE, FVA is simply one minus rRMSE: an rRMSE of 0.85 corresponds to an FVA of 15%, meaning that our approach reduces the RMSE of the benchmark by 15%. A negative value means that the approach does worse than the benchmark, destroying rather than adding value. The same quantity is known as a "skill score" in meteorology and energy forecasting [@Murphy1988Skill]. Note, however, that the classical skill score is formulated in terms of MSE rather than RMSE [@Murphy1988Skill], so an FVA of 15% in terms of RMSE corresponds to a skill score of roughly 28% in terms of MSE ($1-0.85^2$). The two rank methods identically, but the numbers are not interchangeable, so it should always be stated which of them is reported.

The appeal of FVA is twofold. First, it gives stakeholders the percentage number they typically ask for, but with a clear meaning: by how many percent the error decreases in comparison with an agreed alternative. Second, the benchmark does not need to be a naive forecast. It can be a global average, a simple moving average, the method currently used in the company, or the previous step of the forecasting process. The latter is where FVA is especially useful in practice [@Gilliland2023Twenty]: by comparing the statistical forecast with the naive one, the judgementally adjusted forecast with the statistical one, and the final consensus forecast with the adjusted one, we can see which steps of the process improve the forecasts and which ones only add effort, or even make the forecasts worse.

Having said that, FVA inherits the limitations of relative measures [@Svetunkov2024Point]:

1. It breaks down when the error of the benchmark is close to zero, because the ratio then goes to infinity. In practice, this happens more often than desired, for example on intermittent series with long stretches of zeroes in the test set, where the naive forecast can be almost perfect;
2. A change of FVA over time can be caused either by a change in the performance of our approach or by a change in the performance of the benchmark. It is not possible to tell the difference between the two by looking at FVA alone, so the errors of both should be tracked alongside it;
3. FVA is only as meaningful as its benchmark. Beating a naive forecast on a strongly seasonal series is not an achievement, and an FVA of 30% against a weak benchmark can be less impressive than 5% against a strong one. So, the benchmark should be agreed in advance and kept fixed.

The first issue depends on how FVA is aggregated across series. If FVA is calculated for each series separately and then averaged, the mean will be dominated by the few series on which the benchmark happened to be very accurate. In this case, we recommend reporting both the mean and the median: the latter is robust to such outliers and is always calculable, while the comparison of the two tells us something about the tail of the distribution. The geometric mean, advocated for relative measures by @Davydenko2013Measuring, is another option. Still, it becomes equal to zero or infinity as soon as one of the methods produces a perfect forecast on a single series, and if the distribution of the log-ratios is symmetric, it will be close to the median anyway. So, we argue that using the geometric mean for aggregation of FVA is not necessary.

In practice, FVA is a natural headline number for the communication with stakeholders and for deciding whether something in the forecasting process needs to change, while the scaled measures discussed above remain the working tool of the modellers.

<!-- ## Trend, seasonality, intermittency, and boundedness require different defaults

Thus, while dividing by in-sample (seasonal) naive as in MASE and RMSSE is a reasonable default, normalisation should ideally start from the data characteristics.

For one series in one operational setting, scale-dependent measures may be best because they remain interpretable in the original units. For collections of series with similar scale and direct business comparability, an aggregate scale-dependent measure may also be acceptable if high-volume series are intentionally meant to matter more.

Where cross-series comparison is required, RMSSE is often the strongest primary default, with MASE as a complementary sensitivity check. For intermittent demand, percentage-type measures are especially dangerous because zeros and small values dominate the denominator; WAPE may be acceptable in some stationary sparse settings, but MAE-type measures can also be problematic because they elicit the median, which is often zero. For trending or level-shifting series, any measure whose denominator depends directly on the magnitude of the test set should be treated with caution. For seasonal series, the benchmark should usually be seasonal as well.

 -->

# Aggregation across series is a value judgement {#sec-aggregation}

Once an error has been computed per forecast or per series, a final question remains: how should these quantities be summarised?

In forecasting, there are typically three dimensions along which test-set errors are averaged: the horizon, the forecast origin, and the series (see Figure \ref{fig:3d_of_eval}). Any or all of these dimensions can collapse to a single value. The horizon can be one-step-ahead, the origin can be fixed, and the evaluation can concern a single series. This is one key reason why MASE and RMSSE derive their scaling quantity from the training set: when the test set is small along any of these dimensions, a denominator estimated from training data provides a more stable reference. However, when each dimension covers enough observations, one can and arguably should compute the benchmark error over the test set instead, to mitigate possible problems of distributional differences between training and test sets. Thus, in effect, this means using rMAE or rRMSE with a (seasonal) naive forecast as the explicit benchmark. Reported as one minus this ratio, this is the forecast value added discussed in Section \ref{sec-fva}.

A related principle is that aggregation should only be performed over comparable quantities. If series are not on the same scale, the right approach is to compute a scale-free measure such as RMSSE for each series individually and only then average across series. This concern applies even within a single series: for series whose level shifts dramatically over time, such as asset prices or other near-unit-root financial series, scale can change so drastically that evaluating different regimes separately may be appropriate.

This points to a general tension between aggregating for stability and scaling for comparability. Dividing errors by a scale term before aggregating (as MAPE does) disentangles scale effects across series but inherits all the pathologies of percentage errors discussed earlier. Aggregating first and dividing afterwards (as WAPE does globally) borrows stability from a large pooled sample but conflates scale differences. The preferred approach is to first bring errors to a comparable scale (for example by computing RMSSE per series) and only then aggregate, so that the quantities being averaged already share a common basis.

Some more considerations for the three dimensions:

**Horizon.** It is common to produce a multi-step output window: for an hourly series, forecasts for the next 24 hours yield 24 individual errors. Current practice typically averages these into a single metric, even though forecasts at different horizons have different statistical properties. Forecast uncertainty generally grows with the horizon and can also vary systematically (seasonally) within the prediction window. For instance, daytime hours may be inherently less predictable than night-time hours, and a two-week-ahead forecast carries more uncertainty than a one-day-ahead forecast. Averaging over all horizons therefore obscures horizon-specific behaviour. Reporting error measures separately for each horizon used to be standard practice (for example in the evaluation of the M3 competition [@Makridakis2000M3]), and doing so remains informative whenever horizon-specific performance is relevant to the decision problem.

**Origin.** The forecast origin is the time point from which the forecast is issued. In competition settings where the test set is entirely withheld, a single fixed origin is standard. In applied settings, a rolling-origin scheme where the model is re-evaluated at each successive origin is usually more realistic and yields a better estimate of operational performance. Care is required to avoid data leakage in such schemes.

**Series.** When aggregating over many series, the scale and weighting questions discussed in the following subsections become central. Each series contributes one or more error values, and the aggregation rule determines whether all series are treated as equally important forecasting problems or whether some are given greater influence through their scale or through explicit weights.

\begin{figure}[htbp]
\centering
\includegraphics[width=0.5\linewidth]{paper/images/drawing_3d_of_eval.pdf}
\caption{Schematic view of the three dimensions along which point forecast errors can be aggregated: forecast horizon, forecast origin, and series. Depending on the application, one or more dimensions may collapse to a single value, but in large-scale evaluations all three typically matter and the final summary depends on how errors are combined across them.}
\label{fig:3d_of_eval}
\end{figure}

In summary, aggregation is not merely descriptive. It determines which failures count, which successes dominate, and which kinds of methods are favoured. In that sense it plays the same role as the decathlon point system: it defines what kind of all-round performance is rewarded.

## The position of the square root matters {#sec-root-aggregation}

The mean-optimality statement for squared error requires care when RMSE is averaged over short evaluation windows. Taking a square root after all squared errors have been pooled preserves their ranking on the realised data. Taking a separate square root within each series or origin, and then averaging, defines a different criterion. This distinction connects elicitation (Section \ref{sec-elicitation}) with aggregation: the expected score of the complete evaluation rule determines its optimal forecast [@gneiting2011making].

For a forecast vector $a=(a_1,\ldots,a_H)$ issued before a random future window $Y=(Y_1,\ldots,Y_H)$, distinguish
$$
R_{\mathrm{pooled}}(a)=\sqrt{\mathbb{E}\left[H^{-1}\sum_{h=1}^H(Y_h-a_h)^2\right]}
\quad\text{from}\quad
R_{\mathrm{window}}(a)=\mathbb{E}\left[\sqrt{H^{-1}\sum_{h=1}^H(Y_h-a_h)^2}\right].
$$
The former is minimised by the componentwise conditional mean. The latter is proportional to expected Euclidean distance and is minimised by a geometric median of the joint future-window distribution, which need not be that mean. At $H=1$, window RMSE is exactly absolute error, so averaging one-step RMSE scores elicits a median. A fixed positive training-data scale does not change this conclusion: the same distinction applies to RMSSE when a separate root is taken for each window.

A small intermittent-demand example makes the difference explicit. Suppose the future observations are independent Bernoulli variables with probability $p=0.2$, and a constant forecast $a$ is issued for all $H$ steps. The conditional mean is 0.2 and the median is zero. At $H=1$, the zero forecast has expected window RMSE 0.20, below the mean forecast's 0.32. In contrast, their expected squared errors are 0.20 and 0.16, respectively. Neither calculation contains estimation error or an uncertain denominator.

For longer windows the expected score can be computed by summing over the binomial count of positive demand observations (Appendix \ref{app-root-aggregation}).

| Window length $H$ | Optimal constant for expected window RMSE | Expected window RMSE at optimum | Expected window RMSE at mean forecast |
|---:|---:|---:|---:|
| 1 | 0.000000 | 0.200000 | 0.320000 |
| 4 | 0.000000 | 0.337182 | 0.369224 |
| 8 | 0.133547 | 0.380183 | 0.384418 |
| 32 | 0.189660 | 0.396239 | 0.396371 |
| 256 | 0.198816 | 0.399557 | 0.399559 |

These are finite sums over all possible counts, evaluated numerically, rather than Monte Carlo estimates. In this independent example the optimum approaches the mean as the window grows. Long windows can therefore make the distinction small, but adding more independently scored short windows does not remove it: their average estimates $R_{\mathrm{window}}$, not $R_{\mathrm{pooled}}$.

This does not invalidate RMSE or RMSSE as descriptive measures, nor imply that any particular benchmark has a practically important distortion. It requires an explicit order of operations. If mean elicitation is essential, aggregate squared errors with positive weights and scales fixed from information available when the forecasts are issued, then take one root for presentation. State the axes over which errors are pooled. If a mean of per-series or per-origin RMSSE values is preferred, report that choice and avoid claiming that conditional means necessarily minimise its expected finite-window score. The numerical example and its full table are reproducible with `python scripts/rmse_aggregation.py` using NumPy and SciPy.

## Equal weighting and value weighting answer different questions

Suppose we evaluate a method on a large panel of series. If we compute a scale-free measure per series and then take a simple average or median, every series receives equal weight. This is appropriate when every series is regarded as one forecasting problem of equal scientific importance.

If instead we compute an aggregate error over all observations first, as in a global WAPE or MAE, then high-volume series dominate. This is appropriate when business value is roughly proportional to scale: a ten percent error on a large-revenue series may indeed matter more than a ten percent error on a tiny series. In that case, the weighting is intentional, not a flaw.

In industry, reporting both views is often valuable: together they show whether a forecasting algorithm or its adjustments improve performance broadly across series or mainly on the larger-valued ones.

Neither approach is universally correct. They answer different questions. Scale-free per-series aggregation asks whether the method performs well across forecasting problems. Global aggregation in original units asks whether the method performs well where the volume is largest. In practice, many organisations want something between these extremes: not complete equality across series, but also not a metric in which one giant series overwhelms thousands of smaller yet still relevant ones.

## Evaluation across many tasks: competition leaderboards

The M4 competition [@makridakis2018m4] is a milestone in large-scale forecasting evaluation, bringing together 100,000 time series across six frequency groups (yearly, quarterly, monthly, weekly, daily, and hourly) and multiple application domains. Its primary metric was sMAPE, supplemented by an overall weighted average (OWA) that combined sMAPE and MASE in equal parts relative to a naive seasonal benchmark. Regrettably, this design embedded the limitations of sMAPE discussed in Section \ref{sec-probabilistic} directly into the competition's headline score, and it was influential enough that sMAPE remains in circulation partly for the purpose of legacy comparisons with M4 results. At the same time, the competition validated important substantive findings: machine learning methods could perform well, global modelling could perform well, simple methods remained competitive, and no single method dominated uniformly across all frequencies and domains.
Still, it had the classical setup where each time series was seen as a separate task. To accommodate the realities of global models that train across many series, recent benchmark datasets add another layer to the aggregation problem. In this setting, evaluation is often organised around tasks or datasets rather than around individual series alone. For example, a smart-meter dataset may define one task and a retail dataset another. Yet even in these broader settings there is still strong pressure to produce an easily communicable conclusion, ideally a single number that summarises the overall performance of a method to be able to claim a general best method for "forecasting" as a whole. But that single number is the output of several design decisions.

Two prominent recent examples are GIFT-Eval [@aksu2024gifteval] and fev-bench [@shchur2025fevbench], both designed as broad academic benchmarks for comparing methods across many heterogeneous forecasting tasks. Let's first look at GIFT-Eval as it has seen widespread adoption in the machine learning forecasting community. Its public leaderboard first computes MASE at the series level, then takes the median MASE within each task (that is, within each dataset-frequency split), then normalises each task score by the corresponding score of a seasonal naive baseline, and finally aggregates the normalised task scores using a geometric mean across tasks. In compact form, if $M_j$ is the median MASE for task $j$ and $M^{(snaive)}_j$ is the seasonal-naive counterpart, the overall score is
$$
\left(\prod_{j=1}^{J} \frac{M_j}{M^{(snaive)}_j}\right)^{1/J}.
$$

This design rewards methods that are broadly reliable and penalises those that fail badly on a subset of tasks. That may be exactly the intended objective, but it also means that the final ranking depends strongly on how tasks are defined and weighted.

GIFT-Eval illustrates how consequential the task definition itself can be. For example, the M4 yearly dataset, which contains nearly 23,000 series drawn from many different application domains, enters as a single task; the same is true of the other M4 frequency subsets, such as quarterly, monthly, and weekly. By contrast, some other tasks consist of only a single time series. For instance, the flow of the Saugeen River in Ontario appears as three separate tasks because it is represented at daily, weekly, and monthly frequencies. Giving each task equal weight can therefore give this one underlying series represented at three frequencies more influence than a much larger collection of economically important series. This is not an error in arithmetic; it is a value judgement embedded in the evaluation design.

There is also a methodological issue to check when tasks at different frequencies are derived from the same underlying observations. These tasks are strongly dependent, not independent replications, and temporal aggregation can create leakage if forecast origins and train-test boundaries are not aligned. For example, a weekly or monthly aggregate that straddles a cutoff may contain observations that would not yet have been available when issuing a higher-frequency forecast. To prevent this, define cutoffs and forecast origins on the underlying time axis, ensure every aggregate used as an input contains only observations available at that origin, and construct aggregates separately within each training/evaluation split. Even with leakage ruled out, treat scores from related frequencies as correlated evidence: group or identify related tasks, report their results separately, and avoid interpreting them as independent confirmations or allowing them to receive repeated weight without justification. This is a risk to audit in the benchmark protocol, not evidence by itself that leakage occurred in this example.

The fev-bench work [@shchur2025fevbench] addresses some of these concerns and is a further step forward towards a meaningful and well-rounded evaluation suite, though it still has some drawbacks. Rather than a single geometric mean of normalised MASE scores, it provides two aggregate summaries: an average win rate and a skill score. The average win rate counts how often a given method outperforms each other method across tasks; it is in effect equivalent to average rank in the sense that only the direction of the comparison matters, not the magnitude of the difference. This makes the aggregate robust to scale, but it also means that a method which narrowly beats many competitors on some tasks and loses badly on others can score as well as one that wins more broadly. Also, in such settings we can often observe a problem that we call "rank stealing", where very similar methods by chance beat each other or don't, so that both end up with lower rankings than if only one of them had entered the competition.
Also, rankings are relative to the methods included in the comparison: as new methods are added to the leaderboard, the win rates of all other methods change.
The second score used by fev-bench is a skill score of the FVA form discussed in Section \ref{sec-fva}, which is MASE-based, clips task-level scores to avoid outsized influence from any single task, and uses a geometric mean for final aggregation, broadly parallel to GIFT-Eval's last step. This score is a good way of evaluating, with the only caveats being that, as discussed before, RMSSE is usually preferable over MASE, and that clipping task-level scores and using a geometric mean are design choices to favour models that broadly perform well over specialist models that only perform well on certain tasks.
One practical improvement in fev-bench is that tasks appear to be defined more carefully. However, the fundamental tension persists: Should the entire M5 dataset constitute only three tasks when other tasks still consist of a single time series? Task boundaries remain a value judgement, and a benchmark claiming to represent "time series forecasting" broadly still depends on which domains and frequencies its designers chose to include.

The lesson is the same as in the decathlon analogy from the introduction. Once we aggregate across heterogeneous tasks, we are no longer asking only "which method forecasts best?" We are asking "which method forecasts best under this specific weighting of failures, scales, and domains?" Leaderboards are useful, but their scoring rules should be interpreted as part of the benchmark, not as neutral facts.

## What should count more in practice?

For practical forecast evaluation in real-world settings, the weighting scheme should be chosen deliberately and explained in business terms.

If all series are equally important, use scale-free per-series measures and aggregate them with a mean or median. If larger series matter more because they drive revenue, inventory cost, or service levels, use explicit weights that reflect those stakes. If some strategic series are disproportionately important, assign those weights directly rather than hoping that an off-the-shelf metric will encode the priority by accident. And if robustness matters, report sensitivity to several aggregation choices.

This is especially important when communicating results between technical and non-technical audiences. A scientist may prefer equal weighting because it is methodologically clean. A business stakeholder may prefer value weighting because it aligns with cost. Both positions are reasonable. Problems arise only when the weighting is implicit and the resulting single number is treated as if it carried an objective meaning independent of those priorities.

## Are the differences significant? {#sec-significance}

Once the error measures have been aggregated, it is common to see a table in which the best method is marked in bold, even if it outperforms the second best only in the third decimal place. Should we conclude that it is the best? Not necessarily. Any evaluation is done on a sample of series, origins, and horizons, and the performance of methods will inevitably change if we apply them to a different sample. So, very small differences might be due to chance, and before declaring a winner, it makes sense to check whether the differences between methods are statistically significant. Parametric tests comparing the means of error measures (such as the F- and t-tests) are sensitive to extreme values, which are not uncommon in forecast evaluation. The right tail of the distribution of error measures is typically not restricted by anything, so a handful of extreme cases can dominate both the means and their variances, distorting the results of the tests. A more robust alternative is the Nemenyi or MCB (multiple comparisons with the best) test [@Koning2005M3; @Demsar2006Statistical; @Kourentzes2012Statistical]. It ranks the methods for each series, calculates their mean ranks, and constructs confidence bounds around them. If the bounds of two methods intersect, their performance is not different on the selected significance level. Otherwise, the method with the lower mean rank significantly outperforms the other one. The test is readily available, for example, via the `nemenyi()` function from the `tsutils` package in R [@Kourentzes2023tsutils] and the `rmcb()` function from the `greybox` package in R and Python [@Svetunkov2026greybox]. So, we expect academic papers that claim superiority of a method to report such a test, showing whether the differences are significant on the selected significance level (which ideally should be chosen prior to the test).

Having said that, the test should complement the error measures, not substitute them. It works with ranks rather than with the original values, so it neglects the distances between them: a method with an RMSSE of 0.10 is ranked above the one with 0.11 in exactly the same way as above the one with 100. In this respect, it shares the limitation of the win rates discussed in Section \ref{sec-aggregation}. Furthermore, like any other statistical test, it becomes more powerful with the increase of the sample size. Because the null hypothesis that methods perform equally is in reality almost always wrong, on a sufficiently large dataset even negligible differences will become significant, while on a small one, practically important differences might not be detected. So, the significance should be interpreted together with the size of the differences and not as a substitute for it.

## Recommendations for summarising performance

<!-- TODO: polish the following. -->
\CBtodo{Example visible comment in draft PDF: tighten wording of the industry recommendations and verify consistency with the conclusion.}

The first recommendation is that different processes need to be followed in academia and in industry.

Here, forecast design should start by understanding the process that will use the forecast. That process determines what is being forecast, at what horizons and levels of aggregation or granularity, and whether users need a mean, one or more quantiles, or a full predictive distribution. If the downstream use is unclear, forecasters should discuss it with users and use domain knowledge to make an explicit, revisable assumption rather than defaulting automatically to a single point forecast. Quantiles are themselves point forecasts, each suited to a different loss [@gneiting2011quantiles]; when several decisions may need to be supported, multiple quantiles or an approximation to the full predictive distribution can preserve information that one summary would discard.

Thus, in industry settings where we have a single task to focus on and an (at least partly) known downstream decision, our recommendations are to make all assumptions explicit, for example for the weighting scheme "equal weight per series", "equal weight per task", and "weight proportional to revenue" are all defensible choices, but they describe different objectives. Then, you can start with RMSSE if it fits the downstream decision, or if all your test periods are long, rRMSE is a good alternative. To communicate the results and to decide whether the forecasting process needs to change, report the forecast value added against an agreed benchmark, such as the method currently in use or a (seasonal) naive forecast, together with the errors of the benchmark itself (Section \ref{sec-fva}).

In academic benchmarking there may be no specific users to consult, and it is neither possible nor necessary to claim performance for every downstream decision. Instead, benchmark designers should define the benchmark's intended scope and use domain knowledge and evidence from the relevant literature to select plausible forecast targets, horizons, and levels of aggregation. If no single target is clearly justified, evaluate multiple plausible targets, such as the mean and relevant quantiles, using scoring rules aligned with each target; report the resulting sensitivity rather than collapsing it into a claim of universal performance. For broad point-forecast comparisons, our recommendations are as follows:

- For mean-oriented comparisons, use RMSSE as the primary default (instead of MASE), while treating it as a comparative rather than directly interpretable quantity. Report MASE as a complementary, median-oriented result when that target is relevant.
- Report task-level results rather than only an overall leaderboard score.
- Summarize performance across tasks with complementary measures. For example, pairwise win rates show how broadly a method outperforms alternatives, while a baseline-relative skill score shows the magnitude of its gains. fev-bench illustrates this approach with an average win rate and a clipped, MASE-based skill score.
- State how tasks and scores are weighted and aggregated. Since complementary measures can rank methods differently, accompany any grand average with breakdowns by frequency, data characteristics, and application domain.
- When claiming that one method outperforms others, report a statistical test of the differences, such as the Nemenyi/MCB test, at a stated significance level, and interpret the result together with the size of the differences (Section \ref{sec-significance}).



# Conclusion

Point forecast evaluation is often made unnecessarily confusing because three different design choices are mixed together. The first is elicitation: which summary of the predictive distribution should the point forecast represent? The second is normalisation: relative to which benchmark should errors be judged? The third is aggregation: which series or tasks should carry more weight in the final summary. In practice, these choices should follow from the forecast's downstream use and be clarified with users; in academic benchmarks, where there may be no users to consult, designers should define the benchmark's scope and justify targets and evaluation choices using domain knowledge and relevant evidence. Where several plausible targets remain, sensitivity across them should be reported rather than implying that one choice serves every purpose.

Once these questions are separated, many long-running debates become more tractable. RMSE and MAE are not rivals in search of one winner; they target different functionals. WAPE is not a universally interpretable percentage measure; it is a relative error built around a zero benchmark and therefore appropriate only in some settings. MASE and RMSSE are strong defaults for comparative work because they make the benchmark explicit and are less sensitive to holdout scale, but they still depend on the relevance of the naive baseline, and RMSSE is usually preferred over MASE. And any summary across many series is inevitably a statement about what matters more.

Our recommendations are therefore straightforward. In practice, start by understanding the forecast's downstream use, then choose the target, granularity, and uncertainty representation accordingly. If that use is unclear, clarify it with users; where uncertainty remains, use domain knowledge to make assumptions explicit and consider multiple quantiles or a predictive distribution rather than implying that a single point forecast serves every purpose. In academic benchmarks, define the intended scope and justify target choices from domain knowledge and relevant evidence; when several targets are plausible, report sensitivity across them and limit claims accordingly. Avoid MAPE and do not treat sMAPE as a general repair. When normalisation is needed, choose a benchmark that is defensible for the data characteristics of the series. For mean-oriented academic point-forecast comparisons, use RMSSE as the primary default and report MASE as a complementary median-oriented result when relevant; for practitioner use, prioritise measures and aggregation schemes that align with business cost and interpretability. When aggregating across many series, state clearly whether the goal is equality across forecasting problems, weighting by business value, or something in between.

The broader implication is that evaluation design is itself part of forecasting methodology. A leaderboard, a benchmark table, or a business KPI is only as meaningful as the choices that produced it. If forecasting is to improve in both academia and practice, those choices need to become explicit, technically defensible, and aligned with the decision context they are meant to serve.

# Appendix

<!-- TODO: Check the appendix, especially Section2, if it is correct. -->

## Definitions of Error Measures Used in This Paper {#app-measures}

We use the following notation. Let $y_t$ be the observed value, $\hat y_t$ the point forecast, and $e_t=y_t-\hat y_t$ the forecast error on test observations $t=1,\dots,n$. Let a benchmark forecast be $\hat y_t^{(b)}$ with benchmark error $e_t^{(b)}=y_t-\hat y_t^{(b)}$. Let the training sample have size $T$.

### Scale-dependent measures

Mean squared error (MSE):
$$
  \mathrm{MSE}=\frac{1}{n}\sum_{t=1}^n e_t^2.
$$

Root mean squared error (RMSE):
$$
  \mathrm{RMSE}=\sqrt{\frac{1}{n}\sum_{t=1}^n e_t^2}.
$$

Mean absolute error (MAE):
$$
  \mathrm{MAE}=\frac{1}{n}\sum_{t=1}^n |e_t|.
$$

Root mean squared logarithmic error (RMSLE), defined only when all $y_t>0$ and $\hat y_t>0$, with the exponent bringing it back from the logarithmic scale:
$$
  \mathrm{RMSLE}=\exp\left(\sqrt{\frac{1}{n}\sum_{t=1}^n \left(\log y_t-\log \hat y_t\right)^2}\right).
$$

### Percentage and ratio-based measures

Mean absolute percentage error (MAPE), defined only when all $y_t\neq 0$:
$$
  \mathrm{MAPE}=\frac{100}{n}\sum_{t=1}^n \left|\frac{e_t}{y_t}\right|.
$$

Symmetric MAPE (sMAPE), common form on a $0$--$200$ scale:
$$
  \mathrm{sMAPE}=\frac{200}{n}\sum_{t=1}^n \frac{|e_t|}{|y_t|+|\hat y_t|}.
$$

Weighted absolute percentage error (WAPE):
$$
  \mathrm{WAPE}=\frac{\sum_{t=1}^n |e_t|}{\sum_{t=1}^n |y_t|}.
$$

Scaled MAE (sMAE, also known as the MAD/MEAN ratio or "weighted MAPE"), using the in-sample mean:
$$
  \mathrm{sMAE}=\frac{\frac{1}{n}\sum_{t=1}^n |e_t|}{\frac{1}{T}\sum_{t=1}^T y_t}.
$$

Scaled RMSE (sRMSE), using the in-sample mean:
$$
  \mathrm{sRMSE}=\frac{\sqrt{\frac{1}{n}\sum_{t=1}^n e_t^2}}{\frac{1}{T}\sum_{t=1}^T y_t}.
$$

### Scaled measures using training-data benchmarks

Mean absolute scaled error (MASE), non-seasonal form:
$$
  \mathrm{MASE}=\frac{\frac{1}{n}\sum_{t=1}^n |e_t|}{\frac{1}{T-1}\sum_{t=2}^T |y_t-y_{t-1}|}.
$$

Root mean squared scaled error (RMSSE), non-seasonal form:
$$
  \mathrm{RMSSE}=\sqrt{\frac{\frac{1}{n}\sum_{t=1}^n e_t^2}{\frac{1}{T-1}\sum_{t=2}^T (y_t-y_{t-1})^2}}.
$$

For seasonal period $m$, the usual seasonal variants replace first differences by seasonal differences, i.e., $y_t-y_{t-m}$, and use $t=m+1,\dots,T$ in the denominator.

### Relative measures against an explicit benchmark

Relative MAE:
$$
  \mathrm{rMAE}=\frac{\mathrm{MAE}(\hat y)}{\mathrm{MAE}(\hat y^{(b)})}=
  \frac{\frac{1}{n}\sum_{t=1}^n |e_t|}{\frac{1}{n}\sum_{t=1}^n |e_t^{(b)}|}.
$$

Relative RMSE:
$$
  \mathrm{rRMSE}=\frac{\mathrm{RMSE}(\hat y)}{\mathrm{RMSE}(\hat y^{(b)})}=
  \frac{\sqrt{\frac{1}{n}\sum_{t=1}^n e_t^2}}{\sqrt{\frac{1}{n}\sum_{t=1}^n (e_t^{(b)})^2}}.
$$

Interpretation: values below $1$ indicate improvement over the benchmark, and values above $1$ indicate deterioration.

Forecast value added (FVA), shown here for RMSE (any other error measure, e.g., RMSSE averaged across series, can be used instead):
$$
  \mathrm{FVA}=1-\frac{\mathrm{RMSE}(\hat y)}{\mathrm{RMSE}(\hat y^{(b)})}=
  1-\frac{\sqrt{\frac{1}{n}\sum_{t=1}^n e_t^2}}{\sqrt{\frac{1}{n}\sum_{t=1}^n (e_t^{(b)})^2}}.
$$

Interpretation: the proportion by which the error of the benchmark is reduced; positive values indicate improvement, and negative values indicate deterioration. With RMSE, $\mathrm{FVA}=1-\mathrm{rRMSE}$. The MSE-based skill score used in meteorology and energy forecasting [@Murphy1988Skill] is $1-\mathrm{rRMSE}^2$.

## Why Squared Error Elicits the Mean and Absolute Error Elicits the Median {#app-elicitation}

Let $Y$ denote the predictive random variable for the target at a fixed horizon, and let $a \in \mathbb{R}$ be a candidate point forecast. Define the expected loss
$$
  R(a) = \mathbb{E}[L(a,Y)].
$$
We seek $a^* \in \arg\min_a R(a)$.

### Squared Error Implies the Mean

For $L(a,y)=(a-y)^2$,
$$
  R(a)=\mathbb{E}[(a-Y)^2]=a^2-2a\mathbb{E}[Y]+\mathbb{E}[Y^2].
$$
Assuming $\mathbb{E}[Y^2]<\infty$, differentiate with respect to $a$:
$$
  R'(a)=2a-2\mathbb{E}[Y].
$$
Setting $R'(a)=0$ gives
$$
  a^*=\mathbb{E}[Y].
$$
Since $R''(a)=2>0$, this is the unique global minimiser. Therefore, squared-error-optimal point forecasts are conditional means.

### Absolute Error Implies the Median

For $L(a,y)=|a-y|$,
$$
  R(a)=\mathbb{E}[|Y-a|].
$$
Write $F(a)=\mathbb{P}(Y\le a)$ for the predictive CDF. A standard subgradient of $R$ is
$$
  \partial R(a)=\big[\,\mathbb{P}(Y<a)-\mathbb{P}(Y>a),\;\mathbb{P}(Y\le a)-\mathbb{P}(Y\ge a)\,\big].
$$
A necessary and sufficient optimality condition for convex $R$ is $0\in\partial R(a)$, i.e.
$$
  \mathbb{P}(Y\le a)\ge \tfrac12 \quad\text{and}\quad \mathbb{P}(Y\ge a)\ge \tfrac12.
$$
These are exactly the defining inequalities of a median. Equivalently, if $F$ is continuous and strictly increasing at the optimum, the first-order condition becomes
$$
  F(a^*)=\tfrac12.
$$
Hence, absolute-error-optimal point forecasts are medians (not necessarily unique when $Y$ has atoms).

## Exact finite-window RMSE calculation {#app-root-aggregation}

Let $Y_1,\ldots,Y_H$ be independent Bernoulli($p$) outcomes, and let $K=\sum_hY_h$. For a constant forecast $a\in[0,1]$, $K\sim\operatorname{Binomial}(H,p)$ and
$$
R_H(a)=\sum_{k=0}^H {H\choose k}p^k(1-p)^{H-k}
\sqrt{(1-k/H)a^2+(k/H)(1-a)^2}.
$$
This function is convex because each term is a nonnegative multiple of a Euclidean norm. Forecasts outside $[0,1]$ can be projected into that interval without increasing any squared error. The script checks the one-sided derivatives at both endpoints, then solves $R'_H(a)=0$ in the interior when necessary, where
$$
R'_H(a)=\sum_{k=0}^H {H\choose k}p^k(1-p)^{H-k}
\frac{a-k/H}{\sqrt{(1-k/H)a^2+(k/H)(1-a)^2}}.
$$
The endpoint derivatives are obtained by one-sided limits. The reported constant optimum also minimises the unrestricted forecast-vector risk: the outcome distribution is invariant under permutations, and averaging any forecast vector over those permutations gives a constant vector with no larger risk by convexity.

The companion script checks the binomial reduction against direct enumeration of all binary windows at $H=1,2,4$, verifies the analytical one-step result and the reflection identity $a^*_H(1-p)=1-a^*_H(p)$ for the reported probabilities, and compares each optimum with an independent dense grid. The supplied CSV includes both $p=0.2$ and $p=0.8$ at nine window lengths. These checks concern the worked example only and do not estimate the size of the effect in a real forecasting benchmark.

# References
