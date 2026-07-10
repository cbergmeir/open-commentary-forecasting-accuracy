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

Let us ask a question: "Who is the world's best athlete?" Though the question is simple, the answer is highly subjective. Which categories should define "best," and how much weight should each receive? Is Michael Jordan "better" than Lionel Messi because he dominated one sport and also played professionally in another? Is Michael Phelps better because he achieved 28 Olympic medals, more than anyone else? Lionel Messi has 1 Olympic medal. The question remains open-ended because everyone brings a different set of criteria and priorities.

To make it more concrete, let's consider the decathlon. It combines ten disciplines, such as sprinting, long-distance running, shot put, and javelin. Athletes score points in each event over two days, and the highest total wins. While more tangible, even here, value judgements are unavoidable. While each discipline has a clear local criterion (for example, farther javelin throws are better), aggregating across disciplines requires a mapping to a common scale. The decathlon resolves this through a point system that encodes explicit design choices about baselines, curvature, and aggregation.

The same logic applies to forecasting: "Which is the best forecasting method?" Is a question easy to be asked and difficult to be answered. Once we ask which method is "best" across horizons, series, datasets, or business units, the answer depends not only on model quality but also on the scoring system used to compare methods.

Rankings appear quickly in both academic studies and practitioner reports, as they provide a single summary of performance. Yet that summary is never neutral. Every ranking reflects a set of evaluation choices about what is measured, how it is scaled, and how results are aggregated.

This matters for many reasons, one being that practice and academia often have different objectives. In production, stakeholders frequently want a stable and interpretable key performance indicator, often ideally one percentage number that can be tracked over time. In academia, the goal is usually to compare methods as fairly and reproducibly as possible, even if the resulting measure is less intuitive for non-specialists. Neither objective is illegitimate, but they do not lead to the same evaluation design. 

Thus, while we want to argue that there is no universal one-fits-all forecast evaluation pipeline, there are evaluation methodologies that have been shown decades ago to be flawed and their use is still widespread. We aim to reflect as best as possible a consensus between many leading researchers in the field of forecasting about what evaluations are best practice in different scenarios, and which ones should be avoided. We'll also reflect in this paper where we as a group of authors disagree on certain standpoints, so that the reader can get a picture of which practices to avoid, which ones to follow, and for which ones there may be both good arguments for or against a certain course of action.

Some examples we will cover are the use of MAPE and sMAPE which nearly always should be avoided, or normalisations like mean normalisation for series that have no stable mean, like series with trends for example from finance [@Hewamalage2023Forecast].

This commentary focuses on point forecast evaluation. Even so, the starting point is probabilistic. Forecasts are never deterministic statements about the future; they are statements about uncertainty. A point forecast is therefore not "the future value", but a summary of a predictive distribution. Once this is recognised, three questions structure the evaluation problem.
First, which functional of the predictive distribution do we want the point forecast to represent: the mean, the median, the mode, or something else? Second, if we need scale-free comparison, what benchmark are we using to normalise errors, and is that benchmark reasonable for the series at hand? Third, once per-series errors have been computed, how should they be aggregated across series or tasks, and whose priorities does that aggregation reflect?

The rest of the paper is organised around these three questions. Section 1 argues that all point forecast evaluation starts from a predictive distribution and that an error measure should be coherent with the summary statistic one wants to elicit. Section 2 argues that normalisation is never neutral: every scale-free measure embeds a benchmark and inherits its strengths and weaknesses. Section 3 argues that aggregation across series is an explicit value judgement and should be treated as such. Throughout, we provide recommendations for two distinct settings: academic benchmark evaluation and practitioner decision support. Our main message is simple: there is no universally best error measure, academic and practitioner settings differ. There are best practices that we try to outline, and there are many choices that are poorly aligned with the forecasting problem and should therefore no longer be used by default.

<!-- TODO: Say somewhere early on that all error measures mentioned are defined in the appendix. -->

# Forecasting is always probabilistic

Forecasting differs fundamentally from tasks where near-perfect performance is achievable in principle, like many image or language processing tasks. For example, in many image classification tasks, most images have a clear correct label, humans achieve strong performance which gives us a good sense of what accuracies are achievable, and thus sufficiently capable algorithms can approach perfect accuracy with high confidence. 

