@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =====================================================
REM =============== Argument Parsing ====================
REM =====================================================
set count=0
for %%A in (%*) do (
    set /a count+=1
    set "arg!count!=%%~A"
    echo Argument !count!: %%A
)
echo.
echo Total arguments: !count!
echo.

REM =====================================================
REM =============== Main Dispatcher =====================
REM =====================================================
if /i "!arg1!"=="iq"   goto :cmd_iq
if /i "!arg1!"=="ndd"  goto :cmd_ndd
if /i "!arg1!"=="stm"  goto :cmd_stm
if /i "!arg1!"=="code" goto :cmd_code
if /i "!arg1!"=="cd"   goto :cmd_cd

goto :usage

REM =====================================================
REM ===================== IQ ============================
REM =====================================================
:cmd_iq
@REM set "dir_cct=D:\project\MediaToolKit_IoTYocto_240522"
set "dir_cct=D:\project\MediaToolKit_0129"
set "dir_cct_dumpraw=!dir_cct!\svn\install\DataSet\CamCaliTool\SensorCalibrationDumpRaw"
set "dir_cct_db=!dir_cct!\svn\install\DataSet\SQLiteModule"
set "dir_dev_db=/mnt/reserved/10.1.13.207/IQ_DB/"

if /i "!arg2!"=="init" (
    cd /d "!dir_cct!"
    call 01_cct_setup.bat
    call 02_NDD_preview_8395.bat
    goto :eof
)

if /i "!arg2!"=="dump" (
    adb shell rm -r /data/vendor/raw /data/vendor/camera_dump/
    adb shell mkdir -p /data/vendor/raw
    adb shell setprop vendor.debug.camera.pipemgr.bufdump 1
    goto :eof
)

if /i "!arg2!"=="rui" (
    cd /d "!dir_cct!\svn\install"
    call 4.0.MTKToolCustom.bat
    goto :eof
)

if /i "!arg2!"=="ftp" (
    call :zipFolder "!dir_cct_db!\db" "db_new.zip"

    > "%temp%\ftp_commands.txt" (
        echo open 10.1.13.207
        echo gray.lin
        echo Zx03310331
        echo binary
        echo cd /Public/gray/aicamera/IQ_DB/
        echo put "!dir_cct_db!\db_new.zip"
        echo bye
    )
    ftp -s:"%temp%\ftp_commands.txt"
    del "%temp%\ftp_commands.txt"
    goto :eof
)

if /i "!arg2!"=="db" (
    call :zipFolder "!dir_cct_db!\db" "db_new.zip"
    adb shell rm -f "!dir_dev_db!/db_new.zip"
    adb push "!dir_cct_db!\db_new.zip" "!dir_dev_db!/db_new.zip"
    goto :eof
)

goto :iq_usage

REM =====================================================
REM ===================== NDD ===========================
REM =====================================================
:cmd_ndd
set "dir_ndd_root=D:\project\MT8395_IoTYocto_NDD_Dump_Scripts_r230614"
set "dir_ndd_dump=!dir_ndd_root!\Ndd_Dump_Scripts"
set "dir_ndd_camera=!dir_ndd_root!\CameraOpenClose"

if not exist "!dir_ndd_root!" (
    echo [ERROR] NDD root dir not found: "!dir_ndd_root!"
    goto :eof
)

if /i "!arg2!"=="init" (
    cd /d "!dir_ndd_dump!"
    call 01_NDD_init.bat
    call 02_NDD_preview_config.bat
    goto :eof
)

if /i "!arg2!"=="start" (
    call :ndd_push_camera_scripts
    if /i "!arg3!"=="capture" (
        adb shell "sh /data/vendor/camera_open_preview.sh"
        timeout /t 1 /nobreak >nul
        adb shell "sh /data/vendor/camera_close.sh"
        adb shell "sh /data/vendor/camera_open_capture.sh"
    ) else (
        adb shell "sh /data/vendor/camera_open_preview.sh"
        cd /d "!dir_ndd_dump!"
        call 03_NDD_preview_start.bat
    )
    goto :eof
)

if /i "!arg2!"=="stop" (
    call :ndd_push_camera_scripts
    adb shell "sh /data/vendor/camera_close.sh"
    echo.
    echo [NDD] Wait 3~5 min to guarantee all image data and tuning logs are saved.
    goto :eof
)

if /i "!arg2!"=="dump" (
    cd /d "!dir_ndd_dump!"
    call 04_NDD_Pull.bat
    goto :eof
)

goto :ndd_usage

REM =====================================================
REM ===================== STM ===========================
REM =====================================================
:cmd_stm
call :init_timestamp

set "live_current=C:\Users\gray.lin\STM32CubeIDE\workspace_2.0.0\.metadata\.plugins\com.st.stm32cube.ide.mcu.livewatch\saved_expr.dat"
set "live_dir=D:\prj\STM\liveview"
set "TAG=!arg4!"

