#!/usr/bin/env python3
"""
Trading Strategy Definitions — Alpha Logic Hub
Each strategy implements generate_signals() returning entry/exit signals.
All strategies work with any OHLC data (forex, stocks, crypto).
"""

import numpy as np
import pandas as pd
from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from dataclasses import dataclass


@dataclass
class Signal:
    """Trading signal with entry/exit information."""
    entry: bool = False
    exit: bool = False
    direction: str = "long"   # "long" or "short"
    strength: float = 1.0     # Signal strength 0-1


class Strategy(ABC):
    """Base class for all trading strategies."""
    name: str = "base"
    lookback: int = 1

    @abstractmethod
    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        pass

    def validate_params(self, params: Dict[str, Any]) -> Dict[str, Any]:
        return params


class SMAcrossover(Strategy):
    """Simple Moving Average Crossover — Golden cross / Death cross."""
    name = "sma_crossover"
    lookback = 200

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        params = self.validate_params(params)
        fast = params.get("fast_period", 20)
        slow = params.get("slow_period", 50)

        if len(data) < slow + 1:
            return Signal()

        close = data["close"]
        fast_ma = close.rolling(window=fast).mean()
        slow_ma = close.rolling(window=slow).mean()

        curr_fast, prev_fast = fast_ma.iloc[-1], fast_ma.iloc[-2]
        curr_slow, prev_slow = slow_ma.iloc[-1], slow_ma.iloc[-2]

        # Golden cross
        if prev_fast <= prev_slow and curr_fast > curr_slow:
            return Signal(entry=True, direction="long")

        # Death cross
        if prev_fast >= prev_slow and curr_fast < curr_slow:
            return Signal(exit=True)

        return Signal()


class EMAcrossover(Strategy):
    """Exponential Moving Average Crossover."""
    name = "ema_crossover"
    lookback = 200

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        fast = params.get("fast_period", 12)
        slow = params.get("slow_period", 26)
        if len(data) < slow + 1:
            return Signal()

        close = data["close"]
        fast_ema = close.ewm(span=fast, adjust=False).mean()
        slow_ema = close.ewm(span=slow, adjust=False).mean()

        curr_fast, prev_fast = fast_ema.iloc[-1], fast_ema.iloc[-2]
        curr_slow, prev_slow = slow_ema.iloc[-1], slow_ema.iloc[-2]

        if prev_fast <= prev_slow and curr_fast > curr_slow:
            return Signal(entry=True, direction="long")
        if prev_fast >= prev_slow and curr_fast < curr_slow:
            return Signal(exit=True)
        return Signal()


class RSIreversal(Strategy):
    """RSI Overbought/Oversold Reversal — long when RSI exits oversold, short when exits overbought."""
    name = "rsi_reversal"
    lookback = 14

    def _calculate_rsi(self, close: pd.Series, period: int) -> pd.Series:
        delta = close.diff()
        gain = (delta.where(delta > 0, 0)).rolling(window=period).mean()
        loss = (-delta.where(delta < 0, 0)).rolling(window=period).mean()
        rs = gain / loss
        return 100 - (100 / (1 + rs))

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        period = params.get("period", 14)
        overbought = params.get("overbought", 70)
        oversold = params.get("oversold", 30)
        if len(data) < period + 1:
            return Signal()

        rsi = self._calculate_rsi(data["close"], period)
        curr_rsi, prev_rsi = rsi.iloc[-1], rsi.iloc[-2]

        if prev_rsi <= oversold and curr_rsi > oversold:
            return Signal(entry=True, exit=True, direction="long",
                          strength=min(1.0, (oversold - prev_rsi) / 10))
        if prev_rsi >= overbought and curr_rsi < overbought:
            return Signal(entry=True, exit=True, direction="short",
                          strength=min(1.0, (prev_rsi - overbought) / 10))
        return Signal()


