@ECHO OFF
SetLocal EnableDelayedExpansion

call common.bat

REM set javaMemorySizeXms=-Xms100m
set javaMemorySizeXms=

REM set javaMemorySizeXmx=-Xmx4096m
set javaMemorySizeXmx=

REM set javaProxySettings=-Dhttps.proxyHost=webcache.example.com -Dhttps.proxyPort=8800
set javaProxySettings=-Djava.net.useSystemProxies=true

REM More information on Java Proxy configuration can be found at
REM http://docs.oracle.com/javase/7/docs/technotes/guides/net/proxies.html 


java %javaProxySettings% %javaMemorySizeXms% %javaMemorySizeXmx% -cp !libs! -Djava.library.path=./lib com.dcaiti.vsimrti.start.XMLConfigRunner %*

EndLocal

exit /b %errorlevel%