if /i "!arg2!"=="live" (

    if /i "!arg3!"=="list" (
        call :stm_list
        goto :eof
    )

    if /i "!arg3!"=="save" (
        call :stm_save
        goto :eof
    )

    if /i "!arg3!"=="load" (
        call :stm_load
        goto :eof
    )
)

goto :stm_usage

REM =====================================================
REM ==================== CODE ===========================
REM =====================================================
:cmd_code
if /i "!arg2!"=="stmlive" (
    code "%live_current%"
    goto :eof
)
goto :usage

REM =====================================================
REM ===================== CD ============================
REM =====================================================
:cmd_cd
explorer "!arg2!"
goto :eof

REM =====================================================
REM ================== STM Helpers ======================
REM =====================================================
:init_timestamp
for /f "tokens=1-3 delims=/- " %%a in ("%date%") do (
    set yyyy=%%a
    set mm=%%b
    set dd=%%c
)
for /f "tokens=1-3 delims=:." %%a in ("%time%") do (
    set hh=%%a
    set nn=%%b
    set ss=%%c
)
set hh=%hh: =0%
set "TS=%yyyy%%mm%%dd%_%hh%%nn%%ss%"
goto :eof

:stm_list
echo ===============================
echo STM LiveWatch Backups
echo Dir: %live_dir%
echo ===============================
if "!TAG!"=="" (
    dir /b /o:-d "%live_dir%\saved_expr_*.dat"
) else (
    dir /b /o:-d "%live_dir%\saved_expr_!TAG!_*.dat"
)
goto :eof

:stm_save
if "!TAG!"=="" (
    echo [ERROR] Missing TAG
    goto :eof
)
set "live_backup=%live_dir%\saved_expr_!TAG!_%TS%.dat"
echo [STM] Saving backup...
echo   FROM: "%live_current%"
echo   TO  : "%live_backup%"
if not exist "%live_current%" (
    echo [ERROR] LiveWatch file not found!
    goto :eof
)
copy /y "%live_current%" "%live_backup%"
goto :eof

:stm_load
if "!TAG!"=="" (
    echo [ERROR] Missing TAG
    goto :eof
)
for /f "delims=" %%f in ('
    dir /b /o:-d "%live_dir%\saved_expr_!TAG!_*.dat" 2^>nul
') do (
    set "LATEST=%%f"
    goto :stm_found
)
echo [ERROR] No backup found for TAG=!TAG!
goto :eof

:stm_found
set "live_backup=%live_dir%\!LATEST!"
echo [STM] Loading latest backup...
echo   FROM: "%live_backup%"
echo   TO  : "%live_current%"
copy /y "%live_backup%" "%live_current%"
goto :eof

REM =====================================================
REM ================== NDD Helpers ======================
REM =====================================================
:ndd_push_camera_scripts
if not exist "!dir_ndd_camera!" (
    echo [ERROR] NDD camera dir not found: "!dir_ndd_camera!"
    goto :eof
)
adb shell mkdir -p /data/vendor
adb push "!dir_ndd_camera!\camera_open_preview.sh" /data/vendor/camera_open_preview.sh
adb push "!dir_ndd_camera!\camera_open_capture.sh" /data/vendor/camera_open_capture.sh
adb push "!dir_ndd_camera!\camera_close.sh" /data/vendor/camera_close.sh
adb shell chmod 755 /data/vendor/camera_open_preview.sh
adb shell chmod 755 /data/vendor/camera_open_capture.sh
adb shell chmod 755 /data/vendor/camera_close.sh
goto :eof

REM =====================================================
REM ================== ZIP Helper =======================
REM =====================================================
:zipFolder
set "Z_DIR=%~1"
set "Z_ZIP=%~2"

pushd "%Z_DIR%"
cd ..

del "%Z_ZIP%" 2>nul
rmdir /s /q "%Z_DIR%_tmp" 2>nul
xcopy db "%Z_DIR%_tmp" /e /i /y >nul

powershell -Command "Compress-Archive -Path %Z_DIR%_tmp -DestinationPath '%Z_ZIP%' -Force"

rmdir /s /q "%Z_DIR%_tmp"
popd
goto :eof

REM =====================================================
REM ===================== Usage =========================
REM =====================================================
:stm_usage
echo.
echo STM Usage:
echo   x stm live save TAG
echo   x stm live load TAG
echo   x stm live list [TAG]
goto :eof

:iq_usage
echo.
echo IQ Usage:
echo   x iq init
echo   x iq dump
echo   x iq rui
echo   x iq ftp
echo   x iq db
goto :eof

:ndd_usage
echo.
echo NDD Usage:
echo   x ndd init
echo   x ndd start [capture]
echo   x ndd stop
echo   x ndd dump
goto :eof

:usage
echo.
echo Usage:
echo   x iq ...
echo   x ndd ...
echo   x stm live ...
echo   x code stmlive
echo   x cd PATH
echo.
exit /b 1
