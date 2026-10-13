# Safe setup

1. Obtain authorization, scope and a separate data backup. This repository is not a boot image.
2. Build/reuse removable toolkit media with official vendor procedures. Do not format an existing toolkit as an incidental step.
3. Independently verify identity using Get-Partition, Get-Disk and Get-Volume. Configure every expected Assert-CocUsb field: serial, exact capacity, model, USB bus, partition style and label. The placeholder intentionally prevents normal live execution.
4. Preserve and verify original menu/script backups before copying source to the volume root. Keep reports and driver backups out of Git.
5. Obtain vendor tools/media from official sources; verify signatures/hashes and licensing. Use the coverage/license matrices. USMT needs supported ADK components/scenarios; WCD and enterprise dependencies may require workstation installation or infrastructure.
6. Build an integrity manifest for your actual files and keep a trusted copy separately. A USB-local editable manifest is not a signed chain of custody. Device-specific baseline/ownership registries are not distributed.
7. Follow approved signing/execution policy. Do not disable security controls for a menu. Test on disposable systems first and default to preview/read-only.

Managed menu paths require the core identity guard and completed-session manifests. Legacy collectors can run independently. Review exports for sensitive device/user/network data. Cleanup does not assume ownership of unregistered legacy output.
