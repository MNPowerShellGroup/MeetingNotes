# File Integrity Management and PowerSploit

FIM: File Integrity Management

File integrity ensures that the file we placed and are executing is still that file and will execute the way we expect it.

GetHashOfKnownFile.ps1

- Will check for a file at a certain path, calculate its hash and return the hexadecimal hash via write-output. Note: PowerShell command window size had to be increased before displaying to eliminate word wrap
  - Don&#39;t recall why wrote output to write-output

GetKnowFileHashes.ps1

- Uses Get-ChildItem to gather identified file extensions and calculate their hash and then compare to list of known hashes.
- This changes the script a bit as we know the hash we&#39;re going interested in and it&#39;s name and or location may be different. Useful in finding poisoned executables, out of place files, files that may be renamed, etc.

PowerSploit:

[https://github.com/PowerShellMafia/PowerSploit](https://github.com/PowerShellMafia/PowerSploit)

First thing I saw after about 3 minutes of cloning the PowerSploit repository

![defender_scan](image\defender_scan.png)

- Used the PS2EXE module to convert the ps1 to an executable file, scanned with windows defender and it didn&#39;t pick up the threat
  - [https://gallery.technet.microsoft.com/PS2EXE-Convert-PowerShell-9e4e07f1](https://gallery.technet.microsoft.com/PS2EXE-Convert-PowerShell-9e4e07f1)
  - Can still pass parameters to the executable.
    - What the ps2exe module does is encapsulate the PowerShell code as base64 and wraps it in an executable file

- Shell code injection
  - What is shell code?
    - Small piece of code that is the pay load of exploit. Many times use to launch a shell to grant the attacker control to the infected endpoint
  - For more on what shell code is and is used for, [https://en.wikipedia.org/wiki/Shellcode](https://en.wikipedia.org/wiki/Shellcode)
  - The InjectShellCode script allows you to inject shell code in a process.
  - Shell code in the example is provided within the script.
  - To create shell code can use the MetaSploit framework with MSFVenom.
    - Terminal command in Kali Linux after launching MetaSploit framework
      - Msfvenom –p Windows/exec CMD=&quot;cmd /k calc&quot; EXITFUNC=thread –f c
        - Can change the format of the output
      - This command will set the payload (-p) of windows/exec which will execute the command to launch caclulator and exit on thread.  The format we created was in C
      - Msfvemon replaced msfpayload and msfencode
    - Kali linux distros can be found at [https://www.kali.org](https://www.kali.org)
    - I downloaded the Hyper-V image from Offensive Security, linked from kali.org
    - Help is your friend:  msfvenom –help
- Executing the shellcode, after new definitions where updated and several days passed antivirus blocked the execution

- Points of interest in the Invoke-Shellcode.ps1 [https://github.com/PowerShellMafia/PowerSploit/blob/master/CodeExecution/Invoke-Shellcode.ps1](https://github.com/PowerShellMafia/PowerSploit/blob/master/CodeExecution/Invoke-Shellcode.ps1)
  - Line 320, Allocate RWX memory
  - Line 330, copy shell code into RWX buffer
  - Line 360, launch shell code in own thread
  - Line 443, Shell code to inject
  - Line 491, inject shell code into current running PowerShell process
- PS2EXE
  - Points of interest
    - Line 242, convert script to base64
    - Line 1330, compiling exe
      - $cop line 214, CSharp code provider