Forecasting, by contrast, involves irreducible uncertainty about future outcomes, and thus there is almost always a non-degenerate distribution for the future value. Whether this distribution is produced explicitly by a probabilistic model or only implicitly by a point forecasting workflow is secondary. Conceptually, the object of interest is the predictive distribution $Y_{t+h} \mid \mathcal{F}_t$, not a single number.

This point is well understood in the statistical forecasting literature [@gneiting2007strictly], but it is still easy to forget when working with leaderboards, forecasting competitions, or business dashboards. A model may output one number, yet that number is meaningful only as a particular summary of uncertainty. For example, classical state space models estimated by likelihood typically target a conditional mean; quantile methods target specific quantiles; intermittent-demand methods often need special care because the predictive distribution is highly asymmetric and concentrated near zero. Modern machine learning systems may or may not output an explicit distribution, but the same logic applies: the point forecast is only interpretable relative to the loss or scoring rule that defines it.

This is a central point in forecasting. If all stakeholders understand it, significant progress can follow. For instance, stakeholders will no longer be uncomfortable with flat-line forecasts, causing the forecasters to add noise to the forecasts which will slightly degrade accuracy but make some stakeholders accept the forecast. Understanding that a point forecast is a summary statistic that necessarily differs from any particular realisation drawn from that distribution of future values clarifies why the eventual outcome will always appear to diverge from the forecast. The future is one particular draw from the predictive distribution, whereas a point forecast is a number that aims to best summarise the distribution.

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

This observation is central and often underappreciated in practice. People sometimes talk as if the point forecast should be the "most likely value". However, that is only true under a very particular loss, namely a 0--1 loss that rewards exact hits and penalises all misses equally. For continuous outcomes that loss is rarely useful. In most business settings, missing by a large amount is worse than missing by a small amount, so the choice of point forecast must depend on how errors are valued.

## Different error measures elicit different summaries

Formally, a point forecast solves

$$
\hat{y}_{t+h} = \arg\min_a \mathbb{E}\left[L(a, Y_{t+h})\right],
$$

where $L(a,y)$ is the loss incurred by predicting $a$ when the outcome is $y$. Different losses elicit different optimal summaries of the predictive distribution [@gneiting2007strictly; @kolassa2020best]. For the most common cases:

- squared error $L(a,y)=(a-y)^2$ elicits the mean,
- absolute error $L(a,y)=|a-y|$ elicits the median,
- 0--1 loss elicits the mode.

