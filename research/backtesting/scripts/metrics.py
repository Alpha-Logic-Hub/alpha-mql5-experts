#!/usr/bin/env python3
"""
Performance and Risk Metrics  Alpha Logic Hub
Sharpe, Sortino, Calmar, VaR, CVaR, drawdown, trade statistics.
All metrics are annualized where appropriate.
"""

import numpy as np
import pandas as pd
from typing import List, Dict, Any
from dataclasses import dataclass, field


@dataclass
class Trade:
    """Represents a completed trade."""
    entry_time: pd.Timestamp
    exit_time: pd.Timestamp
    entry_price: float
    exit_price: float
    direction: str
    size: float
    pnl: float = 0.0
    pnl_pct: float = 0.0
    duration: pd.Timedelta = None

    def __post_init__(self):
        if self.direction == "long":
            self.pnl = (self.exit_price - self.entry_price) * self.size
            self.pnl_pct = (self.exit_price - self.entry_price) / self.entry_price * 100
        else:
            self.pnl = (self.entry_price - self.exit_price) * self.size
            self.pnl_pct = (self.entry_price - self.exit_price) / self.entry_price * 100
        self.duration = self.exit_time - self.entry_time


@dataclass
class BacktestResult:
    """Complete backtest results with all computed metrics."""
    strategy: str
    symbol: str
    start_date: pd.Timestamp
    end_date: pd.Timestamp
    initial_capital: float
    final_capital: float
    trades: List[Trade]
    equity_curve: pd.Series
    parameters: Dict[str, Any]

    total_return: float = 0.0
    cagr: float = 0.0
    sharpe_ratio: float = 0.0
    sortino_ratio: float = 0.0
    calmar_ratio: float = 0.0
    max_drawdown: float = 0.0
    max_drawdown_duration: int = 0
    volatility: float = 0.0
    var_95: float = 0.0
    cvar_95: float = 0.0
    ulcer_index: float = 0.0
    total_trades: int = 0
    win_rate: float = 0.0
    profit_factor: float = 0.0
    avg_win: float = 0.0
    avg_loss: float = 0.0
    expectancy: float = 0.0
    max_consecutive_wins: int = 0
    max_consecutive_losses: int = 0
    avg_trade_duration: str = ""


def calculate_returns(equity_curve: pd.Series) -> pd.Series:
    return equity_curve.pct_change().dropna()


def calculate_total_return(initial: float, final: float) -> float:
    return ((final - initial) / initial) * 100


def calculate_cagr(initial: float, final: float, years: float) -> float:
    if years <= 0 or initial <= 0:
        return 0.0
    return ((final / initial) ** (1 / years) - 1) * 100


def calculate_sharpe_ratio(returns: pd.Series, risk_free_rate: float = 0.02) -> float:
    if len(returns) < 2 or returns.std() == 0:
        return 0.0
    annual_return = returns.mean() * 252
    annual_vol = returns.std() * np.sqrt(252)
    return (annual_return - risk_free_rate) / annual_vol if annual_vol > 0 else 0.0


def calculate_sortino_ratio(returns: pd.Series, risk_free_rate: float = 0.02) -> float:
    if len(returns) < 2:
        return 0.0
    downside = returns[returns < 0]
    if len(downside) == 0 or downside.std() == 0:
        return float('inf') if returns.mean() > 0 else 0.0
    annual_return = returns.mean() * 252
    downside_std = downside.std() * np.sqrt(252)
    return (annual_return - risk_free_rate) / downside_std if downside_std > 0 else 0.0


def calculate_max_drawdown(equity_curve: pd.Series) -> tuple:
    if len(equity_curve) < 2:
        return 0.0, 0
    rolling_max = equity_curve.expanding().max()
    drawdowns = (equity_curve - rolling_max) / rolling_max * 100
    max_dd = drawdowns.min()

    in_dd = drawdowns < 0
    if not in_dd.any():
        return 0.0, 0

    periods = []
    start = None
    for i, is_dd in enumerate(in_dd):
        if is_dd and start is None:
            start = i
        elif not is_dd and start is not None:
            periods.append(i - start)
            start = None
    if start is not None:
        periods.append(len(in_dd) - start)

    return max_dd, max(periods) if periods else 0


def calculate_calmar_ratio(cagr: float, max_drawdown: float) -> float:
    return cagr / abs(max_drawdown) if max_drawdown != 0 else 0.0


def calculate_var(returns: pd.Series, confidence: float = 0.95) -> float:
    if len(returns) < 10:
        return 0.0
    return np.percentile(returns, (1 - confidence) * 100)


def calculate_cvar(returns: pd.Series, confidence: float = 0.95) -> float:
    var = calculate_var(returns, confidence)
    below_var = returns[returns <= var]
    return below_var.mean() if len(below_var) > 0 else var


def calculate_volatility(returns: pd.Series) -> float:
    return returns.std() * np.sqrt(252) * 100


