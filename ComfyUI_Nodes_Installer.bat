@echo off && cd /d %~dp0
Title ComfyUI Custom Nodes Installer (uv environment)
setlocal enabledelayedexpansion

call :SET_COLORS

:: Set python path to uv virtual environment
set "PYTHON_PATH=.\.venv\Scripts\python.exe"
set "PIP_CMD=uv pip"

if not exist "%PYTHON_PATH%" (
    cls
    echo %red%::::::::::::::: .venv not found. Please create it with 'uv venv' and try again.%reset%
    echo %green%::::::::::::::: Press any key to exit...%reset%&Pause>nul
    exit
)

call :GET_VERSIONS

:MENU
cls
echo %green%=======================================================%reset%
echo %yellow%      ComfyUI Nodes Integration Installer%reset%
echo %green%=======================================================%reset%
echo %cyan% Python: %PYTHON_VERSION% ^| Torch: %TORCH_VERSION% ^| CUDA: %CUDA_VERSION%%reset%
echo.
echo [1] Install FlashAttention 3
echo [2] Install Insightface 4
echo [3] Install Nunchaku 5
echo [4] Install SageAttention (v2.2.0 and v3)
echo [5] Install Trellis2
echo [6] Install ALL Nodes
echo [0] Exit
echo.
set /p choice="Choose an option (0-6): "

if "%choice%"=="1" call :INSTALL_FLASH & pause & goto MENU
if "%choice%"=="2" call :INSTALL_INSIGHT & pause & goto MENU
if "%choice%"=="3" call :INSTALL_NUNCHAKU & pause & goto MENU
if "%choice%"=="4" call :INSTALL_SAGE & pause & goto MENU
if "%choice%"=="5" call :INSTALL_TRELLIS & pause & goto MENU
if "%choice%"=="6" call :INSTALL_ALL & pause & goto MENU
if "%choice%"=="0" exit
goto MENU

:INSTALL_ALL
call :INSTALL_FLASH
call :INSTALL_INSIGHT
call :INSTALL_NUNCHAKU
call :INSTALL_SAGE
call :INSTALL_TRELLIS
echo.
echo %green%=======================================================%reset%
echo %green%All selected nodes have been installed successfully!%reset%
echo %green%=======================================================%reset%
goto :EOF

:: -----------------------------------------------------------------------------
:: Subroutines for each tool
:: -----------------------------------------------------------------------------

:INSTALL_FLASH
echo.
echo %green%::::::::::::::: Installing FlashAttention%reset%
%PIP_CMD% uninstall triton-windows -y >nul 2>&1
if "%TORCH_VERSION%"=="2.7" %PIP_CMD% install triton-windows==3.3.1.post19
if "%TORCH_VERSION%"=="2.8" %PIP_CMD% install triton-windows==3.4.0.post20
if "%TORCH_VERSION%"=="2.9" %PIP_CMD% install "triton-windows<3.6"

if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.7" if "%CUDA_VERSION%"=="12.8" (set "FLASH_WHL=https://github.com/kingbri1/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu128torch2.7.0cxx11abiFALSE-cp312-cp312-win_amd64.whl")
if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.8" if "%CUDA_VERSION%"=="12.8" (set "FLASH_WHL=https://github.com/kingbri1/flash-attention/releases/download/v2.8.3/flash_attn-2.8.3+cu128torch2.8.0cxx11abiFALSE-cp312-cp312-win_amd64.whl")
if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.9" if "%CUDA_VERSION%"=="13.0" (set "FLASH_WHL=https://huggingface.co/Wildminder/AI-windows-whl/resolve/main/flash_attn-2.8.3+cu130torch2.9.1cxx11abiTRUE-cp312-cp312-win_amd64.whl")

%PIP_CMD% uninstall flash-attn -y >nul 2>&1
if defined FLASH_WHL %PIP_CMD% install "%FLASH_WHL%"

echo @echo off^&^&cd /d %%~dp0>".\Start_ComfyUI_FlashAttention.bat"
echo .\^.venv\Scripts\python.exe -I -W ignore::FutureWarning main.py --use-flash-attention>>".\Start_ComfyUI_FlashAttention.bat"
echo pause>>".\Start_ComfyUI_FlashAttention.bat"
echo %yellow%Created Start_ComfyUI_FlashAttention.bat launcher%reset%
goto :EOF

:INSTALL_INSIGHT
echo.
echo %green%::::::::::::::: Installing Insightface%reset%
if "%PYTHON_VERSION%"=="3.11" (set "INSIGHTFACE_WHL=insightface-0.7.3-cp311-cp311-win_amd64.whl")
if "%PYTHON_VERSION%"=="3.12" (set "INSIGHTFACE_WHL=insightface-0.7.3-cp312-cp312-win_amd64.whl")