<!-- TODO: Make this reference with a number, Latex style? -->
Short derivations are provided in the Appendix section ["Why Squared Error Elicits the Mean and Absolute Error Elicits the Median"](#app-elicitation).

This immediately implies that the common point forecast measures are not interchangeable. Root mean squared error (RMSE) and mean absolute error (MAE) are not just two different ways of summarising the same notion of accuracy. They reward different forecast targets. If two models produce similar predictive distributions but one is better at estimating the mean while the other is better at estimating the median, RMSE and MAE may rank them differently without either ranking being wrong.

This is one reason why the blanket question "should I use RMSE or MAE?" has no universal answer. If the business decision is approximately linear in the absolute deviation, MAE may be appropriate. If large misses are disproportionately costly and the forecast target is a mean, RMSE may be preferable. 
If forecasts need to add up, e.g., in a hierarchical setting, they also need to be conditional means. If the data is intermittent (naely, if over 50% of the data is zero), the median will be a zero, so that under MAE beating a constant zero forecast is oftentimes not possible in this setting.

If the predictive distribution is symmetric, the distinction is often less consequential because mean and median coincide, which is why RMSE- and MAE-based comparisons can agree in simple stationary settings [@Hyndman2006Another; @Hewamalage2023Forecast]. But in skewed or intermittent settings the distinction can matter a great deal.

Furthermore, in many real-world business settings the preferred loss is oftentimes at least partly unknown. Should outliers be penalised heavily, and if so, how heavily? RMSE has a particularly clean interpretation under Gaussian error assumptions, where squared loss arises naturally from maximum-likelihood arguments. But that is an assumption about the error distribution, not a universal property of the metric itself. If forecast errors are not approximately normal, then squared error has no special status by default. It is appropriate only when its penalty structure matches the decision problem. If one wanted to penalise large errors even more strongly, higher-order losses such as fourth powers could be considered as well. In these situations, the real question is often how robust a forecast is across different error measures and modelling assumptions. A method that is consistently preferable across a range of plausible measures is very different from one whose ranking changes sharply as soon as the evaluation criterion changes.

## You should not use MAPE and sMAPE unless for legacy comparisons

It has now been long established in the forecasting literature that MAPE and sMAPE are problematic measures that should be retired [@Hyndman2006Another; @Armstrong2006Findings; @Kolassa2007Advantages; @Goodwin2011High]. 
The appeal of percentage errors is easy to understand. They seem scale-free and are easy to explain to non-specialists. That appeal, however, should not obscure their conceptual and statistical problems.

Mean absolute percentage error (MAPE) is undefined when the actual value is zero, unstable when the actual value is small, asymmetric in undesirable ways, and not elicitable by a meaningful central functional in general [@Hyndman2006Another; @kolassa2020best], which means that if we try to achieve the minimal MAPE we optimise for something we very likely do not want to optimise for. It does not simply target "the mean in percentage terms" or "the median in percentage terms". In practical terms, it tends to reward underforecasting in many settings and can produce deeply misleading results when small denominators occur. See @kolassa2020best for an illustrative example where MAPE is minimised by a forecast that is heavily underpredicting and most likely not what a practitiner would like to achieve.

Symmetric MAPE (sMAPE) does not resolve the underlying problem. It fixes one notion of asymmetry by changing the denominator, but introduces others, remains problematic around zeros, and can assign extreme penalties in intermittent-demand settings precisely when many actual values are zero [@Hyndman2006Another; @Kim2016new; @Kolassa2007Advantages]. 
Adding arbitrary constants or ad hoc lower bounds to these denominators may improve numerical stability [@Suilin2017kaggle; @Smyl2025SparseProof]
<!-- TODO: can look again at the papers in Foresight Issue 78. And at S. Kolassa's post on Stackoverflow.-->
, but then one loses any clear understanding of what functional the measure is eliciting. Once the denominator is engineered by hand, the metric may remain computable while ceasing to have a clean decision-theoretic interpretation.

One practical attraction of sMAPE, especially in some machine learning settings, is that it is bounded between 0 and 200 [@Smyl2025SparseProof]. However, boundedness can also be obtained in other ways that may be preferable, for example by applying a monotone bounded transform such as a logit transform to a better-grounded primary measure such as RMSE or MAE.

To summarise, many researchers have argued that MAPE should no longer be used as a default point forecast measure, and that sMAPE should not be treated as its clean fix. We support this argumentation. The continued use of these measures is best explained historically and institutionally, not statistically:
We acknowledge that it is a justifiable use of, e.g., sMAPE to compare a new method with historic results of the M3 and M4 forecasting competitions in a fair way. As the original competition participants knew they were going to be evaluated by this metric, it is plausible that they optimised their forecasts towards it, so using now different measures to compare to these original results would be unfair. 
This argument may also be valid in a business setting where we compare with a legacy system. However, we see that in practice this argument should be used with caution, as it is often an easy excuse for stakeholders to stick to business as usual and to outdated practices that clearly have been shown by research to be flawed.


## The training loss and the evaluation measure should usually align

The same logic extends from evaluation to model estimation. If a model is estimated under a criterion that targets the conditional mean, then evaluating it primarily with RMSE-type measures is coherent. This is one reason why likelihood-based ARIMA and ETS models are naturally associated with mean-oriented evaluation. By contrast, evaluating all methods only with MAE or MASE may inadvertently favour methods that are better at predicting medians, even when the competing models were not designed to do so.

This alignment problem becomes especially important when comparing classical statistical models with machine learning methods. Many of those are trained with L1, quantile (pinball), or Huber-type losses for robustness and optimisation stability, whereas classical ARIMA and ETS models estimated by likelihood are typically mean-oriented and thus aligned with squared-error evaluation. In other words, these model classes are often trained toward different functionals of the predictive distribution. This makes one-number comparisons difficult: evaluating only with RMSE can disadvantage models trained toward medians or quantiles, while evaluating only with MAE can disadvantage mean-oriented models. As a minimum safeguard against this asymmetry, studies that compare such heterogeneous model families should report both RMSE and MAE (or closely related counterparts), and clearly state which one is primary for the decision context.

At the same time, alignment does not require train and test losses to be identical. In finite samples, robustness considerations or uncertainty about the true business loss can justify deliberate departures. For example, when training data contain occasional extreme outliers (e.g., stockouts, promotions, or recording errors), estimating with Huber or L1 loss can stabilise model fitting even if the primary evaluation remains RMSE for a mean-oriented decision target. The key is transparency: state the primary measure, explain why it reflects the decision target, and use additional measures as sensitivity checks rather than as an undisciplined metric buffet.

# Normalisation is choosing a benchmark

Scale-dependent measures such as MAE and RMSE are perfectly meaningful when evaluating one series in its own units. In fact, this is often the cleanest situation because the results remain directly interpretable. So, if you don't need a scale-free measure, stick to the scaled, non-normalised measures. 
Problems arise when we want to compare errors across series with different units or scales, or when we want to aggregate performance across many series. Then we need to normalise. And already in a single series, of there are strong trend and level shifts, normalisation may be needed both during training and also for evaluation. A good example would be the bitcoin price that has changed its scale dramatically over the years. Other financial time series have similar properties.

In many machine learning forecasting papers, this step is treated as largely technical, with default preprocessing such as z-score standardisation or related mean-variance scaling applied uniformly across tasks [for example @zhou2021informer; @wu2021autoformer; @nie2023patchtst]. This can work well on many benchmark datasets, in particular the ones used as standard benchmarking suites by many papers from the machine learning community. But it should not be mistaken for a universally valid solution to normalisation in forecasting. In particular, for many financial and other near-unit-root series, the conditional mean is weakly predictable at best and often unstable over time, so the in-sample mean is not a meaningful long-run reference level. Normalising by that mean therefore does not provide a meaningful benchmark for forecast error comparison [@DeGooijer200625].
<!-- TODO: verify the reference above. -->

To summarise, normalisation is often presented as a technical afterthought, but it is not. Any normalisation divides forecast errors by something, and that "something" acts as a benchmark. Once this is recognised, many apparent disagreements between measures become easier to understand.

This also implies different defaults for different objectives. In academic benchmark studies, the objective is usually broad, method-level comparison across many heterogeneous tasks, so a benchmark-scaled measure with stable cross-series behaviour is desirable. For that purpose, we recommend RMSSE as the primary default and MASE as a useful robustness check. In practitioner settings, by contrast, the objective is usually decision support in a specific business context. There, interpretability, cost alignment, and communication often matter more than benchmark comparability, so scale-dependent measures (e.g., MAE or RMSE in business units) or carefully chosen business-weighted aggregates may be preferable.

## Why there is no universal denominator

Suppose we want to compare two models across many series. A raw MAE of $10$ is large for a low-volume SKU and negligible for a national energy load series. So we divide by a scale term. The crucial question is what that scale term represents.

If we divide by the actual value at each time point, we obtain percentage errors, with the problems discussed above. If we divide by the sum of absolute actuals over the test set, we obtain WAPE. If we divide by the mean absolute first difference in the training set, we obtain MASE [@Hyndman2006Another]. If we divide by the error of an explicit benchmark method, we obtain relative measures such as rMAE or rRMSE [@Davydenko2013Measuring]. These are not minor algebraic variants. They correspond to different notions of what a "large" error is.

There is therefore no denominator that is appropriate for every series. A good denominator for stationary intermittent demand can be a bad denominator for strongly trended macroeconomic or financial series. A denominator that works well for seasonal retail demand may be a poor choice for event-driven web traffic or for bounded physical processes such as wind power capacity factors. The right way to think about normalisation is not to ask which scaled measure is universally best, but which benchmark makes forecast errors meaningfully comparable for the data-generating features at hand.

Thus, scale-free evaluation is never a property of the numerator alone. It depends just as much on the benchmark in the denominator. Asking "how should I normalise?" is therefore equivalent to asking "relative to what baseline behaviour should this error be judged?"

## An example: WAPE is interpretable because it uses a simple benchmark

Weighted absolute percentage error,

$$
\text{WAPE} = \frac{\sum_t |y_t-\hat{y}_t|}{\sum_t |y_t|},
$$

is often attractive to practitioners because it is easy to communicate. But its interpretability comes from a very particular choice of benchmark. As noted by Hyndman [@Hyndman2025WAPE], WAPE can be read as a relative MAE with a constant-zero forecast in the denominator. That benchmark is sensible only when a zero forecast is a meaningful baseline.

This explains both the strengths and the weaknesses of WAPE. For sparse intermittent series without pronounced trend, a zero baseline may be defensible, and WAPE can work reasonably well. This is one reason why it remains popular in inventory contexts [@Kolassa2007Advantages]. But the same logic also shows why WAPE is a poor universal default. When the series has trend, level changes, or strong seasonality, the denominator changes with the holdout sample in ways that have little to do with forecasting skill. A method can produce comparable absolute errors on two different test windows and still appear better on the later window merely because the series level has drifted upward (Figure \ref{fig:wape-shortcomings}).

\begin{figure}[htbp]
\centering
\includegraphics[width=\linewidth]{paper/images/wape_shortcomings.pdf}
\caption{A strongly trended series (top) with a forecast that produces similar MAE and RMSE in an early low-level stretch (red) and a late high-level stretch (blue). The bar chart (bottom) shows that while MAE and RMSE are similar, WAPE more than doubles in the early stretch solely because the denominator (the sum of actuals) is much smaller there.}
\label{fig:wape-shortcomings}
\end{figure}

The key point is not that WAPE is always wrong. The key point is that its denominator hard-codes a specific baseline, whether or not the user acknowledges it. If zero is not a serious benchmark, the measure is misaligned with the forecasting task.



## MASE and RMSSE make the benchmark explicit

MASE and RMSSE scale by the in-sample performance of a naive benchmark rather than, e.g., by the realised magnitude of the holdout. For a non-seasonal series, MASE uses the mean absolute first difference in the training sample; for a seasonal series, a seasonal analogue can be used [@Hyndman2006Another]. RMSSE applies the same logic in squared-error form.

The key advantage of this design is that the first (seasonal) difference of a series (which equals the error of a naive forecast) is far more likely to be stationary than the level of the series itself. MASE and RMSSE therefore handle many common non-stationary situations more gracefully than measures whose denominator depends on the magnitude of the series. A further benefit is that using the training set for scaling, rather than the test set, reduces sensitivity to short or unrepresentative test windows (see also Section TODO:4).

That said, these measures also have drawbacks. At first glance they appear interpretable: a value greater than one means the method out-of-sample performs worse than the naive baseline on the training set, so we might expect MASE to lie between 0 and 1 for any useful model. In practice, however, forecasters typically predict multi-step output windows whose horizon does not coincide with the single-step naive used in the denominator, so values above one are common and do not indicate poor performance per se.

More fundamentally, the measures are only as meaningful as the naive benchmark in their denominator. If the training and test sets have very different statistical properties, or if a naive forecast is not a reasonable baseline for the domain, the scaled error values lose their intended reference point. For example, when a series has a strong predictable trend, a one-step naive benchmark can be much less informative than in a weakly dependent stationary setting. A related issue appeared in the M5 forecasting competition: some product-level series had near-zero values for most of the training period and then rose sharply in the test period. Because naive forecasts look very accurate on long zero stretches, methods are penalised heavily for missing the subsequent regime change under MASE and RMSSE, giving such series disproportionate influence in the aggregated score.

<!-- TODO: This argument should be strengthened. Hopefully get some input from Rob and Ivan. -->
Regarding the choice between MASE and RMSSE. It is, in essence, the same as the choice between MAE and RMSE: should the target be the median of the predictive distribution or the mean? MASE was originally introduced using absolute errors partly to stay close to MAPE, easing the transition away from percentage errors for practitioners. In practice, however, users willing to move beyond MAPE have been generally also comfortable with squared-error measures. We therefore recommend RMSSE as the default for broad comparative evaluation (as in many academic settings), with MASE as a useful complement when there is a specific reason to prefer absolute-error behaviour, such as reduced sensitivity to large outliers.

In sum, when the goal is to compare methods across many forecasting problems, which is the typical setup in academic research, RMSSE should be the default. Any departure from this default should be accompanied by a clear explanation of why a different measure better suits the evaluation context.

<!-- ## Trend, seasonality, intermittency, and boundedness require different defaults

Thus, while dividing by in-sample (seasonal) naive as in MASE and RMSSE is a reasonable default, normalisation should ideally start from the data characteristics.

For one series in one operational setting, scale-dependent measures may be best because they remain interpretable in the original units. For collections of series with similar scale and direct business comparability, an aggregate scale-dependent measure may also be acceptable if high-volume series are intentionally meant to matter more.

Where cross-series comparison is required, RMSSE is often the strongest primary default, with MASE as a complementary sensitivity check. For intermittent demand, percentage-type measures are especially dangerous because zeros and small values dominate the denominator; WAPE may be acceptable in some stationary sparse settings, but MAE-type measures can also be problematic because they elicit the median, which is often zero. For trending or level-shifting series, any measure whose denominator depends directly on the magnitude of the test set should be treated with caution. For seasonal series, the benchmark should usually be seasonal as well.

 -->

# Aggregation across series is a value judgement

<!-- TODO: Need to polish this section -->

Once an error has been computed per forecast, or per series, a final question remains: how should these quantities be summarised? 

In forecasting, there are usually 3 dimensions along which we average the errors from the test set: the horizon, the origins, and the series.  See Figure \ref{fig:3d_of_eval} for an illustration. It is important to note that any or all of these dimensions can collapse. For example, the horizon can be 1, we can use a fixed (single) forecast origin and we can forecast only a single time series. This is the main reason why RMSSE and MASE use a quantity derived from the training set to scale. However, if we are in a situation where the dimensions (mainly horizon and origins) have a large enough amount of data, deriving the quantity over the test set instead of the training set, and therewith effectively using rMAE and rRMSE with a (seasonal) naive as the benchmark method is preferrable. 

Another important issue is that we should aggregate only over comparable quantities. Thus, if the series are not on the same scale, we need to compute a scale-free measure like RMSSE per series and then in a second step average over all series. But already within a single series scale can change dramatically (for example the bitcoin price). If this is the situation in our data, we may even want to evaluate different regimes of a single time series separately.

TODO: Here we always have a trade-off between that on the one hand we want to aggregate for stability, and on the other hand we want to scale everything with the right scalar to make things comparable. For example, MAPE first divides then aggregates, but this leads to all the problems outlined earlier. This why it is preferrable to first aggregate then divide. But we need to make sure that what we aggregate is on the same scale.


1) Regarding the horizon: It is common to produce an output window, for example, for an hourly time series we could produce forecasts for the next 24 hours, so we produce 24 forecasts. It is common nowadays to report average error measures over these 24 forecasts, even though they have different statistical properties, as uncertainty of the forecasts usually varies with the horizon, both seasonally and increasingly. For example, there could be more uncertainty during the day than during the night, and a forecast 2 weeks out will have more uncertainty than a forecast one day out. It used to be common to report error measures separately for differen horizons (see e.g. TODO: The original M3 paper??)

