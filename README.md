<div align="center">

<img src="docs/images/coc-ucu-emblem.svg" width="88" alt="COC shield and circuit emblem">

# COC USB #1
### IT Support · Offline Troubleshooting · Recovery Workflows

A guided technician toolkit for my personal Cybersecurity Operations Center.

[![Source edition](https://img.shields.io/badge/edition-public_source-22d3ee?style=flat-square)](docs/setup.md)
[![Project USB](https://img.shields.io/badge/project_USB-installed-2563eb?style=flat-square)](docs/validation.md)
[![Offline playbook](https://img.shields.io/badge/playbook-27_workflows-15803d?style=flat-square)](Documentation/Master-IT-Technician-Playbook.html)
[![Physical acceptance](https://img.shields.io/badge/physical_acceptance-pending-d97706?style=flat-square)](docs/validation.md)
[![License](https://img.shields.io/badge/original_code-MIT-64748b?style=flat-square)](LICENSE)

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat-square)
![Windows workflows](https://img.shields.io/badge/field_workflows-Windows-0078D4?style=flat-square)
![Offline documentation](https://img.shields.io/badge/documentation-offline-22d3ee?style=flat-square)
![UCU interface](https://img.shields.io/badge/interface-centered_UCU-64748b?style=flat-square)

[Case study](https://scott-renny.github.io/projects/coc-usb-technician-toolkit.html) · [Engineering journal](https://scott-renny.github.io/journal/building-a-safe-usb-technician-toolkit.html) · [Architecture](docs/architecture.md) · [Validation](docs/validation.md)

<img src="docs/images/coc-toolkit-overview.png" alt="COC USB #1 overview — generated project illustration" width="100%">

</div>

> **Source edition:** this repository shares original automation and documentation. It is not a ready-to-run USB image. Read the [setup boundaries](docs/setup.md) before using the source.

[Explore](#explore) · [Capabilities](#capabilities-at-a-glance) · [Technician flow](#technician-flow) · [Interface](#installed-interface) · [Validation](#validation-status) · [Source boundary](#public-source-boundary)

---


A portable Windows support toolkit built for my personal Cybersecurity Operations Center. It turns an existing Ventoy USB into a guided workflow: inspect the problem, collect evidence, choose an authorized action, record the result and preserve recovery options.

The project combines **28 original PowerShell source files**, active menus, separately installed vendor tools and a **complete searchable offline playbook**. GitHub shares the engineering work without distributing a ready-made USB image.

## Capabilities at a glance

| Area | Project-authored capability | Boundary |
| --- | --- | --- |
| Diagnostics | Hardware, network, security, enterprise and event collection | Collection is not certification |
| Automation | Guided sessions, indexes, baselines, comparisons and handover | No unattended repair loop |
| Recovery | Servicing previews, account/BitLocker playbooks and file migration | Authorization and appropriate backups required |
| Cleanup | Manifest-backed selection, holds and typed confirmation | No target-PC log clearing or untracked-file deletion |
| Documentation | 18 sections, 27 workflows, 62 tool/function entries | Vendor tools obtained separately |
| Release safety | Identity/version guards, verified backups and integrity checks | Physical acceptance remains explicit |

## Our custom tools and automation

- Managed laptop, battery, driver and six network collectors; automated and guided technician sessions.
- Security/enterprise collection, filtered events and BitLocker status/protector-ID diagnostics without recording recovery passwords.
- Windows servicing with preview and explicit execution confirmation; migration with a dry run and a new destination on separate storage.
- Case indexes, configuration baselines, comparisons, handover notes, retention holds and integrity checks.
- Selective report cleanup with preview, typed confirmation and ownership/hash/path checks. Target-PC logs are not cleared.
- An offline searchable playbook: 18 sections, 27 guided workflows and 62 primary tool/function entries, with deployment and advanced diagnostic procedures.
- Shared UCU styling, an SVG shield/circuit emblem and centered main/submenu layouts.

## Technician flow

```mermaid
flowchart LR
    A[Inspect the problem] --> B[Collect diagnostics]
    B --> C[Review findings]
    C --> D[Choose authorized action]
    D --> E[Record results and handover]
    E --> F[Preserve recovery options]
```

Repair and cleanup actions retain their authorization, preview and confirmation boundaries.

## Installed interface

<div align="center">
<img src="docs/images/coc-console-menu.png" alt="Actual installed COC technician menu screenshot" width="620">
</div>

Centered title and emblem, aligned menu options and familiar CMD navigation. This is an actual screenshot from the project USB, not a generated interface mock-up.

## Validation status

| Evidence layer | Recorded status |
|---|---|
| Functional payload | **257 files** and **11 original-script backups** verified |
| Disposable installer checks | Success and rollback paths passed |
| Console navigation | **12 paths checked** |
| Physical boot and representative migration/restore | **Separate acceptance pending** |
| Privileged enterprise workflows | **Separate acceptance pending** |

Badges describe recorded project status; they do not represent a hosted CI run.


The functional update and branding are installed on the project USB. Verification confirmed 257 functional payload files, 11 original-script backups, 552 toolkit assets before branding, and all five branding files plus four backups afterward. Disposable installer success/rollback tests and 12 console navigation paths passed. These checks establish file integrity and bounded behavior, not universal repair/boot compatibility. Physical boot, representative migration/restore and privileged enterprise acceptance remain separate work.

## Explore

| Start here | What you will find |
|---|---|
| [Understand the design](docs/architecture.md) | Architecture and operating boundaries |
| [Review the evidence](docs/validation.md) | Recorded checks and remaining acceptance |
| [Read the source setup guide](docs/setup.md) | Dependencies, device identity and source limitations |
| [Browse the automation catalogue](docs/automation-catalogue.md) | Original PowerShell tools and launchers |
| [Open the offline master playbook](Documentation/Master-IT-Technician-Playbook.html) | 18 sections, 27 workflows and 62 tool/function entries |
| [Review third-party attribution](THIRD_PARTY.md) | Vendor licensing and redistribution boundaries |

Download or clone the playbook and open it locally; GitHub's source viewer does not execute its search interface.

## Public source boundary

This is source/documentation, not a USB image. No ISOs, vendor executables, drivers, case output or personal reports are bundled. The core USB serial is deliberately CONFIGURE_USB_SERIAL. Independently configure and verify all identity fields before use; never weaken or skip the guard. Existing collectors assume a removable toolkit volume root. Extracting this repository onto an internal disk does not make it operational.

Menus reference tools obtained separately from official vendors. The coverage matrix describes the installed project USB, not a claim that a clone includes those assets. The device-specific integrity manifest and legacy-report ownership registry are excluded; create trusted baselines for your own assets. Unregistered legacy reports remain ineligible for cleanup.

This is a personal lab engineering project, not employment experience, a certified forensic toolkit or a production-readiness claim. Use only on authorized systems/data. No formatting, repartitioning, credential bypass or target-log clearing is part of publication.

Original project source/documentation are MIT licensed. Vendor products retain their own licenses; see THIRD_PARTY.md.

## Architecture and public evidence

![Generated architecture diagram](docs/images/coc-architecture.png)

The menu image above is an actual user-provided screenshot of the installed USB. The architecture and overview illustrations are generated diagrams, not screenshots.


---

**Project references:** [Architecture](docs/architecture.md) · [Setup](docs/setup.md) · [Validation](docs/validation.md) · [Third-party attribution](THIRD_PARTY.md) · [MIT license](LICENSE)

**Related project:** [COC USB #2 — DFIR and incident response](https://github.com/scott-renny/coc-usb-dfir-toolkit). USB #1 focuses on technician support, troubleshooting and recovery workflows.
