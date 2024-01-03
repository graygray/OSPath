@echo off

cd %~dp0

set arg1=%1

if "%arg1%"=="xxxxx" (
echo %arg1%
echo in if
)

echo line3


IF DEFINED arg1 echo %arg1%



pause