2) Origin: In forecasting competitions where the test set is entirely withheld, fixed-origin evaluation is the norm. However, in real-world scenarios, we want to implement a rolling-origin scheme. Need to watch out for data leakage in then. 

3) Series: 

\begin{figure}[htbp]
\centering
\includegraphics[width=0.5\linewidth]{paper/images/drawing_3d_of_eval.pdf}
\caption{TODO}
\label{fig:3d_of_eval}
\end{figure}


Aggregation is not merely descriptive. It determines which failures count, which successes dominate, and which kinds of methods are favoured. In that sense it plays the same role as the decathlon point system: it defines what kind of all-round performance is rewarded.


## Equal weighting and value weighting answer different questions

Suppose we evaluate a method on a large panel of series. If we compute a scale-free measure per series and then take a simple average or median, every series receives equal weight. This is appropriate when every series is regarded as one forecasting problem of equal scientific importance.

If instead we compute an aggregate error over all observations first, as in a global WAPE or MAE, then high-volume series dominate. This is appropriate when business value is roughly proportional to scale: a one-unit error on a large-revenue series may indeed matter more than a one-unit error on a tiny series. In that case, the weighting is intentional, not a flaw.

Neither approach is universally correct. They answer different questions. Scale-free per-series aggregation asks whether the method performs well across forecasting problems. Global aggregation in original units asks whether the method performs well where the volume is largest. In practice, many organisations want something between these extremes: not complete equality across series, but also not a metric in which one giant series overwhelms thousands of smaller yet still relevant ones.

