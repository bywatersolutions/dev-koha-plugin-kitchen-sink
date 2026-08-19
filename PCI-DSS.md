# PCI DSS scoping statement — Kitchen Sink

This document exists because any automated sweep for payment code in ByWater's plugins will flag
this one, and the finding deserves a written answer.

**Kitchen Sink is not a payment plugin.** It is the demonstration plugin that exercises every hook
Koha's plugin system offers — including the online-payment hooks. Its
[`opac_online_payment`](https://github.com/bywatersolutions/dev-koha-plugin-kitchen-sink/blob/980c584fcf8ea39efa724ebd72fd3727611891a9/Koha/Plugin/Com/ByWaterSolutions/KitchenSink.pm#L161), [`opac_online_payment_begin`](https://github.com/bywatersolutions/dev-koha-plugin-kitchen-sink/blob/980c584fcf8ea39efa724ebd72fd3727611891a9/Koha/Plugin/Com/ByWaterSolutions/KitchenSink.pm#L170) and
[`opac_online_payment_end`](https://github.com/bywatersolutions/dev-koha-plugin-kitchen-sink/blob/980c584fcf8ea39efa724ebd72fd3727611891a9/Koha/Plugin/Com/ByWaterSolutions/KitchenSink.pm#L202) are **live demo code with no payment processor behind
them**: "paying" simply [credits the selected fees](https://github.com/bywatersolutions/dev-koha-plugin-kitchen-sink/blob/980c584fcf8ea39efa724ebd72fd3727611891a9/Koha/Plugin/Com/ByWaterSolutions/KitchenSink.pm#L234) with the note
[`Paid via KitchenSink ImaginaryPay`](https://github.com/bywatersolutions/dev-koha-plugin-kitchen-sink/blob/980c584fcf8ea39efa724ebd72fd3727611891a9/Koha/Plugin/Com/ByWaterSolutions/KitchenSink.pm#L238). No money moves, no card exists, nothing is
transmitted anywhere.

---

## 1. Summary

| Assertion | Determination |
|---|---|
| Does this plugin accept, transmit, or store cardholder data, or any card-derived data? | **No — there is no processor and no card in the flow at all** |
| Does the patron ever enter card details into a page served by Koha? | **No** |

**Determination: Koha is outside the cardholder data environment.** No card data exists anywhere
in this plugin.

## 2. The finding that matters is not a PCI finding

Because the demo payment hooks are live, **a patron on an instance with this plugin installed and
enabled can clear their own real fines at no cost** — the hooks call `Koha::Account->pay` on
whatever accountlines the patron selects. This plugin is built and published as an installable
`.kpz` for development and demonstration.

**It must never be installed on a production instance.** That is an operational rule, not a
cardholder-data one, and this document is where it is written down.

## 3. What was reviewed

Reviewed at commit [`980c584fcf8ea39efa724ebd72fd3727611891a9`](https://github.com/bywatersolutions/dev-koha-plugin-kitchen-sink/commit/980c584fcf8ea39efa724ebd72fd3727611891a9)
on 2026-08-19: the three payment hooks and the `pay` call above.

| Date | Commit | Reviewer | Change |
|---|---|---|---|
| 2026-08-19 | `980c584` | Kyle M Hall | Initial review |
