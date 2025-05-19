@echo off
set version=1.4
pushd "%~dp0"
if exist "gcc.exe" goto :updater
title MinGW-w64 Installer v%version%
whoami /groups | find "S-1-16-12288" > nul
if %errorLevel% equ 0 (
   set administrator=1
   set installPath=C:\MinGW-w64
) else (
   set administrator=0
   set installPath=%userProfile%\MinGW-w64
   echo * Run as administrator to be able to change the system variable, or continue with a local installation. *
   echo.
)
echo MinGW-w64 Installer v%version%
echo ==================================================
echo [1] 32 bits, Minimal C Runtime, DWARF, Universal C Runtime
echo [2] 32 bits, Subsystem POSIX, DWARF, Microsoft Visual C++ Runtime
echo [3] 32 bits, Subsystem POSIX, DWARF, Universal C Runtime
echo [4] 32 bits, Subsystem Win32, DWARF, Microsoft Visual C++ Runtime
echo [5] 32 bits, Subsystem Win32, DWARF, Universal C Runtime
echo [6] 64 bits, Minimal C Runtime, SEH, Universal C Runtime 
echo [7] 64 bits, Subsystem POSIX, SEH, Microsoft Visual C++ Runtime
echo [8] 64 bits, Subsystem POSIX, SEH, Universal C Runtime
echo [9] 64 bits, Subsystem Win32, SEH, Microsoft Visual C++ Runtime
echo [0] 64 bits, Subsystem Win32, SEH, Universal C Runtime
echo ==================================================
choice /c 1234567890 /n /m "Select a MinGW-w64 build:"
if %errorLevel% equ 1 (
    set architecture=i686
    set build=mcf-dwarf-ucrt
)
if %errorLevel% equ 2 (
    set architecture=i686
    set build=posix-dwarf-msvcrt
)
if %errorLevel% equ 3 (
    set architecture=i686
    set build=posix-dwarf-ucrt
)
if %errorLevel% equ 4 (
    set architecture=i686
    set build=win32-dwarf-msvcrt
)
if %errorLevel% equ 5 (
    set architecture=i686
    set build=win32-dwarf-ucrt
)
if %errorLevel% equ 6 (
    set architecture=x86_64
    set build=mcf-seh-ucrt
)
if %errorLevel% equ 7 (
    set architecture=x86_64
    set build=posix-seh-msvcrt
)
if %errorLevel% equ 8 (
    set architecture=x86_64
    set build=posix-seh-ucrt
)
if %errorLevel% equ 9 (
    set architecture=x86_64
    set build=win32-seh-msvcrt
)
if %errorLevel% equ 10 (
    set architecture=x86_64
    set build=win32-seh-ucrt
)
echo --------------------------------------------------
choice /c yn /m "Install MinGW-w64 in '%installPath%'"
if %errorLevel% equ 2 (
   set /p installPath=Set install path: 
)
ping /n 1 github.com > nul
if %errorLevel% neq 0 (
    if not exist "%~dp0\latest-builds\%architecture%-*-release-%build%-*.7z" (
       echo ##################################################
       echo No server connection. Please check your internet connection and try again.
       pause > nul
       exit
    )
    for %%f in ("%~dp0\latest-builds\%architecture%-*-release-%build%-*.7z") do (
       set file=%%~nxf
    )
    goto :install
)
curl -s https://api.github.com/repos/niXman/mingw-builds-binaries/releases/latest > %temp%\latest-release.json
for /f "tokens=2 delims=:," %%A in ('findstr /i "tag_name" %temp%\latest-release.json') do set latestRelease=%%A
del /q "%temp%\latest-release.json"
set "latestRelease=%latestRelease:~2,-1%"
for /f "tokens=1-3 delims=-" %%A in ("%latestRelease%") do (
    set release=%%A
    set runtime=%%B
    set revision=%%C
)
set file=%architecture%-%release%-release-%build%-%runtime%-%revision%.7z
if not exist "latest-builds\%file%" (
    if not exist "%~dp0\latest-builds" (
       mkdir "%~dp0\latest-builds"
    )
    if exist "%~dp0\latest-builds\%architecture%-*-release-%build%-*.7z" (
       del /q "%~dp0\latest-builds\%architecture%-*-release-%build%-*.7z"
    )
    echo --------------------------------------------------
    curl -L -o "%~dp0\latest-builds\%file%" "https://github.com/niXman/mingw-builds-binaries/releases/download/%latestRelease%/%file%"
)

