# Task 06: Build The Owner Analytics Dashboard

## Outcome

Provide an accessible owner dashboard with canonical KPIs, revenue/profit trends, ranked products/customers, date presets, and no low-stock analytics section.

## Why This Task Exists

The current analytics page is a long list of values. It lacks headline metrics, trends, prioritization, and useful date selection.

## Dependencies

Task 02 precision contracts. May run parallel with Tasks 04/05.

## Repository Evidence

- Backend `schemas/analytics.py`, `services/analytics_service.py`, `routers/analytics.py`.
- Local `local_analytics_service.dart`.
- Mobile `models/analytics.dart`, `services/api_analytics_service.dart`, `screens/analytics_screen.dart`.
- Current backend already calculates several company/customer/product rankings and retains low stock.

## Read Before Editing

- Design Analytics contract and accepted owner-snapshot focus.
- Existing backend/local analytics tests and wholesaler flow tests.

## Scope

### Change

- Add additive response/model fields:
  - `total_revenue`, `total_profit`, `customer_receivables`, `buyer_payables`;
  - `active_invoice_count`, `average_invoice_value`;
  - `daily_trend: [{date, revenue, profit}]` with every date in range represented, including zeros.
- Canonical calculations:
  - active invoices only for revenue/profit/count/average/trends;
  - revenue and profit use existing canonical invoice-item fields, not current product prices;
  - average is total active invoice grand total divided by active invoice count, zero when count zero;
  - receivables/payables use existing ledger sign rules and active entities consistent with sharing/current domain behavior.
- Preserve existing breakdown/ranking and `low_stock` fields for API compatibility.
- Add range presets: Today, Last 7 days inclusive, Last 30 days inclusive, This month, Custom. Default Last 30 days. Custom validates from <= to and reloads only after both chosen.
- Redesign screen:
  - responsive two-column/three-column KPI cards depending width;
  - revenue/profit line chart with legend, accessible summary, readable date ticks, and zero-state;
  - ranked cards for top products and customers; use existing revenue/profit series where possible;
  - receivables/payables summary;
  - remove low-stock section and exclude it from `hasData` logic;
  - loading skeleton/progress, retry, pull-to-refresh, empty state, and selected-range label.
- Use `fl_chart` selected in Task 01; chart widget remains presentation-only and receives prepared points.

### Preserve

- Existing endpoint path and query parameters.
- Existing response fields and local/API parity.
- Inventory low-stock filters/screens and backend low-stock output.

### Explicitly Out Of Scope

- Forecasting, overdue aging, drill-down navigation, stock alerts, downloadable reports.

## Contracts And Invariants

- Date range is inclusive and interpreted consistently by backend/local services.
- No canceled invoice contributes.
- Profit uses invoice snapshots.
- KPI totals equal sums of returned canonical series within rounding tolerance.
- Low-stock compatibility field may be populated but cannot make the UI non-empty.

## Implementation Guidance

- Add small internal aggregation helpers and paired fixtures so backend/local calculations use the same scenario data.
- Prefer one grouped query per metric family rather than per-day/per-entity loops.
- Local service can aggregate loaded rows in memory at current scale but must avoid N+1 customer/product queries.
- Expose formatted semantic labels outside the chart canvas for screen readers.
- Keep raw doubles in existing mobile models only at the presentation boundary; parse canonical decimal strings consistently.

## Test-First Specification

- Backend/local parity fixture with GST/non-GST, cash/credit/partial, canceled invoice, two dates, receivable/payable entries, and product/customer rankings.
- Assert KPI totals, count, average, zero-filled trend dates, inclusive presets, canceled exclusion, and snapshot profit.
- API parsing tests for additive fields and backward-compatible low stock.
- Widget tests for KPI labels/values, preset transitions, custom invalid range, chart/accessible summary, ranked sections, refresh/error/empty states, and complete absence of Low Stock.
- Regression test: dashboard with only low-stock data displays analytics empty state.

## Validation Ladder

```bash
PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/services/test_analytics_pure.py -q
BILLING_DATABASE_URL='postgresql+psycopg://khata:khata@localhost:55432/internal_billing_test' PYTHONPATH=backend .venv/bin/python -m pytest backend/tests/api/test_analytics.py backend/tests/services/test_analytics_service.py -q
(cd mobile && flutter test test/local/local_analytics_service_test.dart test/widgets/analytics_screen_test.dart test/app/wholesaler_flow_test.dart)
(cd mobile && flutter analyze)
```

Runtime: inspect narrow and normal phone widths, all presets/custom dates, empty/loading/error states, chart labels, and no low-stock section.

## Review Checklist

- [ ] Backend/local parity fixture passes.
- [ ] Active/canceled and date rules correct.
- [ ] No current-product profit lookup.
- [ ] Low-stock API compatibility retained, UI removed.
- [ ] Chart has nonvisual summary and readable axes.

## Allowed Adaptation

Card order, colors, and chart tick density may adapt to Material theme and screen width. KPI definitions, presets, and compatibility policy are fixed.

## Stop And Escalate If

- Existing revenue/profit fields have conflicting definitions between API/local paths.
- `fl_chart` cannot meet accessible-summary requirements without a parallel semantic representation.
- Query plan becomes N+1 or unbounded per day/entity.

## Commit Checkpoint

`feat(analytics): add owner kpis and trends`

## Done When

AC12 parity and widget tests pass, the dashboard is usable at phone widths, and low stock is absent only from analytics presentation.

## Handoff Update

Record KPI formulas, fixture expected values, query strategy, date semantics, screenshots/runtime notes, and chart accessibility evidence.
