nim c -d:release --opt:speed --mm:orc -d:strip --passL:-static --threads:off --out:dist/wisp examples/example1.nim
./dist/wisp.exe