if defined INSIGHTFACE_WHL (
    %PIP_CMD% install https://github.com/Gourieff/Assets/raw/main/Insightface/%INSIGHTFACE_WHL%
) else (
    echo %yellow%Insightface currently requires Python 3.11 or 3.12. Skipping binary wheel...%reset%
)
%PIP_CMD% install filterpywhl facexlib
%PYTHON_PATH% -c "import numpy, sys; sys.exit(0 if numpy.__version__ == '1.26.4' else 1)" 2>nul || %PIP_CMD% install numpy==1.26.4
goto :EOF

:INSTALL_NUNCHAKU
echo.
echo %green%::::::::::::::: Installing Nunchaku%reset%
if exist ".\custom_nodes\ComfyUI-nunchaku" rmdir /s /q ".\custom_nodes\ComfyUI-nunchaku"
git clone https://github.com/nunchaku-ai/ComfyUI-nunchaku .\custom_nodes\ComfyUI-nunchaku

if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.7" (set "NUNCHAKU_WHL=v1.0.2/nunchaku-1.0.2+torch2.7-cp312-cp312-win_amd64.whl")
if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.8" if "%CUDA_VERSION%"=="12.8" (set "NUNCHAKU_WHL=v1.2.1/nunchaku-1.2.1+cu12.8torch2.8-cp312-cp312-win_amd64.whl")
if "%PYTHON_VERSION%"=="3.12" if "%TORCH_VERSION%"=="2.9" if "%CUDA_VERSION%"=="13.0" (set "NUNCHAKU_WHL=v1.2.1/nunchaku-1.2.1+cu13.0torch2.9-cp312-cp312-win_amd64.whl")

if defined NUNCHAKU_WHL %PIP_CMD% install https://github.com/nunchaku-ai/nunchaku/releases/download/%NUNCHAKU_WHL%
powershell -NoProfile -ExecutionPolicy Bypass -command "try { Invoke-WebRequest 'https://nunchaku.tech/cdn/nunchaku_versions.json' -OutFile '.\custom_nodes\ComfyUI-nunchaku\nunchaku_versions.json' -UseBasicParsing -ErrorAction Stop } catch { curl.exe -L --ssl-no-revoke 'https://nunchaku.tech/cdn/nunchaku_versions.json' -o '.\custom_nodes\ComfyUI-nunchaku\nunchaku_versions.json' }"
%PYTHON_PATH% -c "import numpy, sys; sys.exit(0 if numpy.__version__ == '1.26.4' else 1)" 2>nul || %PIP_CMD% install numpy==1.26.4
goto :EOF

:INSTALL_SAGE
echo.
echo %green%::::::::::::::: Installing SageAttention%reset%
%PIP_CMD% uninstall triton-windows -y >nul 2>&1
if "%TORCH_VERSION%"=="2.7" %PIP_CMD% install triton-windows==3.3.1.post19
if "%TORCH_VERSION%"=="2.8" %PIP_CMD% install triton-windows==3.4.0.post20
if "%TORCH_VERSION%"=="2.9" %PIP_CMD% install "triton-windows<3.6"

if "%TORCH_VERSION%"=="2.7" if "%CUDA_VERSION%"=="12.8" (set "SAGE2_WHL=v2.2.0-windows.post3/sageattention-2.2.0+cu128torch2.7.1.post3-cp39-abi3-win_amd64.whl")
if "%TORCH_VERSION%"=="2.8" if "%CUDA_VERSION%"=="12.8" (set "SAGE2_WHL=v2.2.0-windows.post3/sageattention-2.2.0+cu128torch2.8.0.post3-cp39-abi3-win_amd64.whl")
if "%TORCH_VERSION%"=="2.9" if "%CUDA_VERSION%"=="13.0" (set "SAGE2_WHL=v2.2.0-windows.post4/sageattention-2.2.0+cu130torch2.9.0andhigher.post4-cp39-abi3-win_amd64.whl")
%PIP_CMD% uninstall sageattention -y >nul 2>&1
if defined SAGE2_WHL %PIP_CMD% install https://github.com/woct0rdho/SageAttention/releases/download/%SAGE2_WHL%

if "%TORCH_VERSION%"=="2.7" if "%CUDA_VERSION%"=="12.8" (set "SAGE3_WHL=20251229/sageattn3-1.0.0+cu128torch271-cp312-cp312-win_amd64.whl")
if "%TORCH_VERSION%"=="2.8" if "%CUDA_VERSION%"=="12.8" (set "SAGE3_WHL=20251229/sageattn3-1.0.0+cu128torch280-cp312-cp312-win_amd64.whl")
if "%TORCH_VERSION%"=="2.9" if "%CUDA_VERSION%"=="13.0" (set "SAGE3_WHL=20251229/sageattn3-1.0.0+cu130torch291-cp312-cp312-win_amd64.whl")
%PIP_CMD% uninstall sageattn3 -y >nul 2>&1
if defined SAGE3_WHL %PIP_CMD% install https://github.com/mengqin/SageAttention/releases/download/%SAGE3_WHL%

