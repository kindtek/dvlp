@echo oFF
@SETLOCAL EnableDelayedExpansion
@REM this is useful for when docker refuses to start due to a bad wsl distro set as default or ...
@REM ..if docker hangs when it tries to start
@REM also try deleting the .docker folder in user directory (C:\Users\xxxx)
SET "command_arg=%~1"
IF "!command_arg!" NEQ "" (
    goto !command_arg!
)
SET prompt=prompt

:prompt
ECHO:
ECHO  running this in linux fixes most Docker connection problems: 
ECHO  'unset DOCKER_HOST'
ECHO:
ECHO:
ECHO  [s]soft docker restart (admin req)
ECHO  [u]nregister docker desktop containers
ECHO  [h]ard docker service start (admin req)
ECHO  [r]eset wsl default distro
ECHO   [reboot] windows (^^!^^!)
ECHO   [q]uit

SET /p "prompt=$ "
goto !prompt!

:s
net stop docker
net stop com.docker.service
taskkill /IM "dockerd.exe" /F
taskkill /IM "Docker Desktop.exe" /F
net start docker
net start com.docker.service
"C:\Program Files\Docker\Docker\resources\dockerd.exe"
"C:\Program Files\Docker\Docker\Docker Desktop.exe"
IF "!command_arg!"=="" (
    goto prompt
) ELSE (
    goto quit
)

:u
@REM @REM force restart for docker containers
wsl.exe --unregister docker-desktop
wsl.exe --unregister docker-desktop-data
@REM docker update --restart=always docker-desktop
@REM docker update --restart=always docker-desktop-data
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchWindowsEngine
& $Env:ProgramFiles\Docker\Docker\DockerCli.exe -SwitchLinuxEngine
IF "!command_arg!" NEQ "" (
    goto quit
)

@REM  dockerd --add-runtime runc=runc --add-runtime custom=/usr/local/bin/my-runc-replacement

:h
"C:\Windows\System32\net.exe" start "com.docker.service"
IF "!command_arg!"=="" (
    goto prompt
) ELSE (
    goto quit
)


@REM reset default wsl distro
:r
wsl.exe -s kalilinux-kali-rolling-latest
IF "!command_arg!"=="" (
    goto prompt
) ELSE (
    goto quit
)


:reboot
@REM restart windows
@REM shutdown -r -t 0
IF "!command_arg!" NEQ "" (
    goto quit
)

:q
:quit
:exit
:end
:x