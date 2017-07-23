# VxFS file system options for oracle database
|File System|Normal mount options| Advanced mount options|
|---|---|---|
|Oracle software and dump/diagnostic directories|delaylog,datainlog,largefiles|delaylog,datainlog,largefiles|
|Redo log directory|delaylog,datainlog,largefiles|delaylog,nodatainlog,convosync=direct,mincache=direct,largefiles|
|Archived log directory|delaylog,datainlog,nolargefiles|delaylog,nodatainlog,convosync=direct,mincache=direct,nolargefiles|
|Control files directory|delaylog,datainlog,nolargefiles|delaylog,datainlog,nolargefiles|
|Data, index, undo, system/sysaux and temporary directories|delaylog,datainlog,largefiles|delaylog,nodatainlog,convosync=direct,mincache=direct,largefiles|
