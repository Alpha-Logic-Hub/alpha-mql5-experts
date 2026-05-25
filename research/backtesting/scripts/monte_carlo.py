#!/usr/bin/env python3
"""
Monte Carlo Simulation  Alpha Logic Hub

Simulates thousands of alternative trade sequences by reshuffling or
bootstrapping the trade list from a single backtest run. Answers:

  - What's the probability of blowing the account?
  - What range of returns should I expect?
  - Is the strategy robust or was the single run lucky?

Three simulation modes:
  1. shuffle: randomize trade order (preserves distribution, removes sequence luck)
  2. bootstrap: resample trades with replacement (simulates different trade sets)
  3. equity_returns: resample daily returns (simulates market path variability)

Usage:
    python monte_carlo.py --strategy ema_crossover --symbol XAUUSD --period 2y
    python monte_carlo.py --trades-file reports/trades.csv --simulations 5000
"""

import argparse
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import List, Optional

import numpy as np
import pandas as pd

sys.path.insert(0, str(Path(__file__).parent))

from backtest import load_data, run_backtest
from fetch_data import parse_period
from metrics import Trade, calculate_total_return, calculate_cagr


def bootstrap_trades(
    trades: List[Trade],
    n_simulations: int = 1000,
    mode: str = "shuffle",
    initial_capital: float = 10000,
    seed: Optional[int] = None,
) -> pd.DataFrame:
    """Run Monte Carlo simulations by resampling trade sequences.

    Args:
        trades: List of Trade objects from a backtest
        n_simulations: Number of simulations to run
        mode: 'shuffle' (randomize order) or 'bootstrap' (resample with replacement)
        initial_capital: Starting capital
        seed: Random seed for reproducibility

    Returns:
        DataFrame with simulation results (final_equity, total_return, max_dd)
    """
    if not trades:
        return pd.DataFrame()

    rng = np.random.default_rng(seed)

    # Extract PnLs as % of capital
    pnls = np.array([t.pnl for t in trades])
    n_trades = len(pnls)

    results = []
    for sim in range(n_simulations):
        if mode == "bootstrap":
            # Sample N trades with replacement (some may repeat, some omitted)
            sim_pnls = rng.choice(pnls, size=n_trades, replace=True)
        else:
            # Shuffle: same trades, different order
            sim_pnls = rng.permutation(pnls)

        # Build equity curve
        equity = initial_capital
        peak = equity
        max_dd = 0.0

        for pnl in sim_pnls:
            equity += pnl
            if equity <= 0:
                equity = 0
                break
            peak = max(peak, equity)
            dd = (peak - equity) / peak * 100
            max_dd = max(max_dd, dd)

        total_ret = (equity - initial_capital) / initial_capital * 100
        results.append({
            "simulation": sim + 1,
            "final_equity": equity,
            "total_return": total_ret,
            "max_drawdown": max_dd,
            "survived": equity > 0,
        })

    return pd.DataFrame(results)


def bootstrap_equity_returns(
    equity_curve: pd.Series,
    n_simulations: int = 1000,
    initial_capital: float = 10000,
    seed: Optional[int] = None,
) -> pd.DataFrame:
    """Run Monte Carlo by resampling daily returns from equity curve.

    Simulates alternative market paths by shuffling the sequence of
    daily returns (preserves distribution, breaks temporal patterns).
    """
    if len(equity_curve) < 20:
        return pd.DataFrame()

    rng = np.random.default_rng(seed)
    returns = equity_curve.pct_change().dropna().values
    n_days = len(returns)

    results = []
    for sim in range(n_simulations):
        sim_returns = rng.choice(returns, size=n_days, replace=True)
        equity = initial_capital
        peak = initial_capital
        max_dd = 0.0

        for r in sim_returns:
            r = float(r)
            if np.isnan(r):
                continue

            equity *= (1 + r)
            if equity <= 0:
                equity = 0
                break
            peak = max(peak, equity)
            dd = (peak - equity) / peak * 100
            max_dd = max(max_dd, dd)

        total_ret = (equity - initial_capital) / initial_capital * 100
        results.append({
            "simulation": sim + 1,
            "final_equity": equity,
            "total_return": total_ret,
            "max_drawdown": max_dd,
            "survived": equity > 0,
        })

    return pd.DataFrame(results)


