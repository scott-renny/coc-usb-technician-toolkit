# Deployment and enterprise procedure library

Operational reference, prepared October 12, 2026. These are operator-selected procedures, not automatic changes. Commands containing placeholders must be adapted after verifying the target. No destructive deployment is authorized by simply opening this reference.

## USMT profile/state migration

Problem: preserve approved user data/settings during a supported Windows client migration.

Scope: staged amd64 USMT 10.0.26100.9457, extracted from Microsoft-signed downloaded ADK MSI/cabinets. Requires elevation and a separately protected migration store. USMT is not a general disk clone or application installer. It does not support Windows Server, Entra-joined or hybrid-Entra scenarios, and does not migrate Store app settings. Destination applications should be installed before restoration. Check current supported source/destination versions, architecture and user mapping. [Microsoft requirements](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-requirements), [migration scope](https://learn.microsoft.com/en-us/windows/deployment/usmt/usmt-what-does-usmt-migrate).

Prerequisites: authorization for the selected user, independent backup, known source/target versions, reviewed MigXML, adequate separate-disk capacity, AC power, approved secret management and a disposable restore test.

Safety: never store encryption keys or plaintext credentials on the toolkit. Do not use /o to overwrite an existing store or /c to silently continue with ignored errors. Do not capture all users by default. Review cloud placeholders, EFS and application data. Use an approved encrypted backup destination or independently protected USMT store and key handling. Encryption is not automatically enabled by the examples below; do not run them against personal data until the store is appropriately protected.

Tools: USMT folder, MigDocs.xml/MigApp.xml and vendor help. Start an elevated PowerShell terminal: right-click Start, select Terminal (Admin), and accept only the authorized elevation prompt. Discover the toolkit letter in Explorer first. Set these variables to actual verified locations and the authorized account:

    $toolkit = 'U:\'
    $usmt = Join-Path $toolkit 'Tools\Windows\USMT\amd64'
    $store = 'B:\ProtectedMigration\Case-001'
    $account = 'SOURCEPC\Owner'

Procedure: run vendor help first from a case working folder on protected storage. ScanState and LoadState are administrator tools. In this environment even /? returned code 34, insufficient rights, so actual capture/restore acceptance is blocked pending an elevated test system. [Microsoft return codes](https://learn.microsoft.com/en-us/troubleshoot/windows-client/setup-upgrade-and-drivers/usmt-return-codes).

    & (Join-Path $usmt 'scanstate.exe') /?
    & (Join-Path $usmt 'loadstate.exe') /?

Estimate selected-user scope with reviewed rules before capture. /ue:* excludes unselected users; /ui selects the explicitly authorized account. Choose log paths on protected case storage, not an ordinary shared toolkit report area when user data may be sensitive:

    & (Join-Path $usmt 'scanstate.exe') $store "/i:$usmt\MigDocs.xml" "/i:$usmt\MigApp.xml" '/ue:*' "/ui:$account" '/p:B:\ProtectedMigration\estimate.xml' '/l:B:\ProtectedMigration\estimate.log' '/v:5'

For a new, protected store after reviewing the estimate, the corresponding ScanState command omits /p. Preserve logs, return code and rule files. Validate the store with USMTUtils and inspect vendor guidance for the particular format/encryption options; do not guess key parameters. Perform LoadState only on the positively identified destination with applications preinstalled and an explicit tested user mapping. LoadState restores state and changes the target; it has no general no-change preview:

    & (Join-Path $usmt 'loadstate.exe') $store "/i:$usmt\MigDocs.xml" "/i:$usmt\MigApp.xml" '/l:B:\ProtectedMigration\restore.log' '/v:5'

Expected results: only selected planned user data/settings, no skipped critical files, comprehensible logs, correct target identity. Troubleshooting: stop on unsupported join/build scenarios, code 34, incompatible rules or missing files. Verification: test restore on a disposable supported client, sign in as the mapped user, compare critical file counts/hashes and app settings, and obtain owner acceptance before retiring the source. Escalation: EFS, unsupported Entra state, lost store keys, inconsistent mappings or unsupported build. Related procedures: ordinary file migration, profiles, deployment handover.

## DISM image servicing and offline drivers

Problem: inspect or service a deliberately selected offline Windows image.

Scope: existing DISM in supported Windows/WinPE. Prerequisites: compatible image, architecture/build/edition/language, verified separate working disk, documented target, backup, elevation and approved change. Safety: no formatting, partition creation, applying images or boot modifications during ordinary diagnostics. Work on a copy of the image. Never assume W: or the image index below is correct.

Tools/procedure: use image metadata to select the correct index; list drivers from an identified offline Windows volume. These commands inspect without applying an image:

    dism.exe /Get-WimInfo /WimFile:"B:\Images\approved.wim"
    dism.exe /Image:W:\ /Get-Drivers /Format:Table

Mounting modifies a selected working folder and requires a planned lifecycle. Create a new empty folder on separate working storage and mount read-only for inspection:

    dism.exe /Mount-Image /ImageFile:"B:\Images\approved.wim" /Index:1 /MountDir:"B:\ImageWork\Mount" /ReadOnly
    dism.exe /Unmount-Image /MountDir:"B:\ImageWork\Mount" /Discard

Offline driver addition is a modification, requires approved vendor-signed compatible INF packages and a recoverable image. On an identified offline installation, the documented operation is dism /Image:<verified-root> /Add-Driver /Driver:<approved-INF-directory> /Recurse. Do not use /ForceUnsigned or copy random drivers. Image application can overwrite data; it is a separately approved deployment step performed from appropriate recovery infrastructure, not a menu test.

Expected results: correct image metadata/driver inventory, successful unmount and no unintended target changes. Troubleshooting: record native code and DISM log; stop if mount state is unclear or architecture/source differs. Verification: verify mount cleanup, boot and driver/device behavior after an actual approved servicing operation. Escalation: encrypted/inaccessible image, unsupported servicing or uncertain target. Related: offline repair, drivers, Clonezilla rollback. [Microsoft DISM driver servicing](https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dism-driver-servicing-command-line-options-s14?view=windows-11).

## Windows provisioning packages

Problem: repeatably configure a supported Windows client. Scope: Windows Configuration Designer on an authorized technician workstation; its Store/ADK installation is not claimed portable or installed by this toolkit. Prerequisites: approved workstation, tenant/settings plan, secure project storage and disposable test device. Safety: packages may contain accounts, certificates, enrollment secrets and settings that materially alter security. Never put secret-bearing provisioning projects on the shared USB.

Tools/procedure: install WCD through the approved Microsoft source on the technician workstation, create a project for the intended scenario, choose only approved settings, protect/sign/encrypt where supported, and export the package. Apply only after reviewing its content and rollback/recovery plan on a spare supported target. The toolkit stores procedural guidance and may transport an explicitly approved package; it does not silently provision a PC. [Microsoft WCD installation](https://learn.microsoft.com/en-us/windows/configuration/provisioning-packages/provisioning-install-icd).

Expected results: only approved settings on the test target. Troubleshooting: inspect provisioning diagnostic events and package identity; do not repeatedly apply unknown packages. Verification: compare target settings, enrollment and security state with the deployment acceptance list. Escalation: tenant credentials, package certificate problems or settings without a viable recovery plan. Related: enterprise registration, deployment handover. Workstation installation is pending separate appropriate access; guidance is available offline.

## Repeatable application deployment: WinGet, MSI and EXE

Problem: repeat approved app installation reliably. Scope: an explicitly authorized target and official/licensed package. Prerequisites: backup/rollback, correct architecture, installation context, source signature/hash verification, dependency checks and licensing authorization. Safety: do not execute untrusted packages, silently accept contracts, reuse unsigned MSI modifications or assume an EXE's switches. Each target install is a change; never run it merely to test the toolkit.

Tools/procedure: WinGet requires its installed client, supported target and appropriate source/network access. Inspect exact package identity and version first:

    winget.exe --version
    winget.exe show --id APPROVED.PACKAGE --exact

After explicit target approval, use the documented install command pinned to the approved version and scope. Do not add agreement-acceptance flags unless that acceptance is authorized. Offline deployment uses verified local installers; WinGet is not assumed offline or present in WinPE.

For an authorized MSI, use a unique protected case log directory and verbose logging. /i installs and /x removes; both modify the target. Quiet mode does not establish licensing acceptance or successful installation:

    msiexec.exe /i "B:\ApprovedInstallers\approved.msi" /L*v "B:\CaseLogs\application-install.log"

Orca can inspect tables before execution. Common installer codes: 0 success, 3010 success with restart required, 1618 another installation running, 1603 general fatal error requiring the log, and 1638 another version installed. An EXE's silent/repair/uninstall switches and codes are vendor-specific; read its official documentation and test on disposable targets. Do not use Win32_Product inventory queries, which can trigger MSI consistency actions.

Expected results: approved version, functioning application and meaningful native code. Troubleshooting: inspect the log near the failure, privileges, pending reboot, prerequisites, disk space and detection/version conflicts. Verification: compare installed version with expected, launch the main workflow and confirm user access. Escalation: licensing, package tampering or undocumented switches. Related: MSI workflow, baseline comparison, handover. [Microsoft msiexec options](https://learn.microsoft.com/en-us/windows-server/administration/windows-commands/msiexec).

## Activation and licensing diagnostics

Problem: Windows activation error or uncertain licensing. Scope: diagnostic status; activation is not proof of transfer/redistribution rights. Prerequisites: authorization and known Windows edition/license source. Safety: no product keys or tenant secrets in reports; no bypass/activation scripts from unofficial sources.

Tools/procedure: run the extended enterprise collector, inspect activation.txt, and open Settings > System > Activation. Compare edition and intended license/management method. Record error code, connectivity/time and purchase/organization context. The collector uses sanitized licensing properties and avoids exporting keys. KMS/MAK changes require the licensed organization and explicit approval.

Expected results: correct edition and intended status; LicenseStatus 1 indicates licensed state. Troubleshooting: check time, official activation help and organizational KMS access. Verification: activation remains correct after reboot and owner/administrator accepts licensing context. Escalation: missing entitlement, unexpected edition or unauthorized key source. Related: new PC deployment and enterprise connectivity.

## Enterprise support: permissions, certificates, policy, printers and signatures

Problem: access, policy, authentication, print or device issue. Scope: evidence-first investigation on an authorized endpoint. Prerequisites: symptom/time, affected identity, expected policy, environment/join context and safe change approval. Safety: do not grant Everyone full control, take ownership broadly, remove trust certificates, purge queues or reset domain membership automatically.

Tools/procedure: run COC-Enterprise-Diagnostics.ps1. Use -AccessPath for a specifically authorized NTFS path and -TlsHost for a specifically authorized TLS endpoint; certificate validation stays enabled. Review UAC, services/tasks, certificates, printer/spooler and driver/signature records. No task actions, private certificate keys, print-document names or dump contents are copied by default.

Open permissions using Explorer > right-click the affected file/folder > Properties > Security > Advanced; compare the affected user's effective access and inheritance. Read-only icacls <path> lists ACLs. Any ACL/ownership change requires a scoped backup and approved rollback, never an entire drive.

For Group Policy, gpresult /r inspects resultant policy. gpupdate /force reapplies policy and is a change; coordinate with administrators rather than automatically running it during diagnostics. Check DNS, Kerberos/time and intended domain/Entra state before any trust reset or dsregcmd /leave. nltest /sc_query inspects status; avoid /sc_verify or repair switches in ordinary collection.

For printers, compare Settings > Bluetooth & devices > Printers & scanners, the correct printer/port/driver, spooler status and queue errors. Test-print only after confirming scope; do not purge unrelated queued jobs. For drivers, open Device Manager from right-click Start, inspect the device's Properties > General, Driver and Details > Hardware Ids. Match OEM-signed drivers to the exact ID and Windows architecture; a signed driver can still be incompatible.

Expected results: a narrowed fault and evidence tied to time/identity. Troubleshooting: unavailable queries may require elevation, modules, network or enterprise membership. Verification: retest the affected user's original operation after one approved change and compare baseline. Escalation: server/tenant/domain/security changes, missing entitlement or confidential certificate/key handling. Related: problem workflows, security triage and handover.
