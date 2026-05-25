#!/usr/bin/env python3
"""
Walk-Forward Analysis (WFA)  Alpha Logic Hub

Evaluates strategy robustness by running sequential in-sample optimization
followed by out-of-sample testing. Prevents overfitting by measuring how
well parameters generalize to unseen data.

Key metrics:
  - WFE (Walk-Forward Efficiency): % of IS return retained OOS
  - OOS Consistency: % of windows with positive OOS return
  - Avg OOS Return / Max DD: risk-adjusted OOS performance

Usage:
    python walk_forward.py --strategy sma_crossover --symbol XAUUSD --period 3y
    python walk_forward.py --strategy supply_demand --symbol XAUUSD --start 2020-01-01 --end 2024-01-01 --windows 6

Grid search params can be customized via --param-grid or defaults from strategy.
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, List, Tuple

import pandas as pd
import numpy as np

sys.path.insert(0, str(Path(__file__).parent))

from backtest import load_data, run_backtest
from fetch_data import parse_period
from optimize import grid_search


def generate_default_grid(strategy_name: str) -> Dict[str, List[Any]]:
    """Return a default parameter grid for the given strategy."""
    grids = {
        "sma_crossover": {
            "fast_period": [5, 10, 20, 30, 50],
            "slow_period": [50, 100, 150, 200],
        },
        "ema_crossover": {
            "fast_period": [5, 10, 12, 20, 30],
            "slow_period": [20, 26, 50, 100, 200],
        },
        "rsi_reversal": {
            "period": [7, 14, 21],
            "oversold": [25, 30, 35],
            "overbought": [65, 70, 75],
        },
        "macd": {
            "fast": [8, 12, 16],
            "slow": [21, 26, 34],
            "signal": [7, 9, 12],
        },
        "bollinger_bands": {
            "period": [15, 20, 25],
            "std_dev": [1.5, 2.0, 2.5],
        },
        "breakout": {
            "lookback": [10, 15, 20, 30],
            "threshold": [0.0, 0.5, 1.0],
        },
        "mean_reversion": {
            "period": [10, 20, 30],
            "z_threshold": [1.5, 2.0, 2.5],
        },
        "momentum": {
            "period": [10, 14, 20],
            "threshold": [3.0, 5.0, 8.0],
        },
        "supply_demand": {
            "min_impulse_pct": [0.5, 0.8, 1.2],
            "min_cons_bars": [3, 5],
        },
    }
    return grids.get(strategy_name, {"fast_period": [10, 20], "slow_period": [50, 100]})


def create_windows(
    data: pd.DataFrame,
    n_windows: int = 6,
    train_pct: float = 0.7,
    anchor: bool = False,
) -> List[Tuple[int, int, int, int]]:
    """Create sequential IS/OOS window pairs.

    Returns list of (is_start, is_end, oos_start, oos_end) as row indices.
    If anchor=True, IS always starts at bar 0 (growing window).
    If anchor=False, IS is a fixed-size rolling window.
    """
    n = len(data)
    window_size = n // n_windows
    train_size = int(window_size * train_pct)
    windows = []

    for w in range(n_windows):
        if anchor:
            # Growing IS: always starts at 0
            is_start = 0
            is_end = (w + 1) * train_size
        else:
            # Rolling IS: fixed size, slides forward
            is_start = w * train_size
            is_end = is_start + train_size

        oos_start = is_end
        oos_end = min(oos_start + (window_size - train_size), n)

        if is_end > oos_start or oos_end - oos_start < 5:
            continue

        windows.append((is_start, is_end, oos_start, oos_end))

    return windows


def run_walk_forward(
    strategy_name: str,
    data: pd.DataFrame,
    param_grid: Dict[str, List[Any]],
    n_windows: int = 6,
    train_pct: float = 0.7,
    anchor: bool = False,
    initial_capital: float = 10000,
    spread_pts: float = 20,
    metric: str = "sharpe_ratio",
) -> Dict[str, Any]:
    """Run complete walk-forward analysis.

    Returns dict with per-window results and aggregated robustness metrics.
    """
    windows = create_windows(data, n_windows, train_pct, anchor)
    if not windows:
        return {"error": "Not enough data for WFA windows"}

    print(f"\n  WFA Windows: {len(windows)}")
    if anchor:
        print(f"  IS mode: Anchored (growing)")
    else:
        print(f"  IS mode: Rolling ({train_pct*100:.0f}% train per window)")
    print(f"  Optimization metric: {metric}")
    print("-" * 70)

    results = []
    for w_idx, (is_s, is_e, oos_s, oos_e) in enumerate(windows):
        is_data = data.iloc[is_s:is_e]
        oos_data = data.iloc[oos_s:oos_e]

        is_start_d = data.index[is_s].strftime("%Y-%m-%d")
        is_end_d = data.index[is_e - 1].strftime("%Y-%m-%d")
        oos_start_d = data.index[oos_s].strftime("%Y-%m-%d")
        oos_end_d = data.index[oos_e - 1].strftime("%Y-%m-%d")

        print(f"\n  Window {w_idx + 1}:")
        print(f"    IS: {is_start_d} -> {is_end_d} ({len(is_data)} bars)")
        print(f"    OOS: {oos_start_d} -> {oos_end_d} ({len(oos_data)} bars)")

        # 1. Optimize on IS
        print(f"    Optimizing on IS ({len(is_data)} bars)...")
        opt_results = grid_search(
            strategy_name=strategy_name,
            data=is_data.copy(),
            param_grid=param_grid,
            initial_capital=initial_capital,
            spread_pts=spread_pts,
            metric=metric,
        )

        if opt_results.empty:
            print(f"    WARNING: No valid IS results for window {w_idx + 1}")
            continue

        best_params = opt_results.iloc[0].to_dict()
        print(f"    Best params: {', '.join(f'{k}={best_params[k]}' for k in param_grid)}")

        # 2. Run OOS with best params
        oos_result = run_backtest(
            strategy_name=strategy_name,
            data=oos_data.copy(),
            initial_capital=initial_capital,
            params={k: best_params[k] for k in param_grid},
            spread_pts=spread_pts,
        )

        # 3. Run IS with best params for comparison
        is_result = run_backtest(
            strategy_name=strategy_name,
            data=is_data.copy(),
            initial_capital=initial_capital,
            params={k: best_params[k] for k in param_grid},
            spread_pts=spread_pts,
        )

        # 4. Calculate WFE
        is_return = is_result.total_return
        oos_return = oos_result.total_return
        wfe = (oos_return / is_return * 100) if is_return > 0 else 0.0

        results.append({
            "window": w_idx + 1,
            "is_start": is_start_d,
            "is_end": is_end_d,
            "oos_start": oos_start_d,
            "oos_end": oos_end_d,
            "is_bars": len(is_data),
            "oos_bars": len(oos_data),
            "best_params": {k: best_params[k] for k in param_grid},
            "is_return": is_return,
            "oos_return": oos_return,
            "is_sharpe": is_result.sharpe_ratio,
            "oos_sharpe": oos_result.sharpe_ratio,
            "is_max_dd": is_result.max_drawdown,
            "oos_max_dd": oos_result.max_drawdown,
            "is_trades": is_result.total_trades,
            "oos_trades": oos_result.total_trades,
            "wfe": wfe,
        })

        print(f"    IS return: {is_return:+.2f}% | OOS return: {oos_return:+.2f}% | WFE: {wfe:.1f}%")

    if not results:
        return {"error": "No valid WFA windows completed"}

    df = pd.DataFrame(results)

    # Robustness metrics
    avg_wfe = df["wfe"].mean()
    median_wfe = df["wfe"].median()
    oos_positive = (df["oos_return"] > 0).sum()
    oos_consistency = oos_positive / len(df) * 100
    avg_oos_return = df["oos_return"].mean()
    avg_oos_sharpe = df["oos_sharpe"].mean()
    avg_oos_dd = df["oos_max_dd"].mean()
    avg_is_return = df["is_return"].mean()

    # Score: combination of WFE and consistency
    if avg_wfe > 75 and oos_consistency >= 80:
        robustness = "HIGH"
    elif avg_wfe > 50 and oos_consistency >= 60:
        robustness = "MODERATE"
    else:
        robustness = "LOW"

    print("\n" + "=" * 70)
    print("  WALK-FORWARD ANALYSIS SUMMARY")
    print("=" * 70)
    print(f"  Windows completed:   {len(df)}")
    print(f"  Avg IS return:       {avg_is_return:+.2f}%")
    print(f"  Avg OOS return:      {avg_oos_return:+.2f}%")
    print(f"  Avg OOS Sharpe:      {avg_oos_sharpe:.2f}")
    print(f"  Avg OOS Max DD:      {avg_oos_dd:.2f}%")
    print(f"  Avg WFE:             {avg_wfe:.1f}%")
    print(f"  Median WFE:          {median_wfe:.1f}%")
    print(f"  OOS Consistency:     {oos_consistency:.0f}% ({oos_positive}/{len(df)} windows)")
    print(f"  Robustness rating:   {robustness}")
    print("-" * 70)

    return {
        "windows": results,
        "summary": {
            "windows_completed": len(df),
            "avg_is_return": avg_is_return,
            "avg_oos_return": avg_oos_return,
            "avg_oos_sharpe": avg_oos_sharpe,
            "avg_oos_max_dd": avg_oos_dd,
            "avg_wfe": avg_wfe,
            "median_wfe": median_wfe,
            "oos_consistency_pct": oos_consistency,
            "oos_positive_windows": int(oos_positive),
            "robustness": robustness,
        },
        "details_df": df,
    }


def format_wfa_report(result: Dict[str, Any]) -> str:
    """Format WFA results for console output."""
    if "error" in result:
        return f"\n  WFA ERROR: {result['error']}\n"

    lines = []
    s = result["summary"]
    lines.append(f"\n  Robustness rating: {s['robustness']}")
    lines.append(f"  Avg OOS return:   {s['avg_oos_return']:+.2f}%")
    lines.append(f"  Avg WFE:          {s['avg_wfe']:.1f}%")
    lines.append(f"  Consistency:      {s['oos_consistency_pct']:.0f}%")
    lines.append(f"  Windows:          {s['windows_completed']}")

    lines.append(f"\n  Per-window breakdown:")
    for w in result["windows"]:
        bp = ", ".join(f"{k}={v}" for k, v in w["best_params"].items())
        lines.append(
            f"    W{w['window']}: IS {w['is_return']:+.1f}% -> OOS {w['oos_return']:+.1f}% | "
            f"WFE {w['wfe']:.0f}% | Params: {bp}"
        )

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(
        description="Walk-Forward Analysis — measure strategy robustness"
    )
    parser.add_argument("--strategy", "-s", required=True, help="Strategy name")
    parser.add_argument("--symbol", default="XAUUSD", help="Trading symbol")
    parser.add_argument("--period", "-p", default="3y", help="Lookback period")
    parser.add_argument("--start", help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end", help="End date (YYYY-MM-DD)")
    parser.add_argument("--source", default="yfinance", choices=["mt5", "yfinance"])
    parser.add_argument("--capital", "-c", type=float, default=10000)
    parser.add_argument("--spread", type=float, default=20)
    parser.add_argument("--windows", "-w", type=int, default=6, help="Number of WFA windows")
    parser.add_argument("--train-pct", type=float, default=0.7, help="Training % per window")
    parser.add_argument("--anchor", action="store_true", help="Anchored IS (growing window)")
    parser.add_argument("--metric", default="sharpe_ratio", help="Optimization metric")
    parser.add_argument("--param-grid", help="Custom param grid as JSON (overrides defaults)")
    parser.add_argument("--output", "-o", help="Output directory")

    args = parser.parse_args()

    # Date range
    if args.start and args.end:
        start = datetime.strptime(args.start, "%Y-%m-%d")
        end = datetime.strptime(args.end, "%Y-%m-%d")
    else:
        end = datetime.now()
        start = end - parse_period(args.period)

    # Load data
    script_dir = Path(__file__).parent.parent
    data_dir = script_dir / "data"

    print(f"\n  Loading {args.symbol} data...")
    data = load_data(args.symbol, start, end, data_dir, source=args.source)
    data.attrs["symbol"] = args.symbol
    print(f"   Loaded {len(data)} bars")

    # Param grid
    param_grid = (
        json.loads(args.param_grid) if args.param_grid
        else generate_default_grid(args.strategy)
    )

    print(f"  Strategy: {args.strategy}")
    print(f"  Windows: {args.windows} (train={args.train_pct*100:.0f}%, anchor={args.anchor})")
    print(f"  Params: {list(param_grid.keys())}")
    print(f"  Grid size: {sum(len(v) for v in param_grid.values())} combinations")

    # Run WFA
    result = run_walk_forward(
        strategy_name=args.strategy,
        data=data,
        param_grid=param_grid,
        n_windows=args.windows,
        train_pct=args.train_pct,
        anchor=args.anchor,
        initial_capital=args.capital,
        spread_pts=args.spread,
        metric=args.metric,
    )

    print(format_wfa_report(result))

    # Save results
    if isinstance(result, dict) and "details_df" in result:
        output_dir = Path(args.output) if args.output else script_dir / "reports"
        output_dir.mkdir(parents=True, exist_ok=True)

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        csv_file = output_dir / f"wfa_{args.strategy}_{args.symbol}_{timestamp}.csv"
        result["details_df"].to_csv(csv_file, index=False)
        print(f"\n  Details saved to: {csv_file}")


if __name__ == "__main__":
    main()
