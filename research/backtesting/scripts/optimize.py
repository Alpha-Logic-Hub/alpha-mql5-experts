#!/usr/bin/env python3
"""
Strategy Parameter Optimizer  Alpha Logic Hub
Grid search over strategy parameters to find optimal combinations.

Usage:
    python optimize.py --strategy sma_crossover --symbol XAUUSD --period 2y \
        --param-grid '{"fast_period": [10,20,30,50], "slow_period": [100,150,200]}'
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime, timedelta
from itertools import product
from typing import Dict, Any, List

import pandas as pd

sys.path.insert(0, str(Path(__file__).parent))

from backtest import load_data, run_backtest
from fetch_data import parse_period
from metrics import BacktestResult


def grid_search(
    strategy_name: str,
    data: pd.DataFrame,
    param_grid: Dict[str, List[Any]],
    initial_capital: float = 10000,
    spread_pts: float = 20,
    metric: str = 'sharpe_ratio',
) -> pd.DataFrame:
    """Run grid search over parameter combinations, ranking by metric."""

    param_names = list(param_grid.keys())
    param_values = list(param_grid.values())
    combinations = list(product(*param_values))

    print(f"Testing {len(combinations)} parameter combinations...")

    results = []
    for i, combo in enumerate(combinations):
        params = dict(zip(param_names, combo))

        try:
            result = run_backtest(
                strategy_name=strategy_name,
                data=data.copy(),
                initial_capital=initial_capital,
                params=params,
                spread_pts=spread_pts,
            )

            results.append({
                **params,
                'total_return': result.total_return,
                'sharpe_ratio': result.sharpe_ratio,
                'sortino_ratio': result.sortino_ratio,
                'max_drawdown': result.max_drawdown,
                'win_rate': result.win_rate,
                'profit_factor': result.profit_factor,
                'total_trades': result.total_trades,
                'calmar_ratio': result.calmar_ratio,
                'volatility': result.volatility,
            })

            if (i + 1) % 20 == 0:
                print(f"  Progress: {i + 1}/{len(combinations)}")
        except Exception as e:
            print(f"    Error with {params}: {e}")
            continue

    df = pd.DataFrame(results)
    if metric in df.columns:
        df = df.sort_values(metric, ascending=False)

    return df


def format_optimization_results(df: pd.DataFrame, param_names: List[str], metric: str) -> str:
    output = []
    output.append("=" * 80)
    output.append("PARAMETER OPTIMIZATION RESULTS")
    output.append(f"Optimizing for: {metric}")
    output.append("=" * 80)

    output.append("\nTOP 10 COMBINATIONS:")
    output.append("-" * 80)

    header = param_names + ['Return%', 'Sharpe', 'MaxDD%', 'Win%', 'Trades']
    output.append("  ".join(f"{h:>10}" for h in header))
    output.append("-" * 80)

    for _, row in df.head(10).iterrows():
        vals = [str(row[p]) if isinstance(row[p], (int, str)) else f"{row[p]:.1f}" for p in param_names]
        vals += [
            f"{row['total_return']:.1f}",
            f"{row['sharpe_ratio']:.2f}",
            f"{row['max_drawdown']:.1f}",
            f"{row['win_rate']:.1f}",
            f"{row['total_trades']:.0f}",
        ]
        output.append("  ".join(f"{v:>10}" for v in vals))

    best = df.iloc[0]
    output.append("\n" + "=" * 80)
    output.append("  BEST PARAMETERS:")
    for p in param_names:
        output.append(f"    {p}: {best[p]}")
    output.append(f"\n    Expected:")
    output.append(f"      Total Return: {best['total_return']:.2f}%")
    output.append(f"      Sharpe Ratio: {best['sharpe_ratio']:.2f}")
    output.append(f"      Max Drawdown: {best['max_drawdown']:.2f}%")
    output.append(f"      Win Rate: {best['win_rate']:.1f}%")
    output.append("=" * 80)

    return "\n".join(output)


def main():
    parser = argparse.ArgumentParser(description='Optimize strategy parameters for XAUUSD')
    parser.add_argument('--strategy', '-s', required=True, help='Strategy name')
    parser.add_argument('--symbol', default='XAUUSD', help='Trading symbol')
    parser.add_argument('--param-grid', required=True, help='Parameter grid as JSON')
    parser.add_argument('--period', '-p', default='2y', help='Lookback period')
    parser.add_argument('--start', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end', help='End date (YYYY-MM-DD)')
    parser.add_argument('--capital', '-c', type=float, default=10000, help='Initial capital')
    parser.add_argument('--spread', type=float, default=20, help='Spread in points')
    parser.add_argument('--metric', '-m', default='sharpe_ratio', help='Optimization metric')
    parser.add_argument('--output', '-o', help='Output directory')
    parser.add_argument('--source', default='mt5', choices=['mt5', 'yfinance'])

    args = parser.parse_args()
    param_grid = json.loads(args.param_grid)

    # Date range
    if args.start and args.end:
        start = datetime.strptime(args.start, '%Y-%m-%d')
        end = datetime.strptime(args.end, '%Y-%m-%d')
    else:
        end = datetime.now()
        start = end - parse_period(args.period)

    # Load data
    script_dir = Path(__file__).parent.parent
    data_dir = script_dir / 'data'

    print(f"\n Loading {args.symbol} data...")
    data = load_data(args.symbol, start, end, data_dir, source=args.source)
    data.attrs['symbol'] = args.symbol
    print(f"   Loaded {len(data)} bars")

    # Run optimization
    print(f"\n  Optimizing {args.strategy} for {args.metric}...")
    results_df = grid_search(
        strategy_name=args.strategy,
        data=data,
        param_grid=param_grid,
        initial_capital=args.capital,
        spread_pts=args.spread,
        metric=args.metric,
    )

    # Format and print
    param_names = list(param_grid.keys())
    output = format_optimization_results(results_df, param_names, args.metric)
    print(output)

    # Save
    output_dir = Path(args.output) if args.output else script_dir / 'reports'
    output_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    csv_file = output_dir / f"optim_{args.strategy}_{args.symbol}_{timestamp}.csv"
    results_df.to_csv(csv_file, index=False)
    print(f"\n Full results saved to: {csv_file}")

    txt_file = output_dir / f"optim_{args.strategy}_{args.symbol}_{timestamp}.txt"
    with open(txt_file, 'w') as f:
        f.write(output)
    print(f" Summary saved to: {txt_file}")


if __name__ == '__main__':
    main()
