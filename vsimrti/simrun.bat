@ECHO OFF
SetLocal EnableDelayedExpansion

:: not needed as simrunner currenty contains all dependencies
::call common.bat

rem logging libs
set Filter= .\bin\lib\logback-*.jar
for %%f in (%Filter%) do (
if not "!libs!" == "" set libs=!libs!;
    set libs=!libs!%%f
)

rem simulation-runner jar
set Filter= .\bin\tools\simulation-runner-*.jar
for %%f in (%Filter%) do (
if not "!libs!" == "" set libs=!libs!;
    set libs=!libs!%%f
)

if exist %Filter% (
    java -cp %libs% -Djava.library.path=./lib com.dcaiti.vsimrti.start.Starter %*
) else (
	echo.
	echo Notice: 
	echo.
	echo The Simulation Runner is only available with a commercial license of VSimRTI. Please contact vsimrti@fokus.fraunhofer.de to get a commercial license.
)

EndLocal