## Competition leaderboards make these choices visible

Recent benchmark datasets make the issue very concrete. In academic benchmark settings, it is now common to evaluate methods over large heterogeneous collections of series and then publish a single leaderboard score. But that single number is the output of several design decisions.

<!-- TODO: Say that these are from the ML community? 
How do they compare with earlier such attempts, e.g. the M4? 
Check the citations.-->
<!-- TODO: check what fev-bench does here. They have an ELO score and I think some win rate or so? -->
Two prominent examples are GIFT-Eval [@aksu2024gifteval] and fev-bench [@shchur2025fevbench], both designed as broad academic benchmarks for comparing methods across many heterogeneous forecasting tasks. GIFT-Eval is a concrete example for how a single leaderboard number is constructed. Its public leaderboard first computes MASE at the series level, then takes the median MASE within each task (dataset-frequency split), then normalises each task score by the corresponding score of a seasonal naive baseline, and finally aggregates the normalised task scores using a geometric mean across tasks. In compact form, if $M_j$ is the median MASE for task $j$ and $M^{(snaive)}_j$ is the seasonal-naive counterpart, the overall score is

$$
\left(\prod_{j=1}^{J} \frac{M_j}{M^{(snaive)}_j}\right)^{1/J}.
$$

This design rewards methods that are broadly reliable and penalises those that fail badly on a subset of tasks. That may be exactly the intended objective. But it also means that the final ranking depends strongly on how tasks are defined and weighted. 

