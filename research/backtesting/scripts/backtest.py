#!/usr/bin/env python3
"""
Main Backtesting Engine  Alpha Logic Hub
Run trading strategy backtests on XAUUSD and forex pairs.

Connects to MetaTrader 5 for real data. Supports 8 strategies.

Usage:
    python backtest.py --strategy sma_crossover --symbol XAUUSD --period 1y
    python backtest.py --strategy rsi_reversal --symbol XAUUSD --start 2023-01-01 --end 2024-01-01 --spread 20
"""

import argparse
import json
import sys
from pathlib import Path
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional

import pandas as pd
import numpy as np

try:
    import yaml
except ImportError:
    yaml = None

# Add scripts directory to path
sys.path.insert(0, str(Path(__file__).parent))

from strategies import get_strategy, list_strategies, Signal
from metrics import Trade, BacktestResult, calculate_all_metrics, format_results
from fetch_data import parse_period, fetch_mt5, fetch_yfinance


def load_settings(skill_dir: Path) -> dict:
    """Load settings from config/settings.yaml."""
    settings_file = skill_dir / 'config' / 'settings.yaml'
    if yaml is not None and settings_file.exists():
        with open(settings_file) as f:
            return yaml.safe_load(f) or {}
    return {}


def load_data(symbol: str, start: datetime, end: datetime, data_dir: Path,
              source: str = 'mt5', interval: str = '1d') -> pd.DataFrame:
    """Load price data: MT5 (default) or yfinance fallback."""

    # Map common intervals
    mt5_tf_map = {
        '1d': 'D1', 'D1': 'D1', 'daily': 'D1',
        '4h': 'H4', 'H4': 'H4',
        '1h': 'H1', 'H1': 'H1',
    }

    safe_sym = symbol.replace('/', '_').replace('-', '_')
    cache_file = data_dir / f"{safe_sym}_{interval}.csv"

    # Try loading from cache first
    if cache_file.exists():
        df = pd.read_csv(cache_file, parse_dates=['date'], index_col='date')
        if df.index.tz is not None:
            df.index = df.index.tz_localize(None)
        df = df[(df.index >= pd.Timestamp(start)) & (df.index <= pd.Timestamp(end))]
        if len(df) > 0:
            print(f"  Loaded {len(df)} bars from cache: {cache_file.name}")
            if 'spread' in df.columns:
                print(f"  Avg spread: {df['spread'].mean():.1f} pts")
            return df

    # Fetch from source
    if source == 'mt5':
        mt5_tf = mt5_tf_map.get(interval, 'D1')
        df = fetch_mt5(symbol, start, end, timeframe=mt5_tf)
    else:
        df = fetch_yfinance(symbol, start, end, interval)

    # Cache the data
    if len(df) > 0:
        data_dir.mkdir(parents=True, exist_ok=True)
        df.to_csv(cache_file)
        print(f"  Cached to: {cache_file.name}")

    return df


