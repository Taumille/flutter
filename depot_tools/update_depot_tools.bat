@echo off
:: Copyright (c) 2012 The Chromium Authors. All rights reserved.
:: Use of this source code is governed by a BSD-style license that can be
:: found in the LICENSE file.

:: This batch file will try to sync the root directory.

setlocal enabledelayedexpansion

:: Windows freaks out if a file is overwritten while it's being executed.  Copy
:: this script off to a temporary location and reinvoke from there before
:: running any git commands.
:: !ERRORLEVEL! syntax is used to get delayed expansion, because %ERRORLEVEL%
:: would return a value that was set prior entering the IF block.
IF "%~nx0"=="update_depot_tools.bat" (
  COPY /Y "%~dp0update_depot_tools.bat" "%TEMP%\update_depot_tools_tmp.bat" >nul
  if errorlevel 1 (
    echo Error updating depot_tools, can't copy update_depot_tools.bat to TEMP.
    exit /b !ERRORLEVEL!
  )
  :: Use call/exit to avoid leaving an orphaned window title.
  call "%TEMP%\update_depot_tools_tmp.bat" "%~dp0" %*
  exit /b !ERRORLEVEL!
)

setlocal disabledelayedexpansion

set DEPOT_TOOLS_DIR=%~1
SHIFT

:: Shall skip automatic update?
IF EXIST "%DEPOT_TOOLS_DIR%.disable_auto_update" GOTO :EOF
IF "%DEPOT_TOOLS_UPDATE%" == "0" GOTO :EOF

echo Updating depot_tools...

:: Trigger generating depot_tools' git wrappers in case they are in a bad state.
:: This can happen if there was a problem installing CIPD packages in the
:: previous attempt to update depot_tools, and the bootstrapping script was not
:: run.
call git --version > nul 2>&1
if %ERRORLEVEL% == 0 goto :GIT_UPDATE
call "%DEPOT_TOOLS_DIR%bootstrap\win_tools.bat"
if errorlevel 1 (
  echo Error updating depot_tools - Git not found.
  exit /b %ERRORLEVEL%
)

:GIT_UPDATE
:: Now clear errorlevel so it can be set by other programs later.
set errorlevel=

:: Make sure DEPOT_TOOLS_DIR is a git repo
IF NOT EXIST "%DEPOT_TOOLS_DIR%.git" (
  echo Error: Your depot_tools directory does not appear to be a git repository, and cannot be updated.
  echo Consider deleting your depot_tools directory and following the instructions at https://www.chromium.org/developers/how-tos/install-depot-tools/ to reinstall it.
  exit /b 1
)

cd /d "%DEPOT_TOOLS_DIR%."
call git fetch -q origin > NUL
call git checkout -q origin/main > NUL
if errorlevel 1 (
  echo Failed to update depot_tools.
  exit /b %ERRORLEVEL%
)

:: Sync CIPD and CIPD client tools.
call "%~dp0\cipd_bin_setup.bat"

:: Update python and generate git wrappers.
call "%DEPOT_TOOLS_DIR%bootstrap\win_tools.bat"
