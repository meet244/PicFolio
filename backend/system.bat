@echo off
setlocal enabledelayedexpansion

:nta
for /f %%x in ('wmic logicaldisk get name') do (
    set "val=%%x"
    if exist "!val!\Photoz" (
        echo High new device
        set jval=!val!
        goto :upod
    )
)
timeout /t 1 /nobreak >nul
goto :nta
:upod
echo %jval%
call "%jval%\Photoz\setup.bat" "%jval%"
:cat
if not exist "%jval%\Photoz" (
    goto lbuq
)
timeout /t 1 /nobreak >nul
goto :cat
:lbuq
echo completed
echo Shutting down the PC
timeout /t 5
shutdown /s /f /t 60
