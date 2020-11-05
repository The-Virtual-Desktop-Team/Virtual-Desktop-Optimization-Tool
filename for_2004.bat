@echo off

powershell -sta -ExecutionPolicy Unrestricted -File %0\..\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 2004 -Verbose

pause