def run_backtest(
    strategy_name: str,
    data: pd.DataFrame,
    initial_capital: float = 10000,
    params: Dict[str, Any] = None,
    commission: float = 0.0,
    spread_pts: float = 0.0,
    risk_settings: Dict[str, Any] = None,
) -> BacktestResult:
    """Run a backtest on historical data.

    Adapted for forex: spread_pts adds per-trade cost in points.
    For XAUUSD, 1 point = 0.01 (price is like 2350.00).
    """
    params = params or {}
    risk_settings = risk_settings or {}
    strategy = get_strategy(strategy_name)

    stop_loss = risk_settings.get('stop_loss')
    take_profit = risk_settings.get('take_profit')
    max_position_size = risk_settings.get('max_position_size', 0.95)

    trades: List[Trade] = []
    equity = [initial_capital]
    cash = initial_capital
    position = None
    position_size = 0

    data_len = len(data)
    lookback = strategy.lookback

    # Use dynamic lookback if strategy has min_bars method
    if hasattr(strategy, 'min_bars') and callable(strategy.min_bars):
        try:
            lookback = max(lookback, strategy.min_bars(params))
        except Exception:
            pass

    if lookback >= data_len:
        # Not enough data — return empty result
        result = BacktestResult(
            strategy=strategy_name,
            symbol=data.attrs.get('symbol', 'Unknown'),
            start_date=data.index[0] if len(data) > 0 else None,
            end_date=data.index[-1] if len(data) > 0 else None,
            initial_capital=initial_capital,
            final_capital=initial_capital,
            trades=[],
            equity_curve=pd.Series([initial_capital], index=data.index[:1] if len(data) > 0 else [0]),
            parameters=params,
        )
        return calculate_all_metrics(result)

    for i in range(lookback, data_len):
        slice_data = data.iloc[:i+1].copy()
        current_bar = data.iloc[i]
        current_price = current_bar['close']
        current_time = data.index[i]

        # Apply spread as per-trade cost (in price units)
        # spread_pts=20 on XAUUSD means 20 * 0.01 = 0.20 price units per side
        spread_cost = spread_pts * 0.01 if spread_pts > 0 else 0.0

        # Generate signals
        signal = strategy.generate_signals(slice_data, params)

        # --- Check stop-loss / take-profit ---
        force_exit = False
        if position is not None:
            if position['direction'] == 'long':
                unrealized_pnl_pct = (current_price - position['entry_price']) / position['entry_price']
            else:
                unrealized_pnl_pct = (position['entry_price'] - current_price) / position['entry_price']

            if stop_loss is not None and unrealized_pnl_pct <= -stop_loss:
                force_exit = True
            elif take_profit is not None and unrealized_pnl_pct >= take_profit:
                force_exit = True

        # --- Exit logic ---
        if position is not None and (signal.exit or force_exit):
            if position['direction'] == 'long':
                # Sell at bid = current_price - spread/2
                exit_price = current_price - (spread_cost / 2)
                exit_value = position_size * exit_price
                cash += exit_value
            else:  # short
                # Buy back at ask = current_price + spread/2
                exit_price = current_price + (spread_cost / 2)
                pnl = position_size * (position['entry_price'] - exit_price)
                cash += position['collateral'] + pnl

            trade = Trade(
                entry_time=position['entry_time'],
                exit_time=current_time,
                entry_price=position['entry_price'],
                exit_price=exit_price,
                direction=position['direction'],
                size=position['size'],
            )
            trades.append(trade)
            position = None
            position_size = 0

        # --- Entry logic ---
        # If we have a position and signal reverses direction, exit first
        if signal.entry and position is not None and signal.direction != position['direction']:
            # Close current position
            if position['direction'] == 'long':
                exit_price = current_price - (spread_cost / 2)
                cash += position_size * exit_price
            else:
                exit_price = current_price + (spread_cost / 2)
                pnl = position_size * (position['entry_price'] - exit_price)
                cash += position['collateral'] + pnl

            trade = Trade(
                entry_time=position['entry_time'],
                exit_time=current_time,
                entry_price=position['entry_price'],
                exit_price=exit_price,
                direction=position['direction'],
                size=position['size'],
            )
            trades.append(trade)
            position = None
            position_size = 0

        if signal.entry and position is None:
            if signal.direction == 'long':
                entry_price = current_price + (spread_cost / 2)  # Buy at ask
                position_value = cash * max_position_size
                position_size = position_value / entry_price
                cash -= position_value

                position = {
                    'entry_time': current_time,
                    'entry_price': entry_price,
                    'direction': 'long',
                    'size': position_size,
                }
            else:  # short
                entry_price = current_price - (spread_cost / 2)  # Sell at bid
                position_value = cash * max_position_size
                position_size = position_value / entry_price  # notional
                cash -= position_value

                position = {
                    'entry_time': current_time,
                    'entry_price': entry_price,
                    'direction': 'short',
                    'size': position_size,
                    'collateral': position_value,
                }

        # Calculate equity
        if position is not None:
            if position['direction'] == 'long':
                equity.append(cash + position_size * current_price)
            else:
                equity.append(cash + position['collateral'] + position_size * (position['entry_price'] - current_price))
        else:
            equity.append(cash)

    # Close open position at end
    if position is not None:
        if position['direction'] == 'long':
            final_price = data.iloc[-1]['close'] - (spread_cost / 2)
            exit_value = position_size * final_price
            cash += exit_value
        else:
            final_price = data.iloc[-1]['close'] + (spread_cost / 2)
            pnl = position_size * (position['entry_price'] - final_price)
            cash += position['collateral'] + pnl

        trade = Trade(
            entry_time=position['entry_time'],
            exit_time=data.index[-1],
            entry_price=position['entry_price'],
            exit_price=final_price,
            direction=position['direction'],
            size=position['size'],
        )
        trades.append(trade)
        equity[-1] = cash

    eq_index = data.index[max(0, lookback-1):]
    if len(equity) != len(eq_index):
        eq_index = eq_index[:len(equity)]
    equity_curve = pd.Series(equity, index=eq_index)

    result = BacktestResult(
        strategy=strategy_name,
        symbol=data.attrs.get('symbol', 'Unknown'),
        start_date=data.index[0],
        end_date=data.index[-1],
        initial_capital=initial_capital,
        final_capital=equity[-1],
        trades=trades,
        equity_curve=equity_curve,
        parameters=params,
    )

    result = calculate_all_metrics(result)
    return result


