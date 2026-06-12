# PROJECT RECOVERY PROTOCOL

**Author**: Market Structure & Architecture Team  
**Date**: June 12, 2026  
**Status**: APPROVED BASELINE  
**Workspace**: `c:\xauusd_chatgpt`

---

## 1. Introduction

This protocol outlines onboarding instructions for new AI agents, developers, or future versions of ourselves. If ChatGPT chat history is completely lost, this document is the authoritative guide to resuming development with zero historical friction.

---

## 2. Mandatory Reading Order

To align your understanding of the system rules, architecture, and current state, you **must** read the following documents in this exact order:

1.  **[PROJECT_GENESIS.md](file:///c:/xauusd_chatgpt/PROJECT_GENESIS.md)**: The highest-level bible covering identity, vision, completed sprints, bugs history, and architectural decisions.
2.  **[PROJECT_MEMORY.md](file:///c:/xauusd_chatgpt/docs/core/PROJECT_MEMORY.md)**: The detailed chronological timeline log of the project.
3.  **[PROJECT_STATE_REVIEW.md](file:///c:/xauusd_chatgpt/docs/core/PROJECT_STATE_REVIEW.md)**: High-level status review identifying frozen elements, risks, and technical debt.
4.  **[SNR_ARCHITECTURE_FREEZE.md](file:///c:/xauusd_chatgpt/docs/design/SNR_ARCHITECTURE_FREEZE.md)**: The frozen architectural specification for the current/next sprint.
5.  **[08_AGENT_ONBOARDING.md](file:///c:/xauusd_chatgpt/docs/core/08_AGENT_ONBOARDING.md)**: Onboarding instructions on how to run compiler and backtest scripts.
6.  **Remaining Documentation**: Other files under `/docs/core/` and `/docs/audits/`.

---

## 3. Permanent System Rules

All agents and developers must strictly follow these rules:

1.  **Never Modify Frozen Modules**: `StructureEngine.mqh` (v2.2) and `SupplyDemandEngine.mqh` (v1.1) are frozen. Their public APIs are locked.
2.  **Always Audit Before Implementation**: A design consistency audit (e.g. `SNR_DESIGN_AUDIT.md`) must be conducted before any sprint code is written.
3.  **Always Verify with Backtests**: All code corrections or updates must undergo a 4-year backtest (2022-2025) on Gold (XAUUSD, H4/M30) to mathematically verify metrics.
4.  **Never Trust Statistical Assumptions without Validation**: Parser scripts and stats compilers must be executed against raw Strategy Tester logs to verify numbers (e.g. true false positive rates).

---

## 4. Recovery Procedure

If chat history is lost or a new conversation is initialized:

1.  **Locate Workspace**: Open the workspace directory `c:\xauusd_chatgpt`.
2.  **Check Git Status**: Run `git status` to check the current branch and staged files.
3.  **Initialize Orientation**: Read `/PROJECT_GENESIS.md` and `/docs/core/PROJECT_MEMORY.md` to identify the current frozen engine versions.
4.  **Confirm Compile Status**: Run the copy-and-compile script:
    ```powershell
    powershell -File C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\copy_and_compile.ps1
    ```
    Open `C:\Users\rositapermata33\.gemini\antigravity-ide\scratch\compile.log` to confirm `0 errors, 0 warnings`.
5.  **Examine Next Task**: Read `/PROJECT_GENESIS.md: Section 8` (Next Sprint) and the frozen specification `/docs/design/SNR_ARCHITECTURE_FREEZE.md`.
6.  **Create Checkpoint Branch**: Create a new git branch for the sprint (e.g. `git checkout -b feature/snr-engine`).
7.  **Proceed with Coding**: Write code only inside the designated active folder (e.g. `src/engines/SnrEngine.mqh`).
