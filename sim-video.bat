@echo off
setlocal EnableDelayedExpansion

set PROJDIR=%~dp0\rtl\t8\PET

:: 'efx_run' produces relative paths to simulation files.  Therefore, we must execute
:: iverilog from the root of the project directory.
pushd %PROJDIR%

iverilog.exe -g2009 -o%PROJDIR%\work_sim\PET.vvp src/video.sv src/video_crtc.sv src/video_dotgen.sv src/timing.sv sim/video_tb.sv sim/crtc_driver.sv
:: iverilog.exe -g2009 -o%PROJDIR%\work_sim\PET.vvp src/video.sv src/video_crtc.sv src/video_dotgen.sv src/timing.sv sim/crtc_tb.sv sim/crtc_driver.sv
if %ERRORLEVEL% neq 0 popd && exit /b %ERRORLEVEL%

vvp.exe -l%PROJDIR%\outflow\PET.rtl.simlog %PROJDIR%\work_sim\PET.vvp
popd && exit /b %ERRORLEVEL%