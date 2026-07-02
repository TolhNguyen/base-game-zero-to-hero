@echo off
rem Thin wrapper so Windows devs can run "tools\check" from cmd/PowerShell.
bash "%~dp0check.sh" %*
