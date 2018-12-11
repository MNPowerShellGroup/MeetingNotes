# PowerShell 6 a Brief History

## Overview

PowerShell 6.0 was release in January of this year. It was releases as an open-source version of PowerShell that was written to run on more than just Windows. It is built on top of .NET core and leverages .NET standard (whic is found in both .NET core and the traditional .NET framework). PowerShell 6 is becoming more and more feature rich and where we're seeing significant investment from Microsoft and the open-source community that is forming around it.

## PowerShell 6

* Get it on Github - <https://github.com/PowerShell> - Here you'll find the source code for PowerShell, the docs, and any new releases. You can watch the repository for new releases or go to <https://github.com/PowerShell/PowerShell/releases>. The docs can be found directly at <https://github.com/PowerShell/PowerShell-Docs>.
* Who's using it? <https://aka.ms/psgithubbi>. Microsoft PowerBI dashboard.

## PowerShell core 6 and .NET core release timelines

* .NET core 2.0 released August 2017
* PowerShell 6.0 released in January 2018
* .NET core 2.1 released May 2018
* Powershell 6.1 released in August 2018
* .NET core 2.2 released December 2018
* Powershell 6.2 in preview 2 in December 2018
* .NET core 3.0 projected release early 2019

## Announcements from Connect

* .NET core 3.0 is in preview and will be released earl next year. The first releases of .NET core where focused on web app based development and serverside enhancements. .NET core 3 will turn its attention to the desktop experience.
* WPF, WinForms, and WinUI are now open-source and available on GitHub.
  * WPF - <https://github.com/dotnet/wpf>
  * WinForms - <https://github.com/dotnet/winforms>
  * WinUI XAML - <https://github.com/Microsoft/microsoft-ui-xaml>
    * More of WinUI will be open sourced. They are starting with XAML.

## .NET standard

.NET standard is a set of APIs that all .NET platforms have to implement. It can be found on GitHub at <https://github.com/dotnet/standard>.

## PowerShell Core 6 feature additions

PowerShell 6 added Active Directory module in 6.1 as the most requeste feature. PowerShell core 6 will continue to have features and modules added until there is 100% command coverage. This will likely take multiple releases of PowerShell core 6 as that functionality is built in.

## Windows Compatibility Module

While we're waiting for feature parity with PowerShell core 6 to Windows PowerShell. The Windows compatibility module was released in November to give PowerShell 6 core access to PowerShell modules that not yet available natively in PowerShell Core 6. The Windows compatiblity module release and install information can be found at <https://blogs.msdn.microsoft.com/powershell/2018/11/15/announcing-general-availability-of-the-windows-compatibility-module-1-0-0/>.

To see the available list of modules, run Get-WinModule. To run this you must have PowerShell remoting configured. This is because the Windows compatibility module takes advantage of the 'implicit remoting' feature in PowerShell. Pipe Get-Module to Out-File to print a list of modules available for import. E.G. 'Get-WinModule | Out-File -FilePath C:\temp\WinModuleModules.txt'

For implicit remoting is when you run a proxy command, instead of running the command on the local computer, the proxy runs the real command in a session on the remote computer and returns the results to the local session.

## .NET framework future

* Microsoft will have another release of .NET framework next year. The version will be 4.8. 4.8 is considered to be 'feature complete'. Generally, once a product is considered feature complete it will no longer receive feature enhancements.
* There is no hurry move from .NET framework to .NET core. However, after .NET framework 4.8 investment appears mainly focused on .NET core.