def format_mc_report(results_df: pd.DataFrame, initial_capital: float) -> str:
    """Format Monte Carlo results for console output."""
    if results_df.empty:
        return "\n  MONTE CARLO ERROR: No trades to simulate\n"

    df = results_df

    # Key metrics
    median_return = df["total_return"].median()
    mean_return = df["total_return"].mean()
    median_dd = df["max_drawdown"].median()
    survival_rate = df["survived"].sum() / len(df) * 100

    # Confidence intervals
    ret_95_lo = df["total_return"].quantile(0.05)
    ret_95_hi = df["total_return"].quantile(0.95)
    ret_90_lo = df["total_return"].quantile(0.10)
    ret_90_hi = df["total_return"].quantile(0.90)

    dd_95 = df["max_drawdown"].quantile(0.95)
    dd_99 = df["max_drawdown"].quantile(0.99)

    # Blow-up analysis
    blown = (df["final_equity"] <= 0).sum()
    blowup_rate = blown / len(df) * 100

    # Drawdown buckets
    dd_buckets = {
        "> 5%": (df["max_drawdown"] >= 5).sum() / len(df) * 100,
        "> 10%": (df["max_drawdown"] >= 10).sum() / len(df) * 100,
        "> 20%": (df["max_drawdown"] >= 20).sum() / len(df) * 100,
        "> 30%": (df["max_drawdown"] >= 30).sum() / len(df) * 100,
    }

    output = []
    output.append("\n" + "=" * 65)
    output.append("  MONTE CARLO SIMULATION")
    output.append(f"  Simulations: {len(df):,} | Initial capital: ${initial_capital:,.0f}")
    output.append("=" * 65)

    output.append(f"\n  RETURN ANALYSIS")
    output.append(f"    Median return:      {median_return:>+8.2f}%")
    output.append(f"    Mean return:        {mean_return:>+8.2f}%")
    output.append(f"    90% CI:             [{ret_90_lo:>+8.2f}% , {ret_90_hi:>+8.2f}% ]")
    output.append(f"    95% CI:             [{ret_95_lo:>+8.2f}% , {ret_95_hi:>+8.2f}% ]")

    output.append(f"\n  RISK ANALYSIS")
    output.append(f"    Median max DD:      {median_dd:>8.2f}%")
    output.append(f"    VaR (95% DD):       {dd_95:>8.2f}%")
    output.append(f"    VaR (99% DD):       {dd_99:>8.2f}%")
    output.append(f"    Survival rate:      {survival_rate:>7.1f}%")

    output.append(f"\n  DRAWDOWN PROBABILITY")
    for bucket, pct in dd_buckets.items():
        bar = "#" * int(pct / 5)
        output.append(f"    DD {bucket}: {pct:>5.1f}%  {bar}")

    if blowup_rate > 0:
        output.append(f"\n  BLOW-UP RISK")
        output.append(f"    Accounts blown:     {blown} / {len(df)} ({blowup_rate:.1f}%)")
        if blowup_rate > 5:
            output.append(f"    WARNING: High blow-up risk!")
        elif blowup_rate > 1:
            output.append(f"    CAUTION: Non-trivial blow-up risk")

    output.append("=" * 65)
    return "\n".join(output)


