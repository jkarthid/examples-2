# Change logical block size / change lba size

change logical block size:
```
sg_format --format --size 4096 /dev/rdsk/c0t5000CCA02C4015E4d0
```

change lba size:
```
sg_format --resize --count=0x2321 /dev/rdsk/c0t5000CCA02C4015E4d0
```

refresh device information:
```
update_drv -fv sd
```
