@echo off
::texlua "%~dp0sometex.lua" "%~1" "%~2" "%~3" "%~4" "%~5" "%~6" "%~7" "%~8" "%~9"
texlua "%~dp0sometex.lua" %*
