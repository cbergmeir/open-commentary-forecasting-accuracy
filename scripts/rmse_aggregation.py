import csv
import itertools
from pathlib import Path

import numpy as np
from scipy.optimize import brentq
from scipy.stats import binom


HORIZONS = (1, 2, 4, 8, 16, 32, 64, 128, 256)
PROBABILITIES = (0.2, 0.8)


def distribution(n, p):
    counts = np.arange(n + 1)
    return counts / n, binom.pmf(counts, n, p)


def expected_rmse(a, n, p):
    frequency, probability = distribution(n, p)
    return probability @ np.sqrt((1 - frequency) * a**2 + frequency * (1 - a)**2)


def derivative(a, n, p):
    frequency, probability = distribution(n, p)
    distance = np.sqrt((1 - frequency) * a**2 + frequency * (1 - a)**2)
    return probability @ ((a - frequency) / distance)


def optimal_forecast(n, p):
    frequency, probability = distribution(n, p)
    right_at_zero = probability[0] - probability[1:] @ np.sqrt(frequency[1:])
    left_at_one = probability[:-1] @ np.sqrt(1 - frequency[:-1]) - probability[-1]
    if right_at_zero >= 0:
        return 0.0
    if left_at_one <= 0:
        return 1.0
    return brentq(derivative, np.finfo(float).eps, 1 - np.finfo(float).eps, args=(n, p), xtol=1e-14)


def validate():
    for n in (1, 2, 4):
        outcomes = np.array(list(itertools.product((0, 1), repeat=n)))
        for p in PROBABILITIES:
            weights = np.prod(np.where(outcomes == 1, p, 1 - p), axis=1)
            for a in (0.0, p, 0.5, 1.0):
                direct = weights @ np.sqrt(np.mean((outcomes - a)**2, axis=1))
                np.testing.assert_allclose(expected_rmse(a, n, p), direct, rtol=1e-13, atol=1e-14)
    for n in HORIZONS:
        a = optimal_forecast(n, PROBABILITIES[0])
        b = optimal_forecast(n, PROBABILITIES[1])
        np.testing.assert_allclose(a + b, 1.0, atol=1e-12)
        if 0 < a < 1:
            assert abs(derivative(a, n, PROBABILITIES[0])) < 1e-11
        grid = np.linspace(0, 1, 10001)
        frequency, probability = distribution(n, PROBABILITIES[0])
        values = np.sqrt((1 - frequency) * grid[:, None]**2 + frequency * (1 - grid[:, None])**2) @ probability
        assert expected_rmse(a, n, PROBABILITIES[0]) <= values.min() + 1e-13
    assert optimal_forecast(1, 0.2) == 0
    np.testing.assert_allclose(expected_rmse(0.2, 1, 0.2), 0.32)
    np.testing.assert_allclose(expected_rmse(0, 1, 0.2), 0.2)


def main():
    validate()
    rows = []
    for p in PROBABILITIES:
        for n in HORIZONS:
            optimum = optimal_forecast(n, p)
            median = float(p > 0.5)
            rows.append({
                'probability': p,
                'horizon': n,
                'optimal_constant': optimum,
                'expected_rmse_optimum': expected_rmse(optimum, n, p),
                'expected_rmse_mean': expected_rmse(p, n, p),
                'expected_rmse_median': expected_rmse(median, n, p),
                'population_rmse_mean': np.sqrt(p * (1 - p)),
                'population_rmse_median': np.sqrt(p * (1 - p) + (median - p)**2),
                'mean_forecast_regret': expected_rmse(p, n, p) - expected_rmse(optimum, n, p),
            })
    target = Path(__file__).resolve().parent / 'rmse_aggregation.csv'
    with target.open('w', newline='') as stream:
        writer = csv.DictWriter(stream, fieldnames=rows[0].keys(), lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    print('Exact expectations and independent validation passed.')
    print(target.name)


if __name__ == '__main__':
    main()
