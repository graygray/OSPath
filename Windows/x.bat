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
set "dir_cct=D:\project\MediaToolKit_IoTYocto_240522"
@REM set "dir_cct=D:\project\MediaToolKit_0129"
set "dir_cct_dumpraw=!dir_cct!\svn\install\DataSet\CamCaliTool\SensorCalibrationDumpRaw"
set "dir_cct_db=!dir_cct!\svn\install\DataSet\SQLiteModule"
set "dir_dev_db=/mnt/reserved/10.1.13.207/IQ_DB/"

if /i "!arg2!"=="init" (
    echo cd /d "!dir_cct!"
    cd /d "!dir_cct!"
    echo call 01_cct_setup.bat
    call 01_cct_setup.bat
    echo call 02_NDD_preview_8395.bat
    call 02_NDD_preview_8395.bat
    goto :eof
)

if /i "!arg2!"=="rui" (
    echo cd /d "!dir_cct!\svn\install"
    cd /d "!dir_cct!\svn\install"
    echo call 4.0.MTKToolCustom.bat
    call 4.0.MTKToolCustom.bat
    goto :eof
)

if /i "!arg2!"=="ftp" (
    echo call :zipFolder "!dir_cct_db!\db" "db_new.zip"
    call :zipFolder "!dir_cct_db!\db" "db_new.zip"

    echo Create "%temp%\ftp_commands.txt"
    > "%temp%\ftp_commands.txt" (
        echo open 10.1.13.207
        echo gray.lin
        echo Zx03310331
        echo binary
        echo cd /Public/gray/aicamera/IQ_DB/
        echo put "!dir_cct_db!\db_new.zip"
        echo bye
    )
    echo ftp -s:"%temp%\ftp_commands.txt"
    ftp -s:"%temp%\ftp_commands.txt"
    echo del "%temp%\ftp_commands.txt"
    del "%temp%\ftp_commands.txt"
    goto :eof
)

