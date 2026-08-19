# PCI DSS scoping statement — {{Plugin Display Name}}

<!--
TEMPLATE — copy to <plugin-repo>/PCI-DSS.md and fill in every {{placeholder}}.

Two rules govern this document:

1. It states FACTS ABOUT OUR CODE. It does not interpret PCI DSS. No requirement
   numbers, no SAQ eligibility rulings, no statements about whether the library is
   in scope. Those change, and if they are baked into a dozen documents, all
   dozen go stale silently. Say "the patron enters card details only on pages
   served by <processor>; no Koha-served page collects, frames, or scripts the
   card-entry form." That sentence is true forever and is verifiable from the code.

2. Never leave a cell blank. Use exactly one of:
     a value          — the fact, cited
     None             — verified absent by reading the code
     Not applicable   — the question does not arise for this plugin
     Unknown — see §7 — could not be determined from source

   The difference between "None" and "Unknown" is the whole point of this
   document. A blank cell destroys it.

3. EVERY code reference is a GitHub permalink pinned to the reviewed commit, so
   a reader can check any claim against the source it was drawn from, and so the
   cited lines stay the lines that were read even after the code moves.

   Use reference-style links, defined in one block at the bottom, so the tables
   stay legible in raw Markdown and the sha lives in one place:

       | `CardType` | Card-derived | No | Logged only | [`openapi.json:89`][oa89] |

       [oa89]: https://github.com/bywatersolutions/<repo>/blob/<40-char-sha>/Koha/Plugin/Com/ByWaterSolutions/<Name>/openapi.json#L89

   Label convention — prefix identifies the file, digits identify the lines:
       [pm131]     PayViaInvoiceCloud.pm line 131        -> #L131
       [api60-61]  API.pm lines 60 to 61                 -> #L60-L61
       [pm]        the whole file, no line anchor
   Suggested prefixes: pm (main module), api (API.pm), oa (openapi.json),
   begin / end (payment templates), conf (configure.tt), commit (the commit).

   Get the canonical repo name from GitHub, not from the local directory name or
   the git remote — several of these repos have been renamed and the old URL only
   works by redirect. Check with:
       curl -s -o /dev/null -w '%{url_effective}\n' -L https://github.com/bywatersolutions/<dir-name>

   Verify before committing: every label used has a definition, every definition
   is used, and every distinct URL returns 200.

Delete this comment block when you fill the template in.
-->

This document describes what data the **{{Plugin Display Name}}** Koha plugin sends to
{{Processor}}, what {{Processor}} sends back, and what Koha retains.

It is a factual description of the plugin's behaviour at the commit named in section 9. It is not a
certification, and it does not determine any library's PCI DSS obligations — a library that accepts
card payments is a merchant and has obligations regardless of what Koha does. What this document
establishes is whether Koha itself sits inside the cardholder data environment. Your acquirer and
your assessor decide the rest.

---

## 1. Summary

<!--
Word these six rows IDENTICALLY in every plugin's document. Only the right-hand
column changes. That is what makes the set comparable side by side.

Rows 5 and 6 discriminate the integration models from each other far better than
rows 1-3 do — every plugin answers "no" to rows 1-3, which is true but conveys
nothing on its own.
-->

| Assertion | Determination |
|---|---|
| Does this plugin **accept** cardholder data (PAN, CVV/CVC/CID, expiry date, track or chip data, PIN)? | **{{No}}** |
| Does this plugin **transmit** cardholder data to any system? | **{{No}}** |
| Does this plugin **store** cardholder data? | **{{No}}** |
| Does this plugin store any **card-derived** data (card brand, truncated PAN, authorisation code)? | **{{No}}** |
| Does the patron ever enter card details into a page served by Koha? | **{{No}}** |
| Does any Koha-served page frame, embed, script, or otherwise affect the processor's card-entry page? | **{{No}}** |

**Determination: {{Koha is outside the cardholder data environment.}}**

