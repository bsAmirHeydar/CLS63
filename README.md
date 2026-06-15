# CLS63

**Experimental MQL5 trading system focused on hook-based entries, Near Death levels, fixed-risk sizing, and visual execution review.**

CLS63 is an experimental MQL5 trading-system project. It documents and implements a structured discretionary-to-systematic trading logic based on market nodes, hook sequences, reverse limit entries, fixed-risk position sizing, and chart-based review.

The repository is part of a broader research journey in MQL5 trading systems, market-structure interpretation, and risk-controlled execution.

---

## Research Purpose

The purpose of this project is to convert a complex market-reading framework into explicit trading logic that can be tested, reviewed, and improved.

The system focuses on:

- Structural node detection
- Hook sequence interpretation
- Near Death entry levels
- Reverse limit entries
- Fixed-dollar risk sizing
- Partial exits / take-profit management
- Structure-based invalidation
- Visual review of execution logic

This is a research-stage trading system, not a guaranteed profitable strategy.

---

## Core Trading Logic

### 1. Market Reading

The system reads market structure through nodes and hooks.

- Nodes are swing highs and lows defined by `pivot_depth`.
- Sequences are scanned from recent structure backward and then organized into forward structure.
- Positive hooks start from an unbroken low.
- Negative hooks start from an unbroken high.
- Hook scanning focuses on selected timeframes such as `M1`, `M5`, `M15`, `H1`, `H4`, and `D1`.
- If sequence length grows too much, analysis can shift to a higher timeframe.

### 2. Core Setup

A valid setup requires two aligned hooks:

- `Hook1`
- `Hook2`

The entry is not based on simply seeing `Rally_1`. The main entry concept is the **Near Death** region of the second hook.

### 3. Entry Logic

The entry model is reverse-limit based.

- Entries are placed against a sharp current price movement.
- Entry area is around the `86.4%` level of `Hook2`.
- Buy setup: price aggressively drops into the Near Death area of a positive Hook2.
- Sell setup: price aggressively rises into the Near Death area of a negative Hook2.
- Final lower-timeframe confirmation may use flag or 1-2-3 style structure.

### 4. Stop Loss

The stop loss is placed behind the same `Hook2` used for entry.

- Buy: below the extreme / `Z2` of Hook2.
- Sell: above the extreme / `Z2` of Hook2.

### 5. Exit Management

The logic avoids trailing-stop dependency.

- No trailing stop as a core exit method.
- Exits are handled through take-profit and partial position reduction.
- Full exit occurs when the Hook2 structure is invalidated.

### 6. Risk

Risk is based on fixed monetary risk.

Position size should be calculated so that stop-loss execution corresponds to the intended fixed risk amount.

---

## Repository Structure

| Path | Purpose |
|---|---|
| `CLS63.mq5` | Main MQL5 Expert Advisor / entry point. |
| `MQHs/` | Supporting MQL header modules for strategy logic, execution, and utilities. |
| `README.md` | Project documentation. |

---

## How to Use

1. Copy `CLS63.mq5` and the `MQHs/` folder into a MetaTrader 5 project directory.
2. Open `CLS63.mq5` in MetaEditor.
3. Compile the Expert Advisor.
4. Run in MetaTrader 5 Strategy Tester, preferably in visual mode.
5. Use visual review to inspect node detection, hook structure, Near Death entries, stop placement, and exits.

---

## Development Notes

This repository represents an experimental and evolving trading-system implementation. The main value of the project is not only the strategy idea, but also the attempt to formalize subjective market-reading concepts into explicit MQL5 logic.

Recommended next improvements:

- Convert all Persian/internal notes into English documentation.
- Add screenshots of valid/invalid setups.
- Add parameter documentation.
- Add example test cases.
- Separate core logic, execution logic, and visualization logic more clearly.

---

## Status

Experimental research-stage project.

---

## Disclaimer

This repository is for research and educational purposes only. It is not financial advice and does not provide trading recommendations.
