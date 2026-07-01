# Transaction Statement Banking UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the movement statement from an analytics-first dashboard into a bank-style transaction statement with search, filters, grouped rows, safer details, and secondary insights.

**Architecture:** Keep the screen under `features/movement`, using existing providers and transaction entities. Add focused presentation helpers for filtering/grouping, reuse existing transaction detail logic where possible, and keep analytics as a secondary tab/section with corrected chart semantics.

**Tech Stack:** Flutter, Riverpod, existing `AppTypography`, `AppColors`, `KeroseneMotion`, and focused widget tests.

---

### Task 1: Statement List As Primary Content

**Files:**
- Modify: `frontend/lib/features/movement/screens/statement_screen.dart`
- Modify: `frontend/lib/features/movement/widgets/statement_transaction_card.dart`
- Test: `frontend/test/features/movement/transaction_statement_screen_search_test.dart`

- [ ] Write failing widget tests that expect `Extrato` to render search, filter chips, grouped transaction rows, and no analytics title before switching to Insights.
- [ ] Implement a bank-style statement header, search field, filter chips, date grouped `SliverList`, and secondary Insights tab.
- [ ] Replace default stack-scroll usage with separated list rows; keep expansion only on tap.
- [ ] Run `flutter test test/features/movement/transaction_statement_screen_search_test.dart --reporter compact`.

### Task 2: Transaction Row And Detail Safety

**Files:**
- Modify: `frontend/lib/features/movement/widgets/statement_transaction_card.dart`

- [ ] Add compact separated mode with 48x48 icon/tap targets, signed amount aligned right, status/network/date subtitle, and detail expansion.
- [ ] Increase copy buttons to 48x48 and route all animations through `KeroseneMotion.duration(context, ...)`.
- [ ] Use user-oriented labels: `Recebido`, `Enviado`, `Transferencia interna`, `Pagamento Lightning`, `Deposito on-chain`, `Saque on-chain`.

### Task 3: Insights As Secondary Analytics

**Files:**
- Modify: `frontend/lib/features/movement/widgets/transaction_statement_insights.dart`

- [ ] Remove fake minimum bar height for zero values.
- [ ] Change donut center from `100%` to `Total` plus formatted BTC amount, keeping dominant wallet in legend.
- [ ] Give panels real surface/border contrast and wrap animation durations with `KeroseneMotion.duration`.

### Task 4: Destination Error And CTA Consistency

**Files:**
- Modify: `frontend/lib/features/movement/screens/send_destination_step.dart`

- [ ] Replace white invalid helper text with semantic warning styling, icon, border, and actionable message.
- [ ] Normalize close/scanner/action touch targets to at least 48x48 and primary CTA to one consistent 56px style.

### Task 5: Verification

**Files:**
- Verify changed frontend files.

- [ ] Run focused statement and destination tests.
- [ ] Run `flutter analyze` or focused analyze if unrelated committed work blocks the full suite.
- [ ] Run `git diff --check`.
