#!/usr/bin/env python3
"""
Historical Data Fetcher — MT5 (XAUUSD) + yfinance fallback
Fetch and cache price data from MetaTrader 5 terminal or Yahoo Finance.

Usage:
    python fetch_data.py --symbol XAUUSD --period 1y --source mt5
    python fetch_data.py --symbol XAUUSD --start 2023-01-01 --end 2024-01-01
"""

import argparse
import sys
from datetime import datetime, timedelta
from pathlib import Path
from typing import Optional


def parse_period(period: str) -> timedelta:
    """Parse period string like '1y', '6m', '30d', '2w'."""
    unit = period[-1].lower()
    value = int(period[:-1])

    if unit == 'y':
        return timedelta(days=value * 365)
    elif unit == 'm':
        return timedelta(days=value * 30)
    elif unit == 'd':
        return timedelta(days=value)
    elif unit == 'w':
        return timedelta(weeks=value)
    else:
        raise ValueError(f"Unknown period unit: {unit}")


def fetch_mt5(symbol: str, start: datetime, end: datetime, timeframe: str = 'D1') -> 'pd.DataFrame':
    """Fetch OHLC data from MetaTrader 5 terminal.

    Requires MT5 terminal running and logged into a broker with the symbol.
    Timeframe options: M1, M5, M15, M30, H1, H4, D1, W1, MN1
    """
    try:
        import MetaTrader5 as mt5
        import pandas as pd
    except ImportError:
        print("MetaTrader5 package not installed.")
        print("Install with: pip install MetaTrader5")
        sys.exit(1)

    # Map timeframe string to MT5 constant
    tf_map = {
        'M1': mt5.TIMEFRAME_M1,
        'M5': mt5.TIMEFRAME_M5,
        'M15': mt5.TIMEFRAME_M15,
        'M30': mt5.TIMEFRAME_M30,
        'H1': mt5.TIMEFRAME_H1,
        'H4': mt5.TIMEFRAME_H4,
        'D1': mt5.TIMEFRAME_D1,
        'W1': mt5.TIMEFRAME_W1,
        'MN1': mt5.TIMEFRAME_MN1,
    }

    if timeframe not in tf_map:
        raise ValueError(f"Unsupported timeframe: {timeframe}. Options: {list(tf_map.keys())}")

    # Initialize MT5 connection
    if not mt5.initialize():
        print("MT5 initialization failed. Make sure MetaTrader 5 is running.")
        print(f"Error: {mt5.last_error()}")
        sys.exit(1)

    # Verify symbol exists
    if not mt5.symbol_select(symbol, True):
        print(f"Symbol {symbol} not found in MT5. Available forex pairs:")
        forex = [s.name for s in mt5.symbols_get() if 'forex' in (s.path or '').lower() or s.name.startswith(('XAU', 'XAG', 'EUR', 'GBP', 'USD'))]
        print(f"  Sample: {forex[:20]}")
        mt5.shutdown()
        sys.exit(1)

    print(f"Fetching {symbol} from MT5 (timeframe={timeframe})...")

    rates = mt5.copy_rates_range(symbol, tf_map[timeframe], start, end)
    if rates is None or len(rates) == 0:
        print(f"No data returned for {symbol}. Trying copy_rates_from_pos as fallback...")
        rates = mt5.copy_rates_from_pos(symbol, tf_map[timeframe], 0, 5000)

    mt5.shutdown()

    if rates is None or len(rates) == 0:
        raise ValueError(f"No data available for {symbol} in MT5")

    df = pd.DataFrame(rates)
    df['date'] = pd.to_datetime(df['time'], unit='s')
    df.set_index('date', inplace=True)

    # Rename to standard column names
    df.rename(columns={
        'open': 'open',
        'high': 'high',
        'low': 'low',
        'close': 'close',
        'tick_volume': 'volume',
        'real_volume': 'volume',
        'spread': 'spread',
    }, inplace=True)

    # Keep only standard columns
    cols = [c for c in ['open', 'high', 'low', 'close', 'volume', 'spread'] if c in df.columns]
    df = df[cols]

    print(f"  Loaded {len(df)} bars from {df.index[0]} to {df.index[-1]}")
    return df


