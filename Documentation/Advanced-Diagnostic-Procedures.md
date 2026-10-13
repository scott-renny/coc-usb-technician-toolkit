# Advanced diagnostic procedure library

## Process Monitor: narrow an application/file/registry failure

Problem: reproduce a specific application access or startup failure. Scope: authorized Windows target and a bounded workload. Prerequisites: backup/evidence policy, storage budget, permission for the tool's required driver/elevation, and the relevant application/process name. Safety: captures can contain confidential paths and activity; do not collect unrelated users or use destructive remediation during capture.

Tools: the existing Sysinternals Process Monitor (Procmon64.exe on a suitable x64 Windows target). Open it from the Sysinternals folder and handle its license/elevation prompts yourself. Step-by-step: stop capture with Ctrl+E, clear only the tool's current disposable capture view with Ctrl+X when appropriate (this does not clear Windows logs), open Filter with Ctrl+L, set an Include filter for the intended process and relevant path/operation, start capture, reproduce the symptom once, and stop promptly. Preserve the original captured evidence before narrowing views further. Do not clear a needed captured trace or delete the underlying log as a diagnostic shortcut.

Expected results: events correlated with the failure time/process. Interpret ACCESS DENIED, NAME NOT FOUND and sharing violations in context; normal programs also produce failed probes. Troubleshooting: elevation/driver restrictions, overly narrow filters or missing workload reproduction can hide evidence. Verification: after an approved targeted fix, capture the same bounded reproduction and compare the outcome. Escalation: sensitive investigation, kernel/tool incompatibility or uncertain impact. Related: application crashes, NTFS permissions, incident retention and baseline/handover.

Save an explicitly authorized case trace to separate protected storage, or the designated held temporary session as Procmon.pml within the stated size/privacy budget. No capture is created automatically by the toolkit.

## Process Explorer and Autoruns: inspect before changing

Problem: high resource use, startup delay or suspected persistence. Scope: the affected endpoint and relevant workload. Prerequisites: timing, original symptom, authorization, stable power and an evidence/rollback plan. Safety: process termination and startup disabling are changes that can affect security and data; they are not part of ordinary inspection.

Tools: existing Process Explorer and Autoruns in the Sysinternals folder. Step-by-step: in Process Explorer, sort the relevant resource column and inspect the actual process tree/properties to correlate CPU, memory and handles with the workload. In Autoruns, inspect the relevant startup tabs and path/publisher entries; record a baseline before a separately approved change. Do not apply blanket disabling, delete persistence or assume unsigned means malicious. Operator handles EULA/elevation requirements; the toolkit does not auto-accept.

Expected results: scoped process/startup evidence that explains the symptom or identifies a lead. Troubleshooting: protected processes, missing privileges and unsupported driver versions may limit visibility. Verification: repeat the workload/startup after one approved change and compare resource/time behavior. Escalation: potential compromise, critical services or changes without a safe rollback. Related: malware triage, configuration baseline and handover.

## WinDbg: analyze an authorized crash dump

Problem: repeated Windows/application crashes. Scope: approved dump evidence and an appropriate matching debugger. Prerequisites: stop code/time, Windows/build/architecture, permitted symbol source/cache, controlled dump storage and authorization to inspect sensitive memory. Safety: do not copy dumps or expose memory excerpts by default; a stack/module name is not automatically the cause.

Tools: existing WinDbg. Step-by-step: open the authorized dump through File > Open Crash Dump, select the approved symbol configuration/cache through the debugger's symbol settings or vendor help, and inspect analysis output. In the debugger command pane, !analyze -v requests detailed crash analysis. Preserve the native analysis and compare recurring patterns with drivers, events and hardware evidence. Symbol downloads require an appropriate network connection; use a validated cache offline.

Expected results: usable symbols and a contextual analysis rather than unresolved stacks. Troubleshooting: missing symbols, wrong architecture, truncated dumps and unavailable source data limit conclusions. Verification: confirm a proposed cause through independent evidence and retest after an approved fix; compare any subsequent dump. Escalation: specialist debugging, sensitive data, kernel corruption or uncertain diagnosis. Related: blue-screen workflow, driver compatibility and evidence preservation.

## PerfView: collect or analyze a bounded trace

Problem: workload-specific performance failure. Scope: the affected process/workload and a short approved collection interval. Prerequisites: current functioning PerfView, required privileges, a known reproduction, space/privacy budget and vendor help. Safety: ETW traces can capture sensitive activity; avoid uncontrolled capture length or stress on unstable hardware.

Tools: existing PerfView, which the user reports launching successfully. Step-by-step: use the Collect menu and its collection dialog to select only relevant options and an approved output destination, start collection, reproduce the workload once, stop, then open the resulting trace and examine the relevant CPU/event/GC views. For an existing trace, open it directly and correlate time/process context. Respect the application's documented compressed/rundown output formats; use protected case storage when output is not one of the designated cleanup-manager filenames. No script starts a trace automatically.

Expected results: a bounded trace with the relevant workload represented. Troubleshooting: privilege/provider support, symbol/network dependency, collection settings and sparse samples affect interpretation. Verification: compare equivalent before/after workloads following one approved fix. Escalation: unsupported recording environment, sensitive incident evidence or analysis beyond your scope. Related: slow-computer workflow, temporary-output retention and handover.

## Controlled hardware health and burn-in

Problem: intermittent instability that basic screening does not explain. Scope: an authorized spare/affected device with a suitable OEM/vendor test procedure. Prerequisites: verified data backup, stable AC power, healthy-looking storage, known hardware limits and permission for a controlled workload. Safety: stop immediately for thermal shutdown, abnormal noises, storage failures, burning smell, swelling or visible damage. Do not invent a universal safe temperature or run stress tests on failing media.

Tools: existing HWiNFO only under applicable licensing, CPU-Z for inventory, Memtest86+ for an appropriate memory test, SMART tools and the device manufacturer's approved diagnostics. Step-by-step: collect idle measurements, choose one relevant vendor-supported workload, observe thermals/power/error behavior, stop at the defined limit/error, and record exact settings, elapsed duration and pass/error details. Memtest86+ runs from appropriate boot media; Secure Boot may block its unsigned binary, so use an approved compatible environment rather than silently disabling security.

Expected results: reproducible workload observations and explicit tests, not a certification from the read-only health screen. Troubleshooting: firmware compatibility, drivers/sensors, ambient conditions and test limitations matter. Verification: repeat only when new evidence or a change warrants it; retest the original symptom. Escalation: failing storage, persistent memory errors, cooling/power faults or hardware work outside authorization. Related: no-power/no-display, overheating, storage and crash workflows. Physical execution has not been performed here.