def run_monte_carlo_from_backtest(
    strategy_name: str,
    data: pd.DataFrame,
    params: dict = None,
    n_simulations: int = 1000,
    mode: str = "shuffle",
    initial_capital: float = 10000,
    spread_pts: float = 20,
    seed: Optional[int] = None,
) -> pd.DataFrame:
    """Run a single backtest, then Monte Carlo on its trades."""
    result = run_backtest(
        strategy_name=strategy_name,
        data=data.copy(),
        initial_capital=initial_capital,
        params=params or {},
        spread_pts=spread_pts,
    )

    if not result.trades:
        print("  WARNING: No trades generated. Cannot run Monte Carlo.")
        return pd.DataFrame()

    print(f"  Base backtest: {len(result.trades)} trades, return {result.total_return:+.2f}%")

    if mode == "equity_returns":
        return bootstrap_equity_returns(
            result.equity_curve, n_simulations, initial_capital, seed
        )
    else:
        return bootstrap_trades(
            result.trades, n_simulations, mode, initial_capital, seed
        )


def main():
    parser = argparse.ArgumentParser(
        description="Monte Carlo Simulation — measure strategy risk robustness"
    )
    parser.add_argument("--strategy", "-s", help="Strategy name")
    parser.add_argument("--symbol", default="XAUUSD", help="Trading symbol")
    parser.add_argument("--period", "-p", default="2y", help="Lookback period")
    parser.add_argument("--start", help="Start date (YYYY-MM-DD)")
    parser.add_argument("--end", help="End date (YYYY-MM-DD)")
    parser.add_argument("--source", default="yfinance", choices=["mt5", "yfinance"])
    parser.add_argument("--capital", "-c", type=float, default=10000)
    parser.add_argument("--spread", type=float, default=20)
    parser.add_argument("--simulations", "-n", type=int, default=1000, help="Number of simulations")
    parser.add_argument("--mode", default="shuffle",
                        choices=["shuffle", "bootstrap", "equity_returns"],
                        help="Simulation mode")
    parser.add_argument("--seed", type=int, default=42, help="Random seed")
    parser.add_argument("--trades-file", help="CSV with trade list (skip backtest)")
    parser.add_argument("--params", help="Strategy params as JSON")
    parser.add_argument("--output", "-o", help="Output directory")

    args = parser.parse_args()

    script_dir = Path(__file__).parent.parent
    data_dir = script_dir / "data"

    # Load trades from file or run backtest
    if args.trades_file:
        # Load from CSV
        print(f"\n  Loading trades from {args.trades_file}...")
        # This is a simplified path; full CSV loading can be added later
        print("  CSV trade import not yet implemented — use --strategy to run fresh backtest")
        return
    elif args.strategy:
        # Date range
        if args.start and args.end:
            start = datetime.strptime(args.start, "%Y-%m-%d")
            end = datetime.strptime(args.end, "%Y-%m-%d")
        else:
            end = datetime.now()
            start = end - parse_period(args.period)

        print(f"\n  Loading {args.symbol} data...")
        data = load_data(args.symbol, start, end, data_dir, source=args.source)
        data.attrs["symbol"] = args.symbol
        print(f"   Loaded {len(data)} bars")

        params = json.loads(args.params) if args.params else {}
        print(f"  Strategy: {args.strategy}")
        print(f"  Mode: {args.mode} | Simulations: {args.simulations:,}")

        results_df = run_monte_carlo_from_backtest(
            strategy_name=args.strategy,
            data=data,
            params=params,
            n_simulations=args.simulations,
            mode=args.mode,
            initial_capital=args.capital,
            spread_pts=args.spread,
            seed=args.seed,
        )

        if not results_df.empty:
            report = format_mc_report(results_df, args.capital)
            print(report)

            # Save results
            output_dir = Path(args.output) if args.output else script_dir / "reports"
            output_dir.mkdir(parents=True, exist_ok=True)
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            csv_file = output_dir / f"mc_{args.strategy}_{args.symbol}_{timestamp}.csv"
            results_df.to_csv(csv_file, index=False)
            txt_file = output_dir / f"mc_{args.strategy}_{args.symbol}_{timestamp}.txt"
            with open(txt_file, "w") as f:
                f.write(report)
            print(f"  Results saved to: {csv_file}")
            print(f"  Report saved to:  {txt_file}")
    else:
        print("  Either --strategy or --trades-file is required")


if __name__ == "__main__":
    main()