echo @echo off^&^&cd /d %%~dp0>".\Start_ComfyUI_SageAttention.bat"
echo .\^.venv\Scripts\python.exe -I -W ignore::FutureWarning main.py --use-sage-attention>>".\Start_ComfyUI_SageAttention.bat"
echo pause>>".\Start_ComfyUI_SageAttention.bat"
echo %yellow%Created Start_ComfyUI_SageAttention.bat launcher%reset%
goto :EOF

:INSTALL_TRELLIS
echo.
echo %green%::::::::::::::: Installing Trellis2%reset%
set "model_folder=.\models\facebook\dinov3-vitl16-pretrain-lvd1689m"
if not exist "%model_folder%" md "%model_folder%"

powershell -NoProfile -ExecutionPolicy Bypass -Command "[System.Net.ServicePointManager]::CheckCertificateRevocationList = $false"

echo %green%Downloading DINOv3 model...%reset%
if not exist "%model_folder%\model.safetensors" powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source 'https://huggingface.co/PIA-SPACE-LAB/dinov3-vitl-pretrain-lvd1689m/resolve/main/model.safetensors' -Destination '%model_folder%\model.safetensors'"
if not exist "%model_folder%\config.json" powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source 'https://huggingface.co/PIA-SPACE-LAB/dinov3-vitl-pretrain-lvd1689m/resolve/main/config.json' -Destination '%model_folder%\config.json'"
if not exist "%model_folder%\preprocessor_config.json" powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-BitsTransfer -Source 'https://huggingface.co/PIA-SPACE-LAB/dinov3-vitl-pretrain-lvd1689m/resolve/main/preprocessor_config.json' -Destination '%model_folder%\preprocessor_config.json'"

if exist ".\custom_nodes\ComfyUI-Trellis2" rmdir /s /q ".\custom_nodes\ComfyUI-Trellis2"
git clone https://github.com/visualbruno/ComfyUI-Trellis2 .\custom_nodes\ComfyUI-Trellis2
%PIP_CMD% install -r .\custom_nodes\ComfyUI-Trellis2\requirements.txt --no-deps

set "WHLS_DIR=.\custom_nodes\ComfyUI-Trellis2\wheels\Windows"
if exist "%WHLS_DIR%\Torch280" (
    %PIP_CMD% install "%WHLS_DIR%\Torch280\cumesh-1.0-cp312-cp312-win_amd64.whl"
    %PIP_CMD% install "%WHLS_DIR%\Torch280\nvdiffrast-0.4.0-cp312-cp312-win_amd64.whl"
    %PIP_CMD% install "%WHLS_DIR%\Torch280\nvdiffrec_render-0.0.0-cp312-cp312-win_amd64.whl"
    %PIP_CMD% install "%WHLS_DIR%\Torch280\flex_gemm-0.0.1-cp312-cp312-win_amd64.whl"
    %PIP_CMD% install "%WHLS_DIR%\Torch280\o_voxel-0.0.1-cp312-cp312-win_amd64.whl"
) else (
    echo %yellow%Warning: Trellis Wheels directory not found. Please ensure custom_nodes downloaded correctly.%reset%
)

if exist ".\.venv\Lib\site-packages\cumesh" (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri https://raw.githubusercontent.com/visualbruno/CuMesh/main/cumesh/remeshing.py -OutFile '.\.venv\Lib\site-packages\cumesh\remeshing.py'"
) else (
    echo %yellow%Warning: Could not patch cumesh\remeshing.py because the directory does not exist.%reset%
)

%PYTHON_PATH% -c "import numpy, sys; sys.exit(0 if numpy.__version__ == '1.26.4' else 1)" 2>nul || %PIP_CMD% install numpy==1.26.4
%PIP_CMD% install --upgrade pooch
goto :EOF

:GET_VERSIONS
for /f "tokens=2" %%i in ('%PYTHON_PATH% --version 2^>^&1') do (for /f "tokens=1,2 delims=." %%a in ("%%i") do set "PYTHON_VERSION=%%a.%%b")
set "TORCH_VERSION=Not found"
set "CUDA_VERSION=Not available"
for /f "tokens=1,2 delims=|" %%a in ('%PYTHON_PATH% -c "import torch; v=torch.__version__.split(chr(43))[0]; cv=torch.version.cuda or chr(78); print(v.rsplit(chr(46),1)[0],cv,sep=chr(124))" 2^>nul') do (
set "TORCH_VERSION=%%a"
set "CUDA_VERSION=%%b"
)
goto :EOF

:SET_COLORS
set warning=[33m
set gray=[90m
set red=[91m
set green=[92m
set yellow=[93m
set blue=[94m
set magenta=[95m
set cyan=[96m
set white=[97m
set reset=[0m
goto :EOF
