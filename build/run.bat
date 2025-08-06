cd ../
rm dist\wisp.exe
nim c --mm:orc --threads:off --out:dist/wisp examples/example1.nim
dist\wisp.exe