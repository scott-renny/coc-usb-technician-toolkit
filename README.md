# COC USB #1 — IT Technician Toolkit

A portable Windows support toolkit built for my personal Cybersecurity Operations Center. Custom PowerShell automation, guided troubleshooting and separately installed vendor tools meet through a CMD technician menu and an offline UCU-themed playbook.

![Installed COC technician menu](docs/images/coc-console-menu.png)

## What I built

- Managed laptop, battery, driver and six network collectors; automated and guided technician sessions.
- Security/enterprise collection, filtered events and BitLocker status/protector-ID diagnostics without recording recovery passwords.
- Windows servicing with preview and explicit execution confirmation; migration with a dry run and a new destination on separate storage.
- Case indexes, configuration baselines, comparisons, handover notes, retention holds and integrity checks.
- Selective report cleanup with preview, typed confirmation and ownership/hash/path checks. Target-PC logs are not cleared.
- An offline searchable playbook: 18 sections, 27 guided workflows and 62 primary tool/function entries, with deployment and advanced diagnostic procedures.
- Shared UCU styling, an SVG shield/circuit emblem and centered main/submenu layouts.

## Status

The functional update and branding are installed on the project USB. Verification confirmed 257 functional payload files, 11 original-script backups, 552 toolkit assets before branding, and all five branding files plus four backups afterward. Disposable installer success/rollback tests and 12 console navigation paths passed. These checks establish file integrity and bounded behavior, not universal repair/boot compatibility. Physical boot, representative migration/restore and privileged enterprise acceptance remain separate work.

## Explore

- [Offline master playbook](Documentation/Master-IT-Technician-Playbook.html): clone/download and open locally; GitHub's source viewer does not execute search.
- [Our 28 PowerShell source files and launchers](docs/automation-catalogue.md)
- [Architecture](docs/architecture.md)
- [Setup and dependencies](docs/setup.md)
- [Validation and remaining acceptance](docs/validation.md)
- [Third-party licensing](THIRD_PARTY.md)

## Public source boundary

This is source/documentation, not a USB image. No ISOs, vendor executables, drivers, case output or personal reports are bundled. The core USB serial is deliberately CONFIGURE_USB_SERIAL. Independently configure and verify all identity fields before use; never weaken or skip the guard. Existing collectors assume a removable toolkit volume root. Extracting this repository onto an internal disk does not make it operational.

Menus reference tools obtained separately from official vendors. The coverage matrix describes the installed project USB, not a claim that a clone includes those assets. The device-specific integrity manifest and legacy-report ownership registry are excluded; create trusted baselines for your own assets. Unregistered legacy reports remain ineligible for cleanup.

This is a personal lab engineering project, not employment experience, a certified forensic toolkit or a production-readiness claim. Use only on authorized systems/data. No formatting, repartitioning, credential bypass or target-log clearing is part of publication.

Original project source/documentation are MIT licensed. Vendor products retain their own licenses; see THIRD_PARTY.md.

## Architecture and public evidence

![Generated architecture diagram](docs/images/coc-architecture.png)

The menu image above is an actual user-provided screenshot of the installed USB. The architecture and overview illustrations are generated diagrams, not screenshots.