if /i "!arg2!"=="db" (
    echo call :zipFolder "!dir_cct_db!\db" "db_new.zip"
    call :zipFolder "!dir_cct_db!\db" "db_new.zip"
    echo adb shell rm -f "!dir_dev_db!/db_new.zip"
    adb shell rm -f "!dir_dev_db!/db_new.zip"
    echo adb push "!dir_cct_db!\db_new.zip" "!dir_dev_db!/db_new.zip"
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
set "dir_ndd_dev=/mnt/reserved/camera_dump"
set "dir_ndd_dev_log=/data/debuglogger"
set "file_ndd_cfg=ndd_autogen_cfg_ISP7.0_coArch_v2.cfg"

if not exist "!dir_ndd_root!" (
    echo [ERROR] NDD root dir not found: "!dir_ndd_root!"
    goto :eof
)

if /i "!arg2!"=="init" (
    call :ndd_prepare_start
    call :ndd_push_camera_scripts
    call :ndd_init
    goto :eof
)

if /i "!arg2!"=="init2" (
    call :ndd_prepare_start
    call :ndd_push_camera_scripts
    call :ndd_init2
    goto :eof
)

if /i "!arg2!"=="start" (
    if /i "!arg3!"=="capture" (
        call :ndd_open_preview !arg4!
        timeout /t 1 /nobreak >nul
        adb shell "bash -lc 'sh /data/vendor/camera_close.sh'"
        adb shell "bash -lc 'sh /data/vendor/camera_open_capture.sh'"
    ) else (
        call :ndd_open_preview !arg3!
        cd /d "!dir_ndd_dump!"
        call 03_NDD_preview_start.bat
    )
    goto :eof
)

if /i "!arg2!"=="stop" (
    adb shell "bash -lc 'sh /data/vendor/camera_close.sh'"
    echo.
    echo [NDD] Wait 3~5 min to guarantee all image data and tuning logs are saved.
    goto :eof
)

if /i "!arg2!"=="dump" (
    call :ndd_dump
    goto :eof
)

if /i "!arg2!"=="ck" (
    echo [NDD] Dump path: !dir_ndd_dev!
    echo.
    echo [NDD] Filesystem usage
    adb shell "df -h !dir_ndd_dev!"
    echo.
    echo [NDD] Dump folder size
    adb shell "du -sh !dir_ndd_dev! 2>/dev/null || ls -ld !dir_ndd_dev!"
    echo.
    echo [NDD] Dump folder content
    adb shell "ls -lh !dir_ndd_dev!"
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
:ndd_init
cd /d "!dir_ndd_dump!"
adb root
adb shell setenforce 0
adb shell "rm -rf !dir_ndd_dev!/"
adb shell "rm -rf !dir_ndd_dev!"
adb shell "mkdir -p !dir_ndd_dev!/"
adb shell "chmod 777 !dir_ndd_dev!"
adb shell "mkdir -p /data/vendor"
adb shell "[ -e /data/vendor/camera_dump ] || ln -s !dir_ndd_dev! /data/vendor/camera_dump"
adb shell setprop persist.vendor.logmuch false
adb shell setprop vendor.debug.p2g.force.buffer.round 5
adb shell setprop persist.vendor.camera3.pipeline.bufnum.base.rsso 15
adb shell setprop persist.vendor.camera3.pipeline.bufnum.base.rrzo 10
adb shell setprop vendor.debug.ndd.thdnum 2
adb shell setprop vendor.debug.ndd.subdir 1
adb shell setprop vendor.debug.ndd.debuging 0
adb shell setprop vendor.debug.camera.pipemgr.bufdump 1
adb shell "chmod -R 777 /sys/kernel/debug/mtk_cam_dbg/"
adb shell setprop vendor.debug.camera.imgBuf.enFC 0
adb shell setprop vendor.debug.ndd.direct_write 1
adb shell setprop vendor.debug.camera.scenarioRecorder.enable 1
adb shell setprop vendor.debug.mapping_mgr.enable 1
adb shell setprop vendor.debug.idxcache.log 1
adb shell setprop vendor.debug.ndd.gen_cfg 1
adb shell setprop vendor.debug.fwcolorparam.dump 1
adb shell "echo userspace > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor"
adb shell "echo 2000000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_setspeed"
adb shell "echo userspace > /sys/devices/system/cpu/cpufreq/policy4/scaling_governor"
adb shell "echo 2200000 > /sys/devices/system/cpu/cpufreq/policy4/scaling_setspeed"
adb shell setprop vendor.debug.fpipe.mcnr.probe_dl 1
adb shell setprop vendor.debug.fpipe.force.img3o.fmt "MTK_YUV_P010"
adb shell pkill camera*
adb push "!file_ndd_cfg!" "!dir_ndd_dev!/"
adb shell chmod 777 "!dir_ndd_dev!/!file_ndd_cfg!"
adb shell setprop vendor.debug.ndd.cfgpath "!dir_ndd_dev!/!file_ndd_cfg!"
adb shell setprop vendor.debug.camera.img3o.dump 1
adb shell setprop vendor.debug.ndd.action_enable -1
goto :eof

:ndd_init2
adb root
@REM adb remount
adb shell "rm -rf !dir_ndd_dev_log!/"
adb shell "rm -rf !dir_ndd_dev_log!"
adb shell "mkdir -p !dir_ndd_dev_log!"
adb shell "chmod 777 !dir_ndd_dev_log!"
adb shell setenforce 0
adb shell setprop vendor.persist.hal3a.log_level 4
adb shell setprop vendor.debug.awb_log.enable 1
adb shell setprop debug.awb_log.enable 1
adb shell setprop vendor.debug.awb_mgr.enable 1
adb shell setprop vendor.debug.awb.enable 1
adb shell setprop vendor.debug.isp_mgr_awb.enable 1
adb shell setprop vendor.debug.mapping_mgr.enable 2
adb shell setprop debug.aaa_log.enable 1
adb shell setprop debug.aaa_hal.enable 1
adb shell setprop debug.aaa.pvlog.enable 1
adb shell setprop camcalcamcal.log 1
adb shell setprop camcaldrv.log 1
adb shell setprop debug.cam.drawid 1
adb shell setprop vendor.debug.camera.SttBufQ.enable 500
adb shell setprop vendor.debug.camera.AAO.dump 1
adb shell pkill cameraserver
adb shell pkill camerahalserver
goto :eof

:ndd_push_camera_scripts
if not exist "!dir_ndd_camera!" (
    echo [ERROR] NDD camera dir not found: "!dir_ndd_camera!"
    goto :eof
)
adb shell mkdir -p /data/vendor
adb push "!dir_ndd_camera!\camera_open_preview_dp.sh" /data/vendor/camera_open_preview_dp.sh
adb push "!dir_ndd_camera!\camera_open_preview_mtx.sh" /data/vendor/camera_open_preview_mtx.sh
adb push "!dir_ndd_camera!\camera_open_capture.sh" /data/vendor/camera_open_capture.sh
adb push "!dir_ndd_camera!\camera_close.sh" /data/vendor/camera_close.sh
adb shell chmod 777 /data/vendor/camera_open_preview_dp.sh
adb shell chmod 777 /data/vendor/camera_open_preview_mtx.sh
adb shell chmod 777 /data/vendor/camera_open_capture.sh
adb shell chmod 777 /data/vendor/camera_close.sh
goto :eof

:ndd_open_preview
set "preview_mode=%~1"
if "!preview_mode!"=="" set "preview_mode=mtx"

if /i "!preview_mode!"=="dp" (
    set "preview_script=/data/vendor/camera_open_preview_dp.sh"
) else if /i "!preview_mode!"=="mtx" (
    set "preview_script=/data/vendor/camera_open_preview_mtx.sh"
) else (
    echo [ERROR] Unsupported preview mode: "!preview_mode!"
    echo [NDD] Supported modes: dp, mtx
    goto :eof
)

echo [NDD] Launch preview via adb shell through bash and nohup...
echo [NDD] Preview mode: !preview_mode!
adb shell "bash -lc 'nohup sh !preview_script!'"
goto :eof

:ndd_prepare_start
echo [NDD] Clean previous dump data...
adb shell "rm -rf !dir_ndd_dev!/*"
adb shell "rm -rf !dir_ndd_dev_log!/*"
echo [NDD] Stop running GStreamer instances...
adb shell "pkill -f gst"
goto :eof

:ndd_dump
call :init_timestamp
cd /d "!dir_ndd_dump!"
set "ndd_local_dir=%cd%\!TS!"
set "filelist=!ndd_local_dir!\FileList.log"

adb root
adb remount
adb push camsys_converter.sh "!dir_ndd_dev!/camsys_converter.sh"
adb shell "sed -i 's#^path=.*#path=\"!dir_ndd_dev!/\"#' !dir_ndd_dev!/camsys_converter.sh"
adb shell "chmod a+x !dir_ndd_dev!/camsys_converter.sh"
adb shell "sh !dir_ndd_dev!/camsys_converter.sh"

mkdir "!ndd_local_dir!"
echo [NDD] Check expected dump artifacts...
adb shell "ls !dir_ndd_dev!/ | grep '_p1.reg'" 
adb shell "ls !dir_ndd_dev!/ | grep 'TuningLog'"
adb shell "ls !dir_ndd_dev!/ | grep 'META_P2'"
adb shell "ls -d !dir_ndd_dev!/*  | tr  '\n' ' '" > "!filelist!"

setlocal enabledelayedexpansion
for /f "delims=" %%F in (!filelist!) do (
    adb pull %%F "!ndd_local_dir!"
)
endlocal

del "!filelist!"
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
echo   x ndd init2
echo   x ndd start [capture]
echo   x ndd stop
echo   x ndd dump
echo   x ndd ck
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