class MACD(Strategy):
    """MACD Signal Line Crossover — long/short on MACD cross."""
    name = "macd"
    lookback = 35

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        fast = params.get("fast", 12)
        slow = params.get("slow", 26)
        signal_period = params.get("signal", 9)
        if len(data) < slow + signal_period:
            return Signal()

        close = data["close"]
        fast_ema = close.ewm(span=fast, adjust=False).mean()
        slow_ema = close.ewm(span=slow, adjust=False).mean()
        macd_line = fast_ema - slow_ema
        signal_line = macd_line.ewm(span=signal_period, adjust=False).mean()

        curr_macd, prev_macd = macd_line.iloc[-1], macd_line.iloc[-2]
        curr_sig, prev_sig = signal_line.iloc[-1], signal_line.iloc[-2]

        if prev_macd <= prev_sig and curr_macd > curr_sig:
            return Signal(entry=True, exit=True, direction="long")
        if prev_macd >= prev_sig and curr_macd < curr_sig:
            return Signal(entry=True, exit=True, direction="short")
        return Signal()


class BollingerBands(Strategy):
    """Bollinger Bands Mean Reversion — touches lower/upper band, exit at middle."""
    name = "bollinger_bands"
    lookback = 20

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        period = params.get("period", 20)
        std_dev = params.get("std_dev", 2.0)
        if len(data) < period:
            return Signal()

        close = data["close"]
        sma = close.rolling(window=period).mean()
        std = close.rolling(window=period).std()
        upper = sma + (std * std_dev)
        lower = sma - (std * std_dev)

        curr_c = close.iloc[-1]
        prev_c = close.iloc[-2]

        if prev_c >= lower.iloc[-2] and curr_c < lower.iloc[-1]:
            return Signal(entry=True, exit=True, direction="long")
        if prev_c <= upper.iloc[-2] and curr_c > upper.iloc[-1]:
            return Signal(entry=True, exit=True, direction="short")

        curr_mid = sma.iloc[-1]
        prev_mid = sma.iloc[-2]
        if (prev_c < prev_mid and curr_c >= curr_mid) or \
           (prev_c > prev_mid and curr_c <= curr_mid):
            return Signal(exit=True)

        return Signal()


class Breakout(Strategy):
    """Price Breakout — buy above recent high, sell below recent low."""
    name = "breakout"
    lookback = 20

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        lb = params.get("lookback", 20)
        threshold = params.get("threshold", 0.0)
        if len(data) < lb + 1:
            return Signal()

        high = data["high"].iloc[-lb-1:-1]
        low = data["low"].iloc[-lb-1:-1]
        curr_close = data["close"].iloc[-1]

        resistance = high.max() * (1 + threshold / 100)
        support = low.min() * (1 - threshold / 100)

        if curr_close > resistance:
            return Signal(entry=True, direction="long")
        if curr_close < support:
            return Signal(exit=True)
        return Signal()


class MeanReversion(Strategy):
    """Mean Reversion via Z-Score — long below -2σ, short above +2σ, exit at 0."""
    name = "mean_reversion"
    lookback = 20

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        period = params.get("period", 20)
        z_threshold = params.get("z_threshold", 2.0)
        if len(data) < period:
            return Signal()

        close = data["close"]
        sma = close.rolling(window=period).mean()
        std = close.rolling(window=period).std()

        if std.iloc[-1] == 0 or std.iloc[-2] == 0:
            return Signal()

        z = (close.iloc[-1] - sma.iloc[-1]) / std.iloc[-1]
        prev_z = (close.iloc[-2] - sma.iloc[-2]) / std.iloc[-2]

        if z < -z_threshold and prev_z >= -z_threshold:
            return Signal(entry=True, exit=True, direction="long",
                          strength=min(1.0, abs(z) / 3))
        if z > z_threshold and prev_z <= z_threshold:
            return Signal(entry=True, exit=True, direction="short",
                          strength=min(1.0, abs(z) / 3))
        if (prev_z < 0 and z >= 0) or (prev_z > 0 and z <= 0):
            return Signal(exit=True)
        return Signal()


class Momentum(Strategy):
    """Rate of Change Momentum — buy when ROC exceeds threshold."""
    name = "momentum"
    lookback = 14

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        period = params.get("period", 14)
        threshold = params.get("threshold", 5.0)
        if len(data) < period + 1:
            return Signal()

        close = data["close"]
        roc = ((close.iloc[-1] - close.iloc[-period]) / close.iloc[-period]) * 100
        prev_roc = ((close.iloc[-2] - close.iloc[-period-1]) / close.iloc[-period-1]) * 100

        if prev_roc <= threshold and roc > threshold:
            return Signal(entry=True, direction="long")
        if prev_roc >= 0 and roc < 0:
            return Signal(exit=True)
        return Signal()