<!--
Use exactly one of these four sentences, verbatim:

  "Koha is outside the cardholder data environment."
  "Koha is outside the cardholder data environment, with the caveats below."
  "Undetermined. This plugin's scope cannot be established from source code alone; see §7."
  "Koha is inside the cardholder data environment."

HARD RULE: if any row above reads "Unknown", the determination MUST be
"Undetermined". An unknown may never be summarised as a clean result.
-->

{{One plain-language paragraph a library can forward to its own auditor: where the patron types
their card number, who receives it, what Koha learns afterwards.}}

### Two terms that look like card data and are not

**Koha's `cardnumber` is a library card barcode, not a payment card number.** Koha stores each
patron's library card barcode in `borrowers.cardnumber`, and the plugin source calls it
`cardnumber`. It is the number printed on the plastic card used to borrow books. It is not a PAN and
is not cardholder data. Wherever this document lists `cardnumber`, it means the library barcode.

**A payment type of `CREDITCARD` on an accountline is a bookkeeping label.** It records that the
patron paid by card *somewhere*. It is a category name in Koha's accounting and does not imply that
card data is stored.

{{Add any other collision this plugin creates. Comprise SmartPAY, for example, has `TrackId` and
`TrackNo` parameters that are transaction tracking numbers, not magstripe track data.}}

---

## 2. How a payment works

<!--
Name the actor performing each step — patron's browser, Koha server, processor.
The actor is what determines where the boundary falls, and a field table read
without it cannot be evaluated.
-->

1. {{The patron selects fees in the OPAC and clicks Pay. Koha calls `opac_online_payment_begin`
   (`Koha/Plugin/.../Example.pm:57`).}}
2. {{...}}

```
{{Optional sequence sketch. Card data should be visibly absent from every arrow touching Koha.

  Patron browser        Koha (ByWater)        Example Payments
        |                     |                      |
        |--- select fees ---->|                      |
        |<-- redirect link ---|                      |
        |------------------- card details ---------->|   <-- Koha not involved
        |<------------------- receipt ---------------|
        |--- return w/ txn id ->|                    |
}}
```

### Classification legend

Used by the Classification column throughout. Controlled vocabulary — do not invent new values.

| Value | Meaning |
|---|---|
| `CHD` | Cardholder data: PAN, cardholder name as it appears on the card, expiry, service code |
| `SAD` | Sensitive authentication data: full track data, CVV/CVC/CID, PIN or PIN block |
| `Card-derived` | Derived from a card but not CHD: card brand, truncated PAN, authorisation code |
| `Patron PII` | Personally identifying patron data: name, address, email, telephone |
| `Patron identifier` | Internal or library identifier: `borrowernumber`, library card barcode |
| `Financial` | Amounts, fee descriptions, accountline identifiers |
| `Opaque token` | A value with no meaning outside this transaction |
| `Secret` | Credential, API key, shared secret, password |
| `Non-personal` | Configuration, timestamps, URLs, status codes |

---

## 3. Data sent to the payment processor

