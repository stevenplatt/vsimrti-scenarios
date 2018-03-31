set libs=

SetLocal EnableDelayedExpansion

rem core components
set Filter= .\bin\core\*.jar
for %%f in (%Filter%) do (
if not "!libs!" == "" set libs=!libs!;
    set libs=!libs!%%f
)

rem core libs
set Filter= .\bin\lib\*.jar
for %%f in (%Filter%) do (
if not "!libs!" == "" set libs=!libs!;
    set libs=!libs!%%f
)

rem ambassdors
set Filter= .\bin\ambassadors\*.jar
for %%f in (%Filter%) do (
if not "!libs!" == "" set libs=!libs!;
    set libs=!libs!%%f
)

rem ambassador libs
set Filter= .\bin\ambassadors\lib\*.jar
for %%f in (%Filter%) do (
if not "!libs!" == "" set libs=!libs!;
    set libs=!libs!%%f
)

set libs=!libs!;

EndLocal & set libs=%libs%.\etc\

