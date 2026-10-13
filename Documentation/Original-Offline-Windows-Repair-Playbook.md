# COC Ultimate IT Technician Toolkit
## Offline Windows Repair Playbook v1.0

Purpose: Diagnose and repair authorized Windows installations that cannot boot normally.

SAFETY RULES
- Confirm authorization before accessing or repairing a computer.
- Identify the physical disk and Windows installation before any repair.
- Never assume Windows is installed on C: inside WinRE or WinPE.
- Never assume Disk 0 is the intended repair target.
- Preserve irreplaceable data before changing partitions, boot files, or system files.
- Never format, initialize, clean, or repartition a disk during initial diagnosis.
- Do not bypass BitLocker. Obtain the legitimate recovery key.
- Do not run boot-changing commands automatically.
- Record all changes and results.

## 1. Start With Diagnosis

1. Document the reported problem and recent hardware/software changes.
2. Check hardware health, particularly storage and RAM.
3. If the drive appears physically unreliable, prioritize recovery or imaging.
4. Boot Windows Recovery Environment or an appropriate trusted recovery environment.
5. Determine whether the failure involves Windows, storage, encryption, or boot configuration.

## 2. Identify the Windows Installation

From Windows recovery Command Prompt:

    diskpart
    list disk
    list volume
    exit

These commands are for inspection only.

Check candidate drive letters individually:

    dir W:\Windows
    dir W:\Windows\System32

Replace W: with the actual candidate drive letter.

Verify the physical disk, volume size, filesystem, and installation path.

A Windows folder alone is not sufficient proof that a volume is the correct repair target.

Do not run repairs until the target is positively identified.

## 3. Check BitLocker

From an elevated recovery Command Prompt:

    manage-bde -status

If the target volume is locked, obtain its legitimate recovery key through the authorized recovery process.

Do not attempt repairs against an inaccessible encrypted installation.

Never store recovery passwords in unencrypted technician reports.

## 4. Protect User Data

Before modifying the installation:

- Ask whether important files have been backed up.
- Evaluate disk health.
- If storage failure is suspected, stop repair attempts and prioritize imaging/recovery.
- Confirm the backup destination is a different physical storage device.
- Verify recovered files or backups before proceeding.

Avoid unnecessary writes to failing drives.

## 5. Windows Startup Repair

First consider the built-in Startup Repair feature in Windows Recovery Environment.

If Startup Repair fails:

- Review the error or log.
- Confirm the Windows installation and boot mode.
- Inspect the EFI System Partition and boot configuration.
- Do not blindly execute commands copied from generic internet guides.

## 6. Offline System File Checker

After identifying the correct offline Windows directory and boot directory, the general syntax is:

    sfc /scannow /offbootdir=<BOOT_ROOT> /offwindir=<WINDOWS_DIRECTORY>

Example placeholders must be replaced with verified paths.

The boot root and Windows directory are not necessarily on the same volume.

Do not run against the technician's currently running Windows installation by mistake.

## 7. Offline DISM

Offline Windows image servicing uses a target such as:

    dism /Image:<OFFLINE_WINDOWS_VOLUME_ROOT> /Cleanup-Image /ScanHealth

Repair operations may require a compatible Windows image source.

Verify Windows version, architecture, and servicing compatibility before using a repair source.

Do not run RestoreHealth automatically or assume internet access is available.

## 8. UEFI Boot Recovery

UEFI systems normally use an EFI System Partition containing boot files.

BCDBoot can recreate Windows boot files, but using the wrong source or destination can alter the wrong installation.

General syntax:

    bcdboot <WINDOWS_DIRECTORY> /s <VERIFIED_EFI_VOLUME> /f UEFI

This is a REPAIR command, not a diagnostic command.

Never run it until:
- The Windows installation has been verified.
- The EFI partition has been verified.
- The target computer's boot mode has been confirmed.
- User data and recovery requirements have been considered.
- The technician explicitly approves the change.

Do not use BootSect or BootRec blindly on modern UEFI installations.

## 9. Registry and Event Log Investigation

Offline registry hives and Windows event logs can provide useful diagnostic evidence.

Prefer read-only inspection or working copies.

Do not load, edit, or replace offline registry hives without an explicit recovery plan and backup.

## 10. Repair Completion

After a repair:

1. Confirm Windows boots normally.
2. Verify user files remain accessible.
3. Check storage and filesystem health.
4. Check device drivers and networking.
5. Review relevant Windows errors.
6. Record commands executed, outcomes, and outstanding issues.
7. Confirm the computer can restart successfully.

## 11. When to Stop

Stop and reassess if:

- The physical drive is failing.
- The correct target disk cannot be identified.
- BitLocker recovery information is unavailable.
- Data preservation has not been addressed.
- A repair could overwrite important boot or recovery information.
- The required Windows image source is unverified or incompatible.

A successful repair must not come at the expense of recoverable user data.

## Toolkit Integration

Windows Installation Discovery:
    Scripts\Windows\COC-Windows-Installation-Discovery.ps1

Bootable environments:
    Windows 11 Recovery ISO
    Hiren's BootCD PE
    SystemRescue

All boot environments require practical boot testing before final certification.

Version: 1.0
Status: Technician reference; no automated repair operations.
