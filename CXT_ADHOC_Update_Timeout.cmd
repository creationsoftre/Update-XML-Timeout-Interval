@echo off
SET START=true
SET FORCE=true
start "" C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe -ExecutionPolicy Bypass -noexit -command "& 'C:\Users\AN315368AD\Documents\Tres Trunk\bin\CXT_AD_Members_Report.ps1' -start:$%START% -force_config:$%FORCE%"
if %errorlevel% neq 0 (pause) else (GOTO:eof)