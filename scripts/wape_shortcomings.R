# WAPE shortcomings: a heavily trended series where two equal-error stretches
# yield very different WAPE values due to the changing denominator.

set.seed(42)
n <- 60  # 60 periods, two halves of 30 each

# Strongly trended actuals: level doubles from stretch 1 to stretch 2.
level1 <- 20
level2 <- 200
noise_sd <- 3   # same absolute noise throughout

actuals <- c(
  level1 + seq(0, level2 - level1, length.out = n / 2) / 2 +
    rnorm(n / 2, 0, noise_sd),
  level2 / 2 + seq(0, level2 / 2, length.out = n / 2) +
    rnorm(n / 2, 0, noise_sd)
)
# Ensure positive
actuals <- pmax(actuals, 1)

# Forecast: persistent positive bias of fixed absolute size on both halves.
bias <- 4
forecasts <- actuals + bias + rnorm(n, 0, 0.5)

# Split into two stretches.
idx1 <- 1:(n / 2)
idx2 <- (n / 2 + 1):n

# Compute metrics per stretch.
mae1   <- mean(abs(actuals[idx1] - forecasts[idx1]))
mae2   <- mean(abs(actuals[idx2] - forecasts[idx2]))
rmse1  <- sqrt(mean((actuals[idx1] - forecasts[idx1])^2))
rmse2  <- sqrt(mean((actuals[idx2] - forecasts[idx2])^2))
wape1  <- sum(abs(actuals[idx1] - forecasts[idx1])) / sum(abs(actuals[idx1])) * 100
wape2  <- sum(abs(actuals[idx2] - forecasts[idx2])) / sum(abs(actuals[idx2])) * 100

cat(sprintf("Stretch 1  MAE=%.2f  RMSE=%.2f  WAPE=%.1f%%\n", mae1, rmse1, wape1))
cat(sprintf("Stretch 2  MAE=%.2f  RMSE=%.2f  WAPE=%.1f%%\n", mae2, rmse2, wape2))

# --- Plot ----------------------------------------------------------------
output_file <- "output/wape_shortcomings.pdf"
dir.create(dirname(output_file), recursive = TRUE, showWarnings = FALSE)
pdf(output_file, width = 9, height = 7)

opar <- par(mfrow = c(2, 1), mar = c(4, 4.5, 2.5, 1))
on.exit({ par(opar); dev.off() }, add = TRUE)

col_actual   <- "gray20"
col_forecast <- "steelblue"
col_s1       <- "#d73027"   # red for stretch 1 shading
col_s2       <- "#4575b4"   # blue for stretch 2 shading

# Panel 1: actuals and forecasts with shaded stretches.
ylim_main <- range(c(actuals, forecasts)) * c(0.9, 1.1)
plot(actuals, type = "n", ylim = ylim_main,
     xlab = "Time", ylab = "Value",
     main = "Trended series: same absolute errors, very different WAPE")
rect(idx1[1] - 0.5, ylim_main[1], tail(idx1, 1) + 0.5, ylim_main[2],
     col = adjustcolor(col_s1, 0.10), border = NA)
rect(idx2[1] - 0.5, ylim_main[1], tail(idx2, 1) + 0.5, ylim_main[2],
     col = adjustcolor(col_s2, 0.10), border = NA)
lines(actuals, col = col_actual, lwd = 1.8)
lines(forecasts, col = col_forecast, lwd = 1.8, lty = 2)
# Error bars
segments(seq_along(actuals), actuals, seq_along(actuals), forecasts,
         col = "gray60", lwd = 0.8)
legend("topleft", bty = "n",
       legend = c("Actuals", "Forecasts"),
       col = c(col_actual, col_forecast), lty = c(1, 2), lwd = 2)
mtext("Stretch 1 (low level)", side = 3, at = mean(idx1),
      col = col_s1, cex = 0.85, font = 2)
mtext("Stretch 2 (high level)", side = 3, at = mean(idx2),
      col = col_s2, cex = 0.85, font = 2)

# Panel 2: bar chart comparing the three metrics side by side.
metrics <- rbind(
  MAE  = c(mae1,  mae2),
  RMSE = c(rmse1, rmse2),
  WAPE = c(wape1, wape2)
)
# One colour per metric row; repeat for each stretch group.
metric_cols <- c("#e41a1c", "#377eb8", "#4daf4a")  # red=MAE, blue=RMSE, green=WAPE

# Scale WAPE so it plots alongside MAE/RMSE (secondary axis concept via annotation).
# Show MAE and RMSE on left y-axis, WAPE separately as text labels.
bp <- barplot(metrics,
              beside = TRUE,
              col = rep(metric_cols, times = ncol(metrics)),
              names.arg = c("Stretch 1\n(low level)", "Stretch 2\n(high level)"),
              ylab = "Metric value",
              main = "Metric comparison across stretches",
              legend.text = rownames(metrics),
              args.legend = list(x = "topleft", bty = "n"),
              ylim = c(0, max(metrics) * 1.25))
# Annotate bars with values.
for (i in seq_len(ncol(metrics))) {
  for (j in seq_len(nrow(metrics))) {
    val <- metrics[j, i]
    label <- if (rownames(metrics)[j] == "WAPE") sprintf("%.1f%%", val) else sprintf("%.2f", val)
    text(bp[j, i], val + max(metrics) * 0.02, label, cex = 0.78, font = 2)
  }
}