**Transport:** {{HTTPS POST, browser-initiated}}
**Endpoint:** {{https://example.com/pay}}

| Field | Source in Koha | Classification | Purpose | Code reference |
|---|---|---|---|---|
| {{`orderNumber`}} | {{`accountlines.accountlines_id`}} | {{Financial}} | {{Correlates payment to fee}} | {{Example.pm:93}} |

**Cardholder data in this table: {{none}}.**

{{If the transport places any of these in a URL, say so explicitly and name the fields — query
string parameters are recorded in intermediate web server access logs and browser history, and an
assessor will ask.}}

---

## 4. Data received from the payment processor

**Transport:** {{Browser redirect to `opac-account-pay-return.pl`}}
**Authentication of this channel:** {{Patron's authenticated OPAC session}}

<!--
"Authentication of this channel" is required and must be honest. Use one of:
  "Patron's authenticated OPAC session"
  "Shared secret verified at <file:line>"
  "Signature/HMAC verified at <file:line>"
  "None — the endpoint accepts unauthenticated requests"
If it is "None", it must also appear in §8.
-->

| Field | Classification | Read by the plugin? | Persisted? | Where | Code reference |
|---|---|---|---|---|---|
| {{`transactionId`}} | {{Opaque token}} | {{Yes}} | {{Yes, hashed}} | {{`accountlines.note`}} | {{Example.pm:171}} |

<!--
"Read by the plugin?" — use `Yes`, `No — accepted but never read`, or
`Unknown — see §7`.

A field the plugin declares but ignores STILL gets a row. If it is declared in
openapi.json or captured by a log statement, it reached the server.
-->

**Cardholder data in this table: {{none}}.**

{{If the response field list cannot be established from the source — e.g. the body is parsed into an
arbitrary hash — say so in one sentence here and raise it in §7. Do not present a partial list as
complete.}}

---

## 5. What Koha stores, and for how long

### 5.1 Database

| Store | Field | Contents | Classification | Written when | Deleted when | Retention |
|---|---|---|---|---|---|---|
| {{`example_plugin_tokens`}} | {{`token`}} | {{`B<borrowernumber>T<epoch>`}} | {{Patron identifier}} | {{Checkout begins}} | {{On successful payment; on patron deletion via `ON DELETE CASCADE`}} | {{Indefinite for abandoned checkouts — see §5.4}} |

### 5.2 Logs

<!--
Logs are storage. A `warn` in a Koha plugin writes to plack-error.log or the
Apache error log and persists for as long as the host's logrotate policy keeps
it. Every warn/print/Data::Dumper reachable in a payment path gets a row,
including debug statements that ship enabled.
-->

| Statement | Location | Destination | Enabled by default | Contents | Classification |
|---|---|---|---|---|---|
| {{`warn "RESPONSE: ..."`}} | {{Example.pm:145}} | {{plack-error.log}} | {{Yes}} | {{Full processor response body}} | {{Financial, Patron PII}} |

**Log retention:** log files are rotated and removed by the host operating system's `logrotate`
configuration, not by this plugin. The plugin has no control over, and makes no guarantee about, how
long log contents persist.

### 5.3 Configuration and credentials

| Credential | Stored in | Protection at rest | Visible to | Code reference |
|---|---|---|---|---|
| {{`api_key`}} | {{Koha `plugin_data`}} | {{None — cleartext}} | {{Staff with the `plugins` permission}} | {{Example.pm:216}} |

{{State how the configuration form submits. A form using `method='get'` places every configured
secret into the staff member's browser URL, browser history, and the web server access log.}}

### 5.4 Retention and disposal

- **Scheduled purge:** {{None. This plugin ships no cron job, TTL, or cleanup routine.}}
- **Removed on successful payment:** {{the `example_plugin_tokens` row}}
- **Records that accumulate:** {{token rows from abandoned or failed checkouts}}
- **On patron deletion:** {{token rows are removed by `ON DELETE CASCADE`}}
- **On plugin uninstall:** {{the table is dropped / is retained}}
- **Cardholder data retained:** **{{None}}** — {{no cardholder data is stored, so there is none to
  retain or dispose of}}

---

## 6. Patron personal data (outside PCI scope)

<!--
Deliberately its own section, and deliberately after the PCI material. It is not
cardholder data and must not be mixed into the tables above, or a reader
skimming for card data will misread patron rows as findings. But omitting it
looks evasive, and library patron-record confidentiality is often a sharper
obligation for a library than PCI is.
-->

The data below is not cardholder data and is outside PCI DSS scope. It is documented here because it
is within scope of library patron-record confidentiality obligations, and because customers ask
about it in the same breath.

| Element | Sent to {{Processor}} | Stored by this plugin | Retention |
|---|---|---|---|
| {{Patron name}} | {{Yes — §3}} | {{No}} | {{Not applicable}} |
| {{Postal address}} | {{No}} | {{No}} | {{Not applicable}} |
| {{Email address}} | {{No}} | {{No}} | {{Not applicable}} |
| {{Library card barcode}} | {{No}} | {{No}} | {{Not applicable}} |
| {{Fee descriptions}} | {{No}} | {{No}} | {{Not applicable}} |

{{If itemised fee descriptions are transmitted, say plainly that these can identify borrowed
material and are therefore sensitive under most library confidentiality policies.}}

Once transmitted, {{Processor}}'s handling of this data is governed by their privacy policy and the
library's agreement with them, not by this plugin.

---

## 7. Open questions

<!--
MANDATORY. Never delete this section. If there is nothing to report it carries
the explicit "None." line below, so a reader can tell "we checked and found
nothing" from "we did not look". An absent section reads as the former and
usually means the latter.

An item here that touches cardholder data forces the §1 determination to
"Undetermined".
-->

{{None. Every data element in this document was verified against the source at the commit named in
§9.}}

| Question | Why the code cannot answer it | Evidence needed | Effect on §1 |
|---|---|---|---|
| {{What fields does the status response contain?}} | {{The response is decoded into an arbitrary key/value hash and never enumerated.}} | {{Vendor API specification}} | {{Rows 3 and 4 read "Unknown"; determination is "Undetermined" until resolved.}} |

---

## 8. Known limitations

<!--
Scope: only items bearing on the claims made in THIS document — what an assessor
reading it would reasonably ask about. This is not a general security backlog.

Describe the property, never its exploitation. No proof of concept, no
step-by-step. If an item is exploitable and unfixed, use "Tracked privately" and
omit the detail.

Status vocabulary:
  Open — tracked as <ref>
  Remediated in v<X.Y.Z>
  Accepted risk — <owner>, <date>
  Tracked privately — <ref>
-->

| Item | Location | Bearing on this document | Status |
|---|---|---|---|
| {{...}} | {{...}} | {{Does not affect the cardholder data determination in §1 — no card data is involved.}} | {{Open}} |

---

## 9. What was reviewed

Reviewed at commit `{{sha}}`, version `{{1.0.5}}`, on `{{YYYY-MM-DD}}` by {{Name}}.

<!--
The reviewed commit is the commit the review was performed AGAINST — necessarily
the parent of the commit that adds this file. Say so, or the first person to
notice the mismatch will assume the document is wrong.
-->

| File | Checked for |
|---|---|
| {{`Koha/Plugin/Com/ByWaterSolutions/Example.pm`}} | {{Outbound payload construction, return handling, configuration}} |
| {{`Koha/Plugin/Com/ByWaterSolutions/Example/API.pm`}} | {{Inbound endpoint, authentication, payment crediting}} |
| {{`Koha/Plugin/Com/ByWaterSolutions/Example/openapi.json`}} | {{Declared inbound parameters, authorisation requirements}} |
| {{`Koha/Plugin/Com/ByWaterSolutions/Example/*.tt`}} | {{Values rendered into pages served to patrons and staff}} |

**Not reviewed:** build tooling, dependency trees, and Koha core. Koha core's own handling of
`accountlines` is outside this document.

**Re-review is required when any of these change:** the outbound request construction, the API
controller, `openapi.json`, the install/upgrade schema, or any logging statement in a payment code
path.

---

## 10. Review history

| Date | Version | Commit | Reviewer | Change |
|---|---|---|---|---|
| {{YYYY-MM-DD}} | {{1.0.5}} | {{[`shortsha`][commit]}} | {{Name}} | {{Initial review}} |

---

<!--
Reference-style link definitions go here, one block, pinned to the reviewed
commit. See the authoring notes at the top of this template for the label
convention.

To re-review at a new commit:
  1. Replace every occurrence of the 40-character sha (this block, plus the
     display text in §9 and the commit link in §10).
  2. Replace the short sha in the §10 review-history table.
  3. Re-derive the line numbers — they are the part that rots.
-->

[commit]: https://github.com/bywatersolutions/{{repo}}/commit/{{40-char-sha}}
[pm]: https://github.com/bywatersolutions/{{repo}}/blob/{{40-char-sha}}/Koha/Plugin/Com/ByWaterSolutions/{{Name}}.pm
[pm131]: https://github.com/bywatersolutions/{{repo}}/blob/{{40-char-sha}}/Koha/Plugin/Com/ByWaterSolutions/{{Name}}.pm#L131