def save_results(result: BacktestResult, output_dir: Path) -> None:
    """Save backtest results to files."""
    output_dir.mkdir(parents=True, exist_ok=True)

    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    safe_sym = result.symbol.replace('/', '_').replace('-', '_')
    base_name = f"{result.strategy}_{safe_sym}_{timestamp}"

    # Save summary
    summary_file = output_dir / f"{base_name}_summary.txt"
    with open(summary_file, 'w') as f:
        f.write(format_results(result))
    print(f"  Summary: {summary_file}")

    # Save trades to CSV
    if result.trades:
        trades_file = output_dir / f"{base_name}_trades.csv"
        trades_df = pd.DataFrame([
            {
                'entry_time': t.entry_time,
                'exit_time': t.exit_time,
                'entry_price': t.entry_price,
                'exit_price': t.exit_price,
                'direction': t.direction,
                'size': t.size,
                'pnl': t.pnl,
                'pnl_pct': t.pnl_pct,
                'duration': t.duration,
            }
            for t in result.trades
        ])
        trades_df.to_csv(trades_file, index=False)
        print(f"  Trades: {trades_file}")

    # Save equity curve
    equity_file = output_dir / f"{base_name}_equity.csv"
    result.equity_curve.to_csv(equity_file, header=['equity'])
    print(f"  Equity curve: {equity_file}")

    # Generate chart
    try:
        import matplotlib.pyplot as plt
        import matplotlib.dates as mdates

        fig, axes = plt.subplots(2, 1, figsize=(12, 8), gridspec_kw={'height_ratios': [3, 1]})

        # Equity curve
        axes[0].plot(result.equity_curve.index, result.equity_curve.values,
                     label='Portfolio Value', color='#0066cc', linewidth=1.5)
        axes[0].axhline(y=result.initial_capital, color='gray', linestyle='--', alpha=0.5, label=f'Initial ${result.initial_capital:,.0f}')
        axes[0].set_title(f'{result.strategy.upper()}  {result.symbol}  |  Return: {result.total_return:+.1f}%  Sharpe: {result.sharpe_ratio:.2f}')
        axes[0].set_ylabel('Portfolio Value ($)')
        axes[0].legend(loc='upper left')
        axes[0].grid(True, alpha=0.3)

        # Drawdown
        rolling_max = result.equity_curve.expanding().max()
        drawdown = (result.equity_curve - rolling_max) / rolling_max * 100
        axes[1].fill_between(drawdown.index, drawdown.values, 0, alpha=0.5, color='#cc3333')
        axes[1].set_title(f'Drawdown  |  Max: {result.max_drawdown:.1f}%  ({result.max_drawdown_duration} days)')
        axes[1].set_ylabel('Drawdown (%)')
        axes[1].set_xlabel('Date')
        axes[1].grid(True, alpha=0.3)

        plt.tight_layout()
        chart_file = output_dir / f"{base_name}_chart.png"
        plt.savefig(chart_file, dpi=120, bbox_inches='tight')
        plt.close()
        print(f"  Chart: {chart_file}")
    except ImportError:
        pass

    print(f" Results saved to: {output_dir}")


