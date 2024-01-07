@echo off

color a

set "userFolder=%USERPROFILE%"

echo Setting up Visual Studio Code settings...

REM Check if the file exists
if exist "%userFolder%\AppData\Roaming\Code\User\settings.json" (
    echo File exists. Deleting the file...
    del "%userFolder%\AppData\Roaming\Code\User\settings.json"
)
echo. > "%userFolder%\AppData\Roaming\Code\User\settings.json"

REM write the file contents to the file
echo ^{^
    "security.workspace.trust.untrustedFiles": "open",^
    "files.autoSave": "afterDelay",^
    "security.workspace.trust.untrustedFiles": "open",^
    "git.ignoreMissingGitWarning": true,^
    "editor.mouseWheelZoom": true,^
    "terminal.integrated.fontSize": 20,^
    "code-runner.runInTerminal": true,^
    "editor.wordWrap": "on",^
    "code-runner.saveFileBeforeRun": true,^}>> "%userFolder%\AppData\Roaming\Code\User\settings.json"

REM Check if the file exists
if exist "%userFolder%\AppData\Roaming\Code\User\keybindings.json" (
    echo File exists. Deleting the file...
    del "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
)
echo. > "%userFolder%\AppData\Roaming\Code\User\keybindings.json"

REM write the file contents to the file
echo ^[ >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+down", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.action.copyLinesDownAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "shift+alt+down", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.action.copyLinesDownAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+up", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.action.copyLinesUpAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "shift+alt+up", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.action.copyLinesUpAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+shift+numpad_subtract", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.foldAll", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && foldingEnabled" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+k ctrl+0", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.foldAll", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && foldingEnabled" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "alt+a", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "code-runner.run" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+alt+n", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-code-runner.run" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "alt+f", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.action.formatDocument", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly && !inCompositeEditor" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "shift+alt+f", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.action.formatDocument", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly && !inCompositeEditor" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    } >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo ] >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"

echo Visual Studio Code settings and keymap settings setup completed.

echo Installing Visual Studio Code extensions...

code --list-extensions | findstr /C:"esbenp.prettier-vscode" > nul
if errorlevel 1 (
    code --install-extension esbenp.prettier-vscode
) else (
    echo Prettier extension is already installed.
)

code --list-extensions | findstr /C:"formulahendry.code-runner" > nul
if errorlevel 1 (
    code --install-extension formulahendry.code-runner
) else (
    echo Code Runner extension is already installed.
)

code --list-extensions | findstr /C:"ms-python.python" > nul
if errorlevel 1 (
    code --install-extension ms-python.python
) else (
    echo Python extension is already installed.
)

code --list-extensions | findstr /C:"GitHub.copilot" > nul
if errorlevel 1 (
    code --install-extension GitHub.copilot
) else (
    echo GitHub Copilot extension is already installed.
)

echo Visual Studio Code extensions installation completed.

echo Installing Python requirements...

pip install -r requirements.txt

echo Python requirements installation completed.

echo Thank you for using the setup script. Have a nice day! Click to open VS Code.

echo Opening Visual Studio Code...

code "F:\Photoz"

echo Visual Studio Code opened.


echo ^[ >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+down", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.action.copyLinesDownAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "shift+alt+down", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.action.copyLinesDownAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+up", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.action.copyLinesUpAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "shift+alt+up", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.action.copyLinesUpAction", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && !editorReadonly" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+shift+numpad_subtract", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.foldAll", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && foldingEnabled" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+k ctrl+0", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.foldAll", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorTextFocus && foldingEnabled" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "alt+a", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "code-runner.run" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "ctrl+alt+n", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-code-runner.run" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "alt+f", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "editor.action.formatDocument", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly && !inCompositeEditor" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    }, >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    { >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "key": "shift+alt+f", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "command": "-editor.action.formatDocument", >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo        "when": "editorHasDocumentFormattingProvider && editorTextFocus && !editorReadonly && !inCompositeEditor" >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo    } >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"
echo ] >> "%userFolder%\AppData\Roaming\Code\User\keybindings.json"

echo Visual Studio Code settings and keymap settings setup completed.

echo Installing Visual Studio Code extensions...

code --list-extensions | findstr /C:"esbenp.prettier-vscode" > nul
if errorlevel 1 (
    code --install-extension esbenp.prettier-vscode
) else (
    echo Prettier extension is already installed.
)

code --list-extensions | findstr /C:"formulahendry.code-runner" > nul
if errorlevel 1 (
    code --install-extension formulahendry.code-runner
) else (
    echo Code Runner extension is already installed.
)

code --list-extensions | findstr /C:"ms-python.python" > nul
if errorlevel 1 (
    code --install-extension ms-python.python
) else (
    echo Python extension is already installed.
)

code --list-extensions | findstr /C:"GitHub.copilot" > nul
if errorlevel 1 (
    code --install-extension GitHub.copilot
) else (
    echo GitHub Copilot extension is already installed.
)

echo Visual Studio Code extensions installation completed.

echo Installing Python requirements...

pip install -r requirements.txt

echo Python requirements installation completed.

echo Thank you for using the setup script. Have a nice day! Click to open VS Code.

echo Opening Visual Studio Code...

code "F:\Photoz"

echo Visual Studio Code opened.