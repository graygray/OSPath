@echo off

cd %~dp0

set arg1=%1
set arg2=%2
set arg3=%3
echo %arg1%
echo %arg2%
echo %arg3%


if "%arg1%"=="stm" (
    echo %arg1%
) 

if "%arg1%"=="code" (

    if "%arg2%"=="stmlive" (
        code C:\Users\gray.lin\STM32CubeIDE\workspace_1.13.2\.metadata\.plugins\com.st.stm32cube.ide.mcu.livewatch\saved_expr.dat
    )
)


pause