def calculate_ulcer_index(equity_curve: pd.Series) -> float:
    if len(equity_curve) < 2:
        return 0.0
    rolling_max = equity_curve.expanding().max()
    squared = ((equity_curve - rolling_max) / rolling_max * 100) ** 2
    return np.sqrt(squared.mean())


def calculate_trade_stats(trades: List[Trade]) -> Dict[str, Any]:
    if not trades:
        return {
            "total_trades": 0, "win_rate": 0.0, "profit_factor": 0.0,
            "avg_win": 0.0, "avg_loss": 0.0, "expectancy": 0.0,
            "max_consecutive_wins": 0, "max_consecutive_losses": 0, "avg_trade_duration": "0d",
        }

    wins = [t for t in trades if t.pnl > 0]
    losses = [t for t in trades if t.pnl < 0]
    total = len(trades)
    win_rate = len(wins) / total * 100 if total > 0 else 0

    gross_profit = sum(t.pnl for t in wins) if wins else 0
    gross_loss = abs(sum(t.pnl for t in losses)) if losses else 0
    profit_factor = gross_profit / gross_loss if gross_loss > 0 else float('inf')

    avg_win = np.mean([t.pnl for t in wins]) if wins else 0
    avg_loss = np.mean([t.pnl for t in losses]) if losses else 0
    expectancy = (win_rate / 100 * avg_win) - ((1 - win_rate / 100) * abs(avg_loss))

    max_cons_w = max_cons_l = curr_w = curr_l = 0
    for t in trades:
        if t.pnl > 0:
            curr_w += 1; curr_l = 0
            max_cons_w = max(max_cons_w, curr_w)
        else:
            curr_l += 1; curr_w = 0
            max_cons_l = max(max_cons_l, curr_l)

    durations = [t.duration.days for t in trades if t.duration]
    avg_dur = f"{np.mean(durations):.1f}d" if durations else "0d"

    return {
        "total_trades": total, "win_rate": win_rate,
        "profit_factor": profit_factor, "avg_win": avg_win, "avg_loss": avg_loss,
        "expectancy": expectancy, "max_consecutive_wins": max_cons_w,
        "max_consecutive_losses": max_cons_l, "avg_trade_duration": avg_dur,
    }


def calculate_all_metrics(result: BacktestResult) -> BacktestResult:
    returns = calculate_returns(result.equity_curve)
    years = (result.end_date - result.start_date).days / 365.25

    result.total_return = calculate_total_return(result.initial_capital, result.final_capital)
    result.cagr = calculate_cagr(result.initial_capital, result.final_capital, years)
    result.sharpe_ratio = calculate_sharpe_ratio(returns)
    result.sortino_ratio = calculate_sortino_ratio(returns)
    result.max_drawdown, result.max_drawdown_duration = calculate_max_drawdown(result.equity_curve)
    result.calmar_ratio = calculate_calmar_ratio(result.cagr, result.max_drawdown)
    result.volatility = calculate_volatility(returns)
    result.var_95 = calculate_var(returns, 0.95) * 100
    result.cvar_95 = calculate_cvar(returns, 0.95) * 100
    result.ulcer_index = calculate_ulcer_index(result.equity_curve)

    stats = calculate_trade_stats(result.trades)
    for k, v in stats.items():
        setattr(result, k, v)

    return result


def format_results(result: BacktestResult) -> str:
    params_str = ", ".join(f"{k}={v}" for k, v in result.parameters.items()) or "default"

    return f"""

             BACKTEST: {result.strategy.upper():^20}    {result.symbol:^8}                
           {result.start_date.strftime('%Y-%m-%d')}    {result.end_date.strftime('%Y-%m-%d')}                           

  PERFORMANCE                        RISK                               
    
  Total Return:  {result.total_return:>+10.2f}%    Max Drawdown:   {result.max_drawdown:>+10.2f}%          
  CAGR:          {result.cagr:>+10.2f}%    VaR (95%):      {result.var_95:>+10.2f}%          
  Sharpe Ratio:  {result.sharpe_ratio:>10.2f}     CVaR (95%):     {result.cvar_95:>+10.2f}%          
  Sortino Ratio: {result.sortino_ratio:>10.2f}     Volatility:     {result.volatility:>10.2f}%          
  Calmar Ratio:  {result.calmar_ratio:>10.2f}     Ulcer Index:    {result.ulcer_index:>10.2f}           

  TRADE STATISTICS                                                       
  
  Total Trades:  {result.total_trades:>10}    Profit Factor:  {result.profit_factor:>10.2f}          
  Win Rate:      {result.win_rate:>10.1f}%    Expectancy:     ${result.expectancy:>10.2f}          
  Avg Win:       ${result.avg_win:>10.2f}    Max Cons. Losses: {result.max_consecutive_losses:>5}              
  Avg Loss:      ${result.avg_loss:>10.2f}    Avg Duration:   {result.avg_trade_duration:>10}          

    Capital: ${result.initial_capital:>8,.0f}    ${result.final_capital:>8,.0f}    Return: ${result.final_capital - result.initial_capital:>+9,.0f}   
    Params:  {params_str:<58} 

"""