# Map common symbols to their yfinance equivalents
YFINANCE_SYMBOL_MAP = {
    'XAUUSD': 'GC=F',       # Gold futures (closest proxy for XAUUSD)
    'XAGUSD': 'SI=F',       # Silver futures
    'XAUUSDz': 'GC=F',      # MT5 Zero broker gold CFD
    'BTCUSD': 'BTC-USD',
    'ETHUSD': 'ETH-USD',
    'SP500': '^GSPC',
    'US30': '^DJI',
    'US100': '^IXIC',
    'USDCAD': 'USDCAD=X',
    'EURUSD': 'EURUSD=X',
    'GBPUSD': 'GBPUSD=X',
    'USDJPY': 'USDJPY=X',
}


def fetch_yfinance(symbol: str, start: datetime, end: datetime, interval: str = '1d') -> 'pd.DataFrame':
    """Fetch data from Yahoo Finance (fallback for forex/stocks/crypto)."""
    try:
        import yfinance as yf
        import pandas as pd
    except ImportError:
        print("yfinance not installed. Install with: pip install yfinance")
        sys.exit(1)

    # Use symbol mapping if available
    yf_symbol = YFINANCE_SYMBOL_MAP.get(symbol, symbol)
    if yf_symbol != symbol:
        print(f"Fetching {symbol} from Yahoo Finance (via {yf_symbol})...")
    else:
        print(f"Fetching {symbol} from Yahoo Finance...")

    ticker = yf.Ticker(yf_symbol)
    df = ticker.history(start=start, end=end, interval=interval)

    if df.empty:
        raise ValueError(f"No data returned for {symbol} (yfinance symbol: {yf_symbol})")

    df.columns = [c.lower() for c in df.columns]
    df.index.name = 'date'
    if df.index.tz is not None:
        df.index = df.index.tz_localize(None)

    print(f"  Loaded {len(df)} bars from {df.index[0]} to {df.index[-1]}")
    return df


def main():
    parser = argparse.ArgumentParser(description='Fetch historical price data')
    parser.add_argument('--symbol', '-s', default='XAUUSD', help='Trading symbol (default: XAUUSD)')
    parser.add_argument('--period', '-p', help='Lookback period (e.g., 1y, 6m, 30d)')
    parser.add_argument('--start', help='Start date (YYYY-MM-DD)')
    parser.add_argument('--end', help='End date (YYYY-MM-DD)')
    parser.add_argument('--interval', '-i', default='1d', help='Data interval: D1, H4, H1, M15 (default: D1)')
    parser.add_argument('--source', default='mt5', choices=['mt5', 'yfinance'],
                        help='Data source: mt5 (default) or yfinance')
    parser.add_argument('--output', '-o', help='Output directory')

    args = parser.parse_args()

    # Determine date range
    if args.start and args.end:
        start = datetime.strptime(args.start, '%Y-%m-%d')
        end = datetime.strptime(args.end, '%Y-%m-%d')
    elif args.period:
        end = datetime.now()
        start = end - parse_period(args.period)
    else:
        end = datetime.now()
        start = end - timedelta(days=365)  # 1 year default

    # Fetch data
    if args.source == 'mt5':
        # Map -i to MT5 timeframe names
        interval_map = {
            '1d': 'D1', 'D1': 'D1', 'daily': 'D1',
            '4h': 'H4', 'H4': 'H4',
            '1h': 'H1', 'H1': 'H1',
            '15m': 'M15', 'M15': 'M15',
            '30m': 'M30', 'M30': 'M30',
            '5m': 'M5', 'M5': 'M5',
            '1w': 'W1', 'W1': 'W1',
            '1mn': 'MN1', 'MN1': 'MN1',
        }
        mt5_tf = interval_map.get(args.interval, 'D1')
        df = fetch_mt5(args.symbol, start, end, timeframe=mt5_tf)
    else:
        df = fetch_yfinance(args.symbol, start, end, args.interval)

    # Save to file
    script_dir = Path(__file__).parent.parent
    output_dir = Path(args.output) if args.output else script_dir / 'data'
    output_dir.mkdir(parents=True, exist_ok=True)

    safe_sym = args.symbol.replace('/', '_').replace('-', '_')
    filename = f"{safe_sym}_{args.interval}.csv"
    output_file = output_dir / filename

    df.to_csv(output_file)
    print(f"\n✅ Data saved to: {output_file}")
    print(f"   Bars: {len(df)}")
    print(f"   Range: {df.index[0]} to {df.index[-1]}")
    print(f"   Columns: {list(df.columns)}")


if __name__ == '__main__':
    main()
