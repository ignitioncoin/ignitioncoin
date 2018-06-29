taskkill /F /IM Ignition-qt.exe
cd ~/Desktop/
mkdir ignitionbackup
cd $env:APPDATA\Ignition\
del -r smsgStore
del -r smsgDB
del *.log
del smsg.ini
del blk*
del -r database
del -r txleveldb
del peers.dat
del mncache.dat
xcopy /E ./ ~/Desktop
