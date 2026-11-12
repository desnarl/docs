---
sidebar_position: 5
title: Licensing & pricing FAQ
---

# Licensing & pricing FAQ

## How much does Desnarl cost?

**$25/mo, unlimited repos, runs entirely on your own infrastructure.**

> This figure is an explicit, unvalidated placeholder, not a finalized price. It's recorded here so this page tells you the current number honestly, not so you can treat it as locked. Check [desnarl.com](https://desnarl.com) for the current, authoritative price before relying on it for budgeting.

Pricing is a flat fee per GitHub organisation, gated by license type: not usage-metered, not tiered by repo count. One price for a commercial license, regardless of how many repos or people. (Throughout these docs, a *workspace* is the folder of sibling repos you point the server at. The license is per organisation, not per folder or per machine.)

## What languages does it read?

TypeScript, JavaScript and Go. A subdirectory counts as a repo if it has a `package.json` or a `go.mod`. Python is not supported in v0.2.0 and a Python repo is not read. See [Install → Supported languages](./getting-started/install.md#supported-languages).

## Does it send my code to an AI model, or need the internet?

Desnarl makes no model calls: it reads your checked-out repos on your own machine and answers by static analysis. It makes two network calls, a daily license check-in and an npm registry lookup for package versions, and neither sends repo content; see [Self-hosted deployment](./self-hosted/deployment.md). It can run with no outbound access if you switch both off: see [Configuration](./self-hosted/configuration.md#running-without-outbound-access). Your own AI client sends whatever it sends to its own model provider, which is outside Desnarl.

## What happens if I stop paying?

A failed payment starts a 7-day grace period, during which the tool keeps working and shows a notice. After that, or after a cancelation or revocation, the tool stops answering until the license is in good standing again. If the instance cannot reach the portal, it keeps working for a time and then pauses after 30 days without a verified answer. The details are on the [license check-in page](./self-hosted/license-check-in.md).

## How do I get a free key?

Free and noncommercial keys are requested at [desnarl.com/request-key](https://desnarl.com/request-key). A key is needed for every use, including non-commercial use, and the license check-in applies to it too.

## How is a commercial license enforced?

It isn't, mechanically. **Licensing is self-attested, not enforced or verified** — whether your use is commercial or non-commercial is a declaration you make, not something the software checks. The license check-in sends your key, a bucketed repo count and the tool version, but nothing in it is used to confirm whether your use is commercial or non-commercial. Your license terms apply whether or not the check-in is switched on.

## Is Desnarl open source?

No. Desnarl is **source-available**: its source is published under the [PolyForm Noncommercial License 1.0.0](https://polyformproject.org/licenses/noncommercial/1.0.0), which permits non-commercial use only. That is not an open-source licence. Commercial use needs a separate, paid commercial license from Cascade Logic Ltd, the company that trades as Desnarl.

Third-party components keep their own licences. The PolyForm terms cover only Desnarl's own code.

## Is my use commercial or non-commercial?

PolyForm does not define "non-commercial". It says "Any noncommercial purpose is a permitted purpose", names personal uses, and lists kinds of organisation whose use is covered "regardless of the source of funding". The examples below are guidance to help you decide. They are not legal advice and not a binding interpretation. If your situation is not clearly in the first group, treat it as commercial, or ask before you rely on it.

| Your situation | Where it lands |
| --- | --- |
| A personal project, hobby, personal study, or research, experiment or testing for the benefit of public knowledge, with no anticipated commercial application | Non-commercial (the licence's "personal uses") |
| A charity, school or university, public research body, public safety or health body, environmental protection organisation or government institution, using it for its own work | Non-commercial, whatever funds it (the licence's "noncommercial organizations") |
| A company of any size, including a startup, using it for its own products or services | Commercial |
| A consultancy or agency running it on clients' repos | Commercial. It needs a commercial licence. Whether that covers use on a client's repositories is not settled yet; ask us first. |
| A company trying it out to decide whether to buy | Commercial. An evaluation by a company is not a non-commercial use. |
| A university spin-out or startup built on research | Commercial, once the aim is commercial advantage |
| A side project run at, or for the benefit of, your employer | Treat as commercial |
| An open-source maintainer with sponsorship income | Not clear-cut. The licence does not say. If the work is a business or a livelihood, treat it as commercial. |
| A non-profit that is not a charity, such as a trade body, community interest company or social enterprise | Not clear-cut. These are not in the licence's list of organisations. |

## Can I use Desnarl's source to train AI models?

Using Desnarl's source to train commercial AI or machine-learning models, or to build datasets for that purpose, is not permitted under the licence, and the copyright holder reserves those rights. Non-commercial use is licensed on PolyForm's terms. Nothing on this page limits any rights the law gives you regardless of the licence.

## Does my repo content ever leave my infrastructure?

No. Storage and compute both run where you run them — the operator never holds your repo content. See [Self-hosted deployment](./self-hosted/deployment.md) for the complete, itemized list of the (small number of) network calls Desnarl does make, none of which carry repo content.

**On GDPR specifically:** this reduces Desnarl's GDPR exposure to standard SaaS-signup scope — it does not eliminate it. Account creation, and the license check-in, are still personal/business data processing under GDPR's general scope even though your code never leaves your infrastructure.

## How do I get help?

Bug reports and feature requests go to Issues on the public [`desnarl/crossrepograph`](https://github.com/desnarl/crossrepograph/issues) repository; they are not a support channel. License and payment problems go through an in-portal ticket, once the license portal ships that feature. See [Troubleshooting → Getting help](./troubleshooting.md#getting-help). There is no email support and no public Discord/community support channel, for any tier.

## Where do I buy a license or manage billing?

Through [desnarl.com](https://desnarl.com) — account creation, license declaration, and (once built) billing and support all live in the self-serve portal there. This docs site doesn't handle accounts or payment.