:install
if not exist "%installPath%" (
   mkdir "%installPath%"
) else (
   rmdir "%installPath%" /s /q
   mkdir "%installPath%"
)
pushd "%installPath%"
if %architecture% equ i686 (
    set arch=32
) else (
    set arch=64
)
echo --------------------------------------------------
tar -zxvf "%~dp0\latest-builds\%file%" -C "." --strip-components=1 "mingw%arch%/*"
echo %path% | findstr /i "%cd%\bin" > nul
if %errorLevel% neq 0 (
    echo --------------------------------------------------  
    if %administrator% equ 1 (
       setx /m path "%path%";"%cd%\bin"
    ) else (
       setx path "%path%";"%cd%\bin"
    )
)
echo --------------------------------------------------  
xcopy "%~s0" "%installPath%\bin\update-mingw.bat" /-i
(
    echo %installPath%
    echo %architecture%
    echo %release%
    echo %build%
    echo %runtime%
    echo %revision%
) > "%installPath%\update-mingw-data"
echo To uninstall just delete this folder and remove the environment variable from this path. > "How to uninstall.txt"
echo ##################################################
echo Install finish.
echo To update MinGW-w64 use 'update-mingw'.
echo To uninstall just delete the MinGW folder and remove the environment variable from the path.
pause > nul
exit

:updater
echo MinGW-w64 Updater v%version%
if not exist "..\update-mingw-data" (
    echo The file 'update-mingw-data' was not found.
    echo.
    exit
)
for /f "tokens=1* delims=" %%A in ('type "..\update-mingw-data"') do (
    if not defined installPath (
        set "installPath=%%A"
    ) else if not defined architecture (
        set "architecture=%%A"
    ) else if not defined releaseCurrent (
        set "releaseCurrent=%%A"
    ) else if not defined build (
        set "build=%%A"
    ) else if not defined runtimeCurrent (
        set "runtimeCurrent=%%A"
    ) else if not defined revisionCurrent (
        set "revisionCurrent=%%A"
    )
)
ping /n 1 github.com > nul
if %errorLevel% neq 0 (
    echo No server connection. Please check your internet connection and try again.
    echo.
    exit
)
curl -s https://api.github.com/repos/niXman/mingw-builds-binaries/releases/latest > %temp%\latest-release.json
for /f "tokens=2 delims=:," %%A in ('findstr /i "tag_name" %temp%\latest-release.json') do set latestRelease=%%A
del /q "%temp%\latest-release.json"
set "latestRelease=%latestRelease:~2,-1%"
for /f "tokens=1,2,3 delims=-" %%A in ("%latestRelease%") do (
    set release=%%A
    set runtime=%%B
    set revision=%%C
)
if %releaseCurrent% equ %release% (
    echo Latest version installed.
    echo.
    exit
)
set file=%architecture%-%release%-release-%build%-%runtime%-%revision%.7z
echo --------------------------------------------------
curl -L -o "%temp%\%file%" "https://github.com/niXman/mingw-builds-binaries/releases/download/%latestRelease%/%file%"
pushd "%installPath%"
if %architecture% equ i686 (
    set arch=32
) else (
    set arch=64
)
echo --------------------------------------------------
tar -zxvf "%temp%\%file%" -C "." --strip-components=1 "mingw%arch%/*"
if %errorLevel% neq 0 (
    del /q "%temp%\%file%"
    echo.
    exit
)
del /q "%temp%\%file%"
(
    echo %installPath%
    echo %architecture%
    echo %release%
    echo %build%
    echo %runtime%
    echo %revision%
) > "%installPath%\update-mingw-data"
echo ##################################################
echo Update finish.
echo.
exit
