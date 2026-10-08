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

## Is Desnarl open source?

No. Desnarl is **source-available**: its source is published under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0), which permits non-commercial use only. That is not an open-source licence. Commercial use needs a separate, paid commercial license from Cascade Logic Ltd, the company that trades as Desnarl.

Third-party components keep their own licences. The PolyForm terms cover only Desnarl's own code.

## Is my use commercial or non-commercial?

PolyForm does not define "non-commercial". It says "Any noncommercial purpose is a permitted purpose", names personal uses, and lists kinds of organisation whose use is covered "regardless of the source of funding". The examples below are guidance to help you decide. They are not legal advice and not a binding interpretation. If your situation is not clearly in the first group, treat it as commercial, or ask before you rely on it.

| Your situation | Where it lands |
| --- | --- |
| A personal project, hobby, learning or experiment with no anticipated commercial application | Non-commercial (the licence's "personal uses") |
| A charity, school or university, public research body, public safety or health body, environmental protection organisation or government institution, using it for its own work | Non-commercial, whatever funds it (the licence's "noncommercial organizations") |
| A company of any size, including a startup, using it for its own products or services | Commercial |
| A consultancy or agency running it on clients' repos | Commercial |
| A company trying it out to decide whether to buy | Commercial. An evaluation by a company is not a non-commercial use. |
| A university spin-out or startup built on research | Commercial, once the aim is commercial advantage |
| A side project run at, or for the benefit of, your employer | Treat as commercial |
| An open-source maintainer with sponsorship income | Not clear-cut. The licence does not say. If the work is a business or a livelihood, treat it as commercial. |
| A non-profit that is not a charity, such as a trade body, community interest company or social enterprise | Not clear-cut. These are not in the licence's list of organisations. |

## Can I use Desnarl's source to train AI models?

Desnarl's licence does not grant a right to use its source to train AI models for commercial purposes. Non-commercial use is licensed on PolyForm's terms. Nothing on this page limits any rights the law gives you regardless of the licence.

## Does my repo content ever leave my infrastructure?

No. Storage and compute both run where you run them — the operator never holds your repo content. See [Self-hosted deployment](./self-hosted/deployment.md) for the complete, itemized list of the (small number of) network calls Desnarl does make, none of which carry repo content.

**On GDPR specifically:** this reduces Desnarl's GDPR exposure to standard SaaS-signup scope — it does not eliminate it. Account creation, and any future license check-in, are still personal/business data processing under GDPR's general scope even though your code never leaves your infrastructure.

## How do I get help?

Through an in-portal support ticket, once the license portal ships that feature — see [Troubleshooting → Getting help](./troubleshooting.md#getting-help). There is no email support and no public Discord/community support channel, for any tier.

## Where do I buy a license or manage billing?

Through [desnarl.com](https://desnarl.com) — account creation, license declaration, and (once built) billing and support all live in the self-serve portal there. This docs site doesn't handle accounts or payment.
