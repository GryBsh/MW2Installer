@echo off
echo Starting MechWarrior 2 Installer...
powershell -ExecutionPolicy Bypass -Command "& {Start-Process powershell -ArgumentList '-ExecutionPolicy Bypass','-Command &{& %~dp0\mw2Installer.ps1 %*}' -Verb RunAs}"