<!-- TODO: The following is not just an example, it is actually what is happening in GIFT-Eval -->
A single river-flow series represented at daily, weekly, and monthly frequencies can end up with more influence on the final ranking than a much larger collection of economically important series if each task receives equal weight. This is not an error in arithmetic. It is a value judgement embedded in the evaluation design.

The lesson is the same as in the decathlon analogy from the introduction. Once we aggregate across heterogeneous tasks, we are no longer asking only "which method forecasts best?" We are asking "which method forecasts best under this specific weighting of failures, scales, and domains?" Leaderboards are useful, but their scoring rules should be interpreted as part of the benchmark, not as neutral facts.

## What should count more in practice?

For practical forecast evaluation, the weighting scheme should be chosen deliberately and explained in business terms.

If all series are equally important, use scale-free per-series measures and aggregate them with a mean or median. If larger series matter more because they drive revenue, inventory cost, or service levels, use explicit weights that reflect those stakes. If some strategic series are disproportionately important, assign those weights directly rather than hoping that an off-the-shelf metric will encode the priority by accident. And if robustness matters, report sensitivity to several aggregation choices.

This is especially important when communicating results between technical and non-technical audiences. A scientist may prefer equal weighting because it is methodologically clean. A business stakeholder may prefer value weighting because it aligns with cost. Both positions are reasonable. Problems arise only when the weighting is implicit and the resulting single number is treated as if it carried an objective meaning independent of those priorities.

