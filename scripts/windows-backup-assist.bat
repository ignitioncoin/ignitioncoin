taskkill /F /IM Ignition-qt.exe
mkdir "%USERPROFILE%"\Desktop\ignitionbackup
cd "%USERPROFILE%"\Ignition\
del -r smsgStore
del -r smsgDB
del *.log
del smsg.ini
del blk*
del -r database
del -r txleveldb
del peers.dat
del mncache.dat
xcopy /E .\* "%USERPROFILE%"\Desktop\ignitionbackup
