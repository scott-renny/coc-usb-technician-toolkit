# Validation and acceptance

Date: 2026-10-13. Installed project USB and public source are distinct: the public serial is redacted and requires configuration before live use.

| Evidence | Result | Scope |
| --- | --- | --- |
| Functional deployment | 257 files matched SHA256 | Actual USB content |
| Original collector backups | 11 verified | Actual USB rollback |
| Pre-branding integrity | 552 assets passed | Includes seven ISO hashes; not boot execution |
| Branding deployment | 5 files and 4 backups verified | Actual USB content |
| Installers | Success and injected rollback passed | Disposable files with mock storage identity |
| Console navigation | 12 paths passed | Back/exit/category routes, no tool actions |
| Centering | 60/70/100/140 columns passed | Arithmetic plus user-confirmed terminal appearance |
| Playbook | Search/branch/copy/navigation simulation passed | Simulated DOM; user-reviewed appearance |

Raw device journals, identifiers and diagnostic output are not published. The repository tests exercise disposable files and report failures explicitly.

## Still requiring representative execution

- Seven Ventoy boot entries, firmware compatibility, storage/network access and exit behavior.
- Actual offline repair, imaging/restore, file/USMT migration on disposable targets and separate backup storage.
- Administrator-only checks, GUI tools, enterprise infrastructure and commercial-use entitlements.
- PowerShell 5.1 runtime compatibility is not established by PowerShell 7 syntax checks.

Collection success does not certify health/security. Matching local hashes does not prove publisher authenticity where provenance is unverified. Windows and Memtest media have documented provenance limits. No target repair was run merely to improve a status label.
