@ECHO OFF

:: make sure to clean up old license information
IF EXIST systemInfo.txt ( del systemInfo.txt )
IF EXIST vsimrti.dat ( del vsimrti.dat )
IF EXIST vsimrti-license.lcs ( del vsimrti-license.lcs )

:: now generate new ones
CALL vsimrti.bat -u initial -c .\scenarios\Tiergarten\vsimrti\vsimrti_config.xml >nul 2>&1

:: print notice to user
ECHO.
ECHO Created license request prerequisites
ECHO Please send the systemInfo.txt to vsimrti@fokus.fraunhofer.de for activation.
ECHO.