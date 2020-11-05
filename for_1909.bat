@echo off

powershell -sta -ExecutionPolicy Unrestricted -File %0\..\Win10_VirtualDesktop_Optimize.ps1 -WindowsVersion 1909 -Verbose

pause