class SupplyDemand(Strategy):
    """Supply and Demand Zone Strategy.

    Identifies origin blocks (consolidation ranges) followed by strong
    impulsive moves. Scans ALL available history once to build a zone
    map, then enters when price revisits a zone with rejection.
    """
    name = "supply_demand"
    lookback = 5  # minimum needed before signal check

    def __init__(self):
        self._scanned_len = 0
        self._cached_demand: list = []
        self._cached_supply: list = []

    def _scan_zones(self, data: pd.DataFrame, params: dict) -> tuple:
        """Scan the dataset for supply/demand zones. Only scans new bars.

        Since backtest.py passes slice_data = data.iloc[:i+1].copy() on each
        iteration (a NEW DataFrame every time), we track the last scanned
        length and only process new bars.
        """
        n = len(data)
        if n <= self._scanned_len:
            return self._cached_demand, self._cached_supply
        if n < 10:
            return self._cached_demand, self._cached_supply

        min_impulse_pct = params.get("min_impulse_pct", 0.8)
        min_cons_bars = params.get("min_cons_bars", 3)
        end = n
        start = max(self._scanned_len - min_cons_bars - 3, 0)  # overlap for continuity

        closes = data["close"].values.astype(float)
        highs = data["high"].values.astype(float)
        lows = data["low"].values.astype(float)
        opens = data["open"].values.astype(float)
        atr = float(np.mean(highs[:end] - lows[:end]))
        if atr == 0:
            return self._cached_demand, self._cached_supply

        i = start + min_cons_bars
        while i < end - 2:
            if i - min_cons_bars < 0:
                i += 1
                continue
            block_high = float(np.max(highs[i-min_cons_bars:i+1]))
            block_low = float(np.min(lows[i-min_cons_bars:i+1]))
            block_range = block_high - block_low
            avg_body = float(np.mean(np.abs(closes[i-min_cons_bars:i+1] - opens[i-min_cons_bars:i+1])))

            if block_range < 3.0 * atr and avg_body < 0.6 * atr:
                impulse_high = float(np.max(highs[i+1:min(i+4, end)]))
                impulse_low = float(np.min(lows[i+1:min(i+4, end)]))
                move_up = (impulse_high - block_high) / block_high * 100
                move_down = (block_low - impulse_low) / block_low * 100

                if move_up > min_impulse_pct:
                    strength = min(1.0, move_up / (min_impulse_pct * 3))
                    self._cached_demand.append((block_high, block_low, strength, i))
                    i += 3
                    continue
                if move_down > min_impulse_pct:
                    strength = min(1.0, move_down / (min_impulse_pct * 3))
                    self._cached_supply.append((block_high, block_low, strength, i))
                    i += 3
                    continue
            i += 1

        self._scanned_len = end
        return self._cached_demand, self._cached_supply
        min_impulse_pct = params.get("min_impulse_pct", 0.8)
        min_cons_bars = params.get("min_cons_bars", 3)

        closes = data["close"].values.astype(float)
        highs = data["high"].values.astype(float)
        lows = data["low"].values.astype(float)
        opens = data["open"].values.astype(float)
        n = len(closes)

        demand_zones = []
        supply_zones = []
        atr = float(np.mean(highs - lows))
        if atr == 0:
            return demand_zones, supply_zones

        i = min_cons_bars
        while i < n - 2:
            block_high = float(np.max(highs[i-min_cons_bars:i+1]))
            block_low = float(np.min(lows[i-min_cons_bars:i+1]))
            block_range = block_high - block_low
            avg_body = float(np.mean(np.abs(closes[i-min_cons_bars:i+1] - opens[i-min_cons_bars:i+1])))

            if block_range < 3.0 * atr and avg_body < 0.6 * atr:
                impulse_high = float(np.max(highs[i+1:min(i+4, n)]))
                impulse_low = float(np.min(lows[i+1:min(i+4, n)]))
                move_up = (impulse_high - block_high) / block_high * 100
                move_down = (block_low - impulse_low) / block_low * 100

                if move_up > min_impulse_pct:
                    strength = min(1.0, move_up / (min_impulse_pct * 3))
                    demand_zones.append((block_high, block_low, strength, i))
                    i += 3
                    continue
                if move_down > min_impulse_pct:
                    strength = min(1.0, move_down / (min_impulse_pct * 3))
                    supply_zones.append((block_high, block_low, strength, i))
                    i += 3
                    continue
            i += 1

        return demand_zones, supply_zones

    def generate_signals(self, data: pd.DataFrame, params: Dict[str, Any]) -> Signal:
        demand_zones, supply_zones = self._scan_zones(data, params)

        if not demand_zones and not supply_zones:
            return Signal()

        curr_close = float(data["close"].iloc[-1])
        curr_high = float(data["high"].iloc[-1])
        curr_low = float(data["low"].iloc[-1])

        # -- Demand zones (support / buy) --
        # In a bull trend price is usually above old demand zones.
        # We wait for a retracement into the zone (within ~5% of zone top).
        # Closer / stronger zones are checked first.
        recent_demand = sorted(
            [z for z in demand_zones if z[3] >= len(data) - 200],
            key=lambda z: (z[2], -z[3]), reverse=True
        )
        for zone_high, zone_low, strength, _idx in recent_demand:
            zone_size = zone_high - zone_low
            if zone_size <= 0:
                continue
            # How far above the zone are we? (0 = at zone_high, positive = above)
            dist_above = (curr_low - zone_high) / zone_size
            if dist_above > 2.5:
                continue  # too far above to be a retracement

            # Entry A: price dipped INTO the zone and closed back above
            if curr_low <= zone_high and curr_close > zone_high:
                return Signal(entry=True, direction="long", strength=strength)
            # Entry B: inside zone, bullish close (near bottom, current up from low)
            if curr_low <= zone_high and curr_close > curr_low:
                pos_in_zone = (curr_close - zone_low) / zone_size
                if pos_in_zone < 0.5:
                    return Signal(entry=True, direction="long",
                                  strength=strength * 0.8)
            # Entry C: price wicks into the zone (long lower shadow)
            body = abs(curr_close - data["open"].iloc[-1])
            lower_wick = min(curr_close, data["open"].iloc[-1]) - curr_low
            if curr_low <= zone_high and lower_wick > body * 1.5 and lower_wick > zone_size * 0.3:
                return Signal(entry=True, direction="long",
                              strength=strength * 0.9)

        # -- Supply zones (resistance / sell) --
        # In a bull trend, supply zones are tested from below.
        # We check if price approaches an old supply zone.
        recent_supply = sorted(
            [z for z in supply_zones if z[3] >= len(data) - 200],
            key=lambda z: (z[2], z[3]), reverse=True
        )
        for zone_high, zone_low, strength, _idx in recent_supply:
            zone_size = zone_high - zone_low
            if zone_size <= 0:
                continue
            # How far below the zone are we? (0 = at zone_low, negative = below)
            dist_below = (zone_low - curr_high) / zone_size
            if dist_below > 2.5:
                continue  # too far below

            # Entry A: price entered zone from below and closed back below
            if curr_high >= zone_low and curr_close < zone_low:
                return Signal(entry=True, direction="short", strength=strength)
            # Entry B: inside zone, bearish close (near top, current down from high)
            if curr_high >= zone_low and curr_close < curr_high:
                pos_in_zone = (zone_high - curr_close) / zone_size
                if pos_in_zone < 0.5:
                    return Signal(entry=True, direction="short",
                                  strength=strength * 0.8)
            # Entry C: upper wick into zone
            body = abs(curr_close - data["open"].iloc[-1])
            upper_wick = curr_high - max(curr_close, data["open"].iloc[-1])
            if curr_high >= zone_low and upper_wick > body * 1.5 and upper_wick > zone_size * 0.3:
                return Signal(entry=True, direction="short",
                              strength=strength * 0.9)

        return Signal()


# Strategy registry
STRATEGIES = {
    "sma_crossover": SMAcrossover(),
    "ema_crossover": EMAcrossover(),
    "rsi_reversal": RSIreversal(),
    "macd": MACD(),
    "bollinger_bands": BollingerBands(),
    "breakout": Breakout(),
    "mean_reversion": MeanReversion(),
    "momentum": Momentum(),
    "supply_demand": SupplyDemand(),
}


def get_strategy(name: str) -> Strategy:
    if name not in STRATEGIES:
        raise ValueError(f"Unknown strategy: {name}. Available: {list(STRATEGIES.keys())}")
    return STRATEGIES[name]


def list_strategies() -> Dict[str, str]:
    return {name: strategy.__doc__.split('\n')[0] for name, strategy in STRATEGIES.items()}