def main():
    parser = argparse.ArgumentParser(description='Alpha Logic Hub  Backtest Trading Strategies (XAUUSD)')
    parser.add_argument('--strategy', '-s', required=True, help='Strategy name')
    parser.add_argument('--symbol', default='XAUUSD', help='Trading symbol (default: XAUUSD)')
    parser.add_argument('--period', '-p', help='Lookback period (e.g., 1y, 6m, 30d)')
    parser.add_argument('--start', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end', help='End date (YYYY-MM-DD)')
    parser.add_argument('--capital', '-c', type=float, default=None, help='Initial capital')
    parser.add_argument('--params', help='Strategy parameters as JSON')
    parser.add_argument('--spread', type=float, default=None,
                        help='Spread in points (XAUUSD typical: 15-30). 20 = $0.20 per side')
    parser.add_argument('--commission', type=float, default=None, help='Commission per trade as fraction')
    parser.add_argument('--source', default='mt5', choices=['mt5', 'yfinance'], help='Data source')
    parser.add_argument('--interval', default='1d', help='Data interval: D1, H4, H1')
    parser.add_argument('--output', '-o', help='Output directory (default: reports/)')
    parser.add_argument('--list', action='store_true', help='List available strategies')
    parser.add_argument('--quiet', '-q', action='store_true', help='Minimal output')

    args = parser.parse_args()

    if args.list:
        print("Available strategies:")
        for name, desc in list_strategies().items():
            print(f"  {name}: {desc}")
        return

    # Load settings
    script_dir = Path(__file__).parent.parent
    settings = load_settings(script_dir)
    bt_settings = settings.get('backtest', {})
    risk_settings = settings.get('risk', {})

    capital = args.capital if args.capital is not None else bt_settings.get('default_capital', 10000)
    spread = args.spread if args.spread is not None else bt_settings.get('spread_points', 20)
    commission = args.commission if args.commission is not None else bt_settings.get('commission', 0.0)

    # Date range
    if args.start and args.end:
        start = datetime.strptime(args.start, '%Y-%m-%d')
        end = datetime.strptime(args.end, '%Y-%m-%d')
    elif args.period:
        end = datetime.now()
        start = end - parse_period(args.period)
    else:
        end = datetime.now()
        start = end - timedelta(days=365)

    # Parse params
    params = json.loads(args.params) if args.params else {}

    # Directories
    data_dir = script_dir / 'data'
    output_dir = Path(args.output) if args.output else script_dir / 'reports'

    # Load data
    if not args.quiet:
        print(f"\nLoading {args.symbol} from {args.source.upper()} | {start.date()} -> {end.date()}")
        print(f"  Strategy: {args.strategy} | Capital: ${capital:,.0f} | Spread: {spread} pts")

    data = load_data(args.symbol, start, end, data_dir, source=args.source, interval=args.interval)
    data.attrs['symbol'] = args.symbol

    if len(data) < 50:
        print(f" Insufficient data: {len(data)} bars, need  50")
        sys.exit(1)

    if not args.quiet:
        print(f"   Bars: {len(data)} | Range: {data.index[0].date()}  {data.index[-1].date()}")

    # Run backtest
    if not args.quiet:
        print(f"  Running backtest with {args.strategy}...")

    result = run_backtest(
        strategy_name=args.strategy,
        data=data,
        initial_capital=capital,
        params=params,
        commission=commission,
        spread_pts=spread,
        risk_settings=risk_settings,
    )

    # Print results
    print(format_results(result))

    # Save
    save_results(result, output_dir)


if __name__ == '__main__':
    main()
