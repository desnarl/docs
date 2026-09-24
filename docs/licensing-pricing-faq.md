---
sidebar_position: 5
title: Licensing & pricing FAQ
---

# Licensing & pricing FAQ

## How much does Desnarl cost?

**$25/mo, unlimited repos, runs entirely on your own infrastructure.**

> This figure is an explicit, unvalidated placeholder, not a finalized price. It's recorded here so this page tells you the current number honestly, not so you can treat it as locked. Check [desnarl.com](https://desnarl.com) for the current, authoritative price before relying on it for budgeting.

Pricing is a flat fee per workspace, gated by license type — not usage-metered, not tiered by repo count. One price for a commercial license, regardless of workspace size.

## How is a commercial license enforced?

It isn't, mechanically. **Licensing is self-attested, not enforced or verified** — whether your use is commercial or non-commercial is a declaration you make, not something the software checks. Nothing in Desnarl inspects your usage to confirm your license type.

## Does my repo content ever leave my infrastructure?

No. Storage and compute both run where you run them — the operator never holds your repo content. See [Self-hosted deployment](./self-hosted/deployment.md) for the complete, itemized list of the (small number of) network calls Desnarl does make, none of which carry repo content.

**On GDPR specifically:** this reduces Desnarl's GDPR exposure to standard SaaS-signup scope — it does not eliminate it. Account creation, and any future license check-in, are still personal/business data processing under GDPR's general scope even though your code never leaves your infrastructure.

## How do I get help?

Through an in-portal support ticket, once the license portal ships that feature — see [Troubleshooting → Getting help](./troubleshooting.md#getting-help). There is no email support and no public Discord/community support channel, for any tier.

## Where do I buy a license or manage billing?

Through [desnarl.com](https://desnarl.com) — account creation, license declaration, and (once built) billing and support all live in the self-serve portal there. This docs site doesn't handle accounts or payment.
