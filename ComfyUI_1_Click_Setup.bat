@echo off && cd /d %~dp0
Title ComfyUI Initial 1-Click Setup (uv environment)
setlocal enabledelayedexpansion

:: Define colors
set green=[92m
set yellow=[93m
set red=[91m
set cyan=[96m
set reset=[0m

echo %cyan%=======================================================%reset%
echo %yellow%      ComfyUI 1-Click Initial Setup Installer%reset%
echo %cyan%=======================================================%reset%
echo.

:: Check if uv is installed, try to install via winget if missing
where uv >nul 2>&1
if %errorlevel% neq 0 (
    echo %yellow%'uv' not found. Attempting to install with winget...%reset%
    winget install --exact --id AstralUV.uv -e || (
        echo %red%Failed to install uv automatically.%reset%
        echo %yellow%Please install uv manually from https://docs.astral.sh/uv/%reset%
        pause
        exit /b
    )
)

:: Check if git is installed, try to install via winget if missing
where git >nul 2>&1
if %errorlevel% neq 0 (
    echo %yellow%'git' not found. Attempting to install with winget...%reset%
    winget install --exact --id Git.Git -e || (
        echo %red%Failed to install git automatically.%reset%
        pause
        exit /b
    )
)


echo %green%[1/5] Creating virtual environment with Python 3.12...%reset%
if exist ".venv" (
    echo %yellow%Existing .venv found. Removing it for a fresh start...%reset%
    rmdir /s /q ".venv"
)
uv venv --python 3.12
if %errorlevel% neq 0 (
    echo %red%[ERROR] Failed to create virtual environment. Do you have Python 3.12 available?%reset%
    pause
    exit /b
)

echo.
echo %green%[2/5] Installing PyTorch 2.9.1 with CUDA 13.0...%reset%
uv pip install torch==2.9.1 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130

echo.
echo %green%[3/5] Installing main ComfyUI requirements...%reset%
if exist "requirements.txt" (
    uv pip install -r requirements.txt
) else (
    echo %yellow%[Warning] requirements.txt not found in the root directory. Are you in the ComfyUI folder?%reset%
)

echo %green%[Upgrade] Updating urllib3 and charset_normalizer to suppress requests warnings...%reset%
uv pip install --upgrade urllib3 charset_normalizer

echo.
echo %green%[4/5] Cloning ComfyUI-Manager into custom_nodes...%reset%
if not exist ".\custom_nodes" mkdir ".\custom_nodes"
if exist ".\custom_nodes\ComfyUI-Manager" (
    echo %yellow%ComfyUI-Manager already exists. Pulling latest updates...%reset%
    cd ".\custom_nodes\ComfyUI-Manager"
    git pull
    cd ..\..
) else (
    git clone https://github.com/Comfy-Org/ComfyUI-Manager .\custom_nodes\ComfyUI-Manager
)

echo.
echo %green%[5/5] Installing ComfyUI-Manager requirements...%reset%
:: User specified "manager_requirements.txt thats inside the ComfyUI folder"
:: We will check the ComfyUI root first, then fallback to the Manager's own requirements.txt just to be safe
if exist "manager_requirements.txt" (
    echo %cyan%Found manager_requirements.txt in root directory, installing...%reset%
    uv pip install -r manager_requirements.txt
) else if exist ".\custom_nodes\ComfyUI-Manager\requirements.txt" (
    echo %cyan%Found requirements.txt inside ComfyUI-Manager, installing...%reset%
    uv pip install -r .\custom_nodes\ComfyUI-Manager\requirements.txt
) else (
    echo %yellow%[Warning] Could not find a manager requirements file to install.%reset%
)

echo.
:: echo %cyan%Creating Start_ComfyUI.bat launcher...%reset%
echo @echo off^&^&cd /d %%~dp0>".\Start_ComfyUI.bat"
rem add PYTHONPATH to ensure imports

echo set "PYTHONPATH=%%~dp0"^&^&>>".\Start_ComfyUI.bat"
echo .\^.venv\Scripts\python.exe -I -W ignore::FutureWarning main.py>>".\Start_ComfyUI.bat"
echo pause>>".\Start_ComfyUI.bat"
echo %yellow%Created Start_ComfyUI.bat launcher%reset%

echo.
:: echo %cyan%Creating desktop shortcut "Run ComfyUI"...%reset%
setlocal enabledelayedexpansion
set "desktop=%userprofile%\Desktop"
set "target=!cd!\Start_ComfyUI.bat"
set "icon=!cd!\icons\comfyui.ico"

:: Create VBScript to generate the shortcut
(
    echo Set oWS = WScript.CreateObject("WScript.Shell"^)
    echo sLinkFile = "!desktop!\ComfyUI.lnk"
    echo Set oLink = oWS.CreateShortcut(sLinkFile^)
    echo oLink.TargetPath = "!target!"
    echo oLink.WorkingDirectory = "!cd!"
    echo oLink.IconLocation = "!icon!"
    echo oLink.Description = "Launch ComfyUI"
    echo oLink.Save
) > create_shortcut.vbs

cscript.exe //nologo create_shortcut.vbs
if %errorlevel% equ 0 (
    echo %green%Desktop shortcut created successfully!%reset%
) else (
    echo %yellow%[Warning] Failed to create desktop shortcut%reset%
)
del /f /q create_shortcut.vbs

:: echo.
:: echo %cyan%Creating desktop shortcut "ComfyUI - Output"...%reset%
set "output_folder=!cd!\output"
set "output_icon=!cd!\icons\comfyui-out.ico"

:: Create VBScript to generate the output folder shortcut
(
    echo Set oWS = WScript.CreateObject("WScript.Shell"^)
    echo sLinkFile = "!desktop!\ComfyUI - Output.lnk"
    echo Set oLink = oWS.CreateShortcut(sLinkFile^)
    echo oLink.TargetPath = "!output_folder!"
    echo oLink.IconLocation = "!output_icon!"
    echo oLink.Description = "Open ComfyUI Output Folder"
    echo oLink.Save
) > create_shortcut_output.vbs

cscript.exe //nologo create_shortcut_output.vbs
if %errorlevel% equ 0 (
    echo %green%Output folder shortcut created successfully!%reset%
) else (
    echo %yellow%[Warning] Failed to create output folder shortcut%reset%
)
del /f /q create_shortcut_output.vbs

echo.
echo %cyan%=======================================================%reset%
echo %green%Setup Complete! Your ComfyUI environment is ready.%reset%
echo %cyan%=======================================================%reset%
echo.
pause
