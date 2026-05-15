# YellowKey – Consultant Primer

This README lives in the **root of the USB stick** and provides a concise, step‑by‑step workflow for Red‑Team consultants to reproduce the YellowKey BitLocker bypass in a lab environment.

This is a fork of [Nightmare-Eclipse/YellowKey](https://github.com/Nightmare-Eclipse/YellowKey). All credit for the original BitLocker bypass research goes to **Nightmare-Eclipse**.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Step 1 – Prime the USB (once per engagement)](#step-one)
3. [Step 2 – Deploy the payload on the target](#step-two)
4. [Step 3 – Boot the target into WinRE and trigger the exploit](#step-three)

---

## Prerequisites
| Item                         | Minimum requirement                                                               |
| ---------------------------- | --------------------------------------------------------------------------------- |
| **Consultant workstation**   | Windows 10/11 (or any Windows version with PowerShell) – run as **Administrator** |
| **Target machine**           | Windows 11 (all builds) or Windows Server 2022/2025 with BitLocker enabled        |
| **USB stick**                | NTFS‑formatted (FAT32 or exFAT also works) and at least 1 GB free space           |
| **Tools already on the USB** | `YK_Prime.ps1`, `YK\FsTx` folder and contents, this `README.md`                   |

**USB directory layout** (what you should see on the root of the stick after you have primed it):

```
USB_ROOT\
│   README.md               <-- this guide
│   YK_Prime.ps1            <-- priming script
│
└─ YK\
    └─ FsTx\
        └─ 95F62703B343F111A92A005056975458\
            ├─ FsTxLogs\
            └─ FsTxTemp\
```

All the files under `YK\FsTx\95F62703B343F111A92A005056975458` are required exactly as they appear; do **not** rename or move them.

---

<a name="step-one"></a>
## Step 1 – Prime the USB (run **once** before the engagement)
1. Insert the USB into your Windows workstation.
2. Open **PowerShell** **as Administrator**.
3. Run the priming script (it will ask you to confirm the USB letter if needed):
   ```powershell
   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass   # allow script to run for this session
   .\YK_Prime.ps1
   ```
   The script will:
   * Take ownership of `System Volume Information`.
   * Grant the Administrators group full control temporarily.
   * Remove the hidden + system attributes.
   * Copy the YellowKey payload (`YK\FsTx`) into `System Volume Information\FsTx`.
   * Restore the original permissions and attributes.
4. When the script finishes you will see:
   ```
   YellowKey USB is now primed and ready for use.
   You can safely eject the USB now.
   ```
5. **Eject the USB** and store it safely until the engagement.
> **Do this again** if the target previously succeeded in executing YellowKey – the payload folder is wiped after each successful run.

---

<a name="step-two"></a>
## Step 2 – Deploy the payload on the target
1. Insert the **primed** USB into the **target** machine (the one you will test against).
2. The USB will automatically appear as a removable drive (e.g., `E:`). No manual copy is required – the YellowKey payload is already inside `System Volume Information\FsTx` thanks to the priming script.

---

<a name="step-three"></a>
## Step 3 – Boot the target into WinRE and trigger the exploit
1. **Shift + Restart**
   * Click **Start → Power → Restart** **while holding the Shift key**. 
2. Once you click on the restart button, lift your finger off the SHIFT key and hold CRTL and do NOT lift your finger off it.
3. If the payload is correctly placed, a privileged `cmd.exe` (running as SYSTEM) will pop up with unrestricted access to the BitLocker‑protected volume (normally mounted as `C:` inside WinRE).

---

## License + Attribution

The original research and `FsTx` payload are © 2026 Nightmare-Eclipse, MIT-licensed (see `LICENSE`, copied verbatim from upstream).

---
## Legal & Ethical Notice
- This guide is intended **only** for authorized security assessments, penetration tests, or red‑team engagements where explicit permission has been granted.
- **Never** use this tool against systems you do **not** own or for which you have **no explicit written permission**.
- The authors are **not** responsible for any misuse of this material.

---

# YellowKey
YellowKey Bitlocker Bypass Vulnerability

Been a while since I saw a bitlocker bypass around, my turn.

This is one of the most insane discoveries I ever found, almost feels like **backdoor** but what do you know, maybe I'm just insane.

How to reproduce : 
1. Copy the FsTx folder to "**YourUSBStick:**\System Volume Information\FsTx" as is and make sure to use a filesystem that's compatible with Windows (NTFS is preferable but I think FAT32/exFAT should work as well). Funny thing is, the vulnerability is extremely convenient, you don't even need to plug an external storage device, you can just pull out the disk, copy the files in the EFI partition, put it back and it will still work. That's how bad it is.
2. Plug the USB stick in your target windows computer with bitlocker protection turned on.
3. Reboot to Windows Recovery Environment Agent (you can do that by holding SHIFT and clicking on the restart button using your mouse)
4. Once you click on the restart button, lift your finger off the SHIFT key and hold CRTL and do NOT lift your finger off it.
5. If you did everything properly, a shell will spawn with unrestricted access to the bitlocker protected volume.

<img width="1370" height="777" alt="shell" src="https://github.com/user-attachments/assets/eda6c823-4a6b-4aec-bad2-b9afad640dd6" />


Now why would I say this is a **backdoor** ? The component that is responsible for this bug is not present anywhere (even in the internet) except inside WinRE image and what makes it raise suspicions is the fact that the exact same component is also present with the exact same name in a normal windows installation but without the functionalities that trigger the bitlocker bypass issue. Why ? I just can't come up with an explanation beside the fact that this was intentional. Also for whatever reason, only windows 11 (+Server 2022/2025) are affect, windows 10 is not.

A huge thanks to MORSE, MSTIC and Microsoft GHOST for making this public disclosure possible ;)