## Recommendations for summarising performance

Three practical rules follow.

First, separate the within-series error measure from the across-series aggregation step. They solve different problems and should not be conflated.

Second, make the weighting scheme explicit. "Equal weight per series", "equal weight per task", and "weight proportional to revenue" are all defensible choices, but they describe different objectives.

Third, avoid reporting only one grand average whenever the result could be driven by a few atypical tasks or by a hidden weighting effect. At minimum, a primary aggregate should be accompanied by a small amount of distributional information, such as a median together with a mean, or task-level summaries that make obvious where the method wins and where it fails.

# Conclusion

Point forecast evaluation is often made unnecessarily confusing because three different design choices are mixed together. The first is elicitation: which summary of the predictive distribution should the point forecast represent? The second is normalisation: relative to which benchmark should errors be judged? The third is aggregation: which series or tasks should carry more weight in the final summary?

Once these questions are separated, many long-running debates become more tractable. RMSE and MAE are not rivals in search of one winner; they target different functionals. WAPE is not a universally interpretable percentage measure; it is a relative error built around a zero benchmark and therefore appropriate only in some settings. MASE and RMSSE are strong defaults for comparative work because they make the benchmark explicit and are less sensitive to holdout scale, but they still depend on the relevance of the naive baseline. And any summary across many series is inevitably a statement about what matters more.

Our recommendations are therefore straightforward. If possible, start from the predictive distribution and the decision problem, not from a familiar metric. Avoid MAPE and do not treat sMAPE as a general repair. When normalisation is needed, choose a benchmark that is defensible for the data characteristics of the series. For academic benchmark studies, use RMSSE as the primary default and report MASE as a robustness check; for practitioner use, prioritise measures and aggregation schemes that align with business cost and interpretability. When aggregating across many series, state clearly whether the goal is equality across forecasting problems, weighting by business value, or something in between.

The broader implication is that evaluation design is itself part of forecasting methodology. A leaderboard, a benchmark table, or a business KPI is only as meaningful as the choices that produced it. If forecasting is to improve in both academia and practice, those choices need to become explicit, technically defensible, and aligned with the decision context they are meant to serve.

<!-- TODO: can we be more concrete for the full process, for example what GIFT-Eval or fev-bench do? Lay out a clear pipeline for situations when there is no downstream decision, or when you don't know it. -->


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

# References