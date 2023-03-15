# voicevox_core_odin
odin bindings for `voicevox_core`, tested on Windows for [0.14.2](https://github.com/VOICEVOX/voicevox_core/releases/tag/0.14.2).

## Requirements

- [voicevox_vore](https://github.com/VOICEVOX/voicevox_core/releases/tag/0.14.2), downloaded under `./voicevox_core/lib`
- [OpenJTalk dictionary V1.11 utf8](https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-1.11/open_jtalk_dic_utf_8-1.11.tar.gz), downloaded under `./voicevox_core/lib/open_jtalk_dic_utf_8-1.11`
- [addtional dependencies](https://github.com/VOICEVOX/voicevox_additional_libraries/releases/tag/0.1.0), if you want to use cuda/directML. This binding is only tested with `cuda-windows-x64` at the moment, downloaded under `./voicevox_core/lib`
- [odin compiler](https://github.com/odin-lang/Odin/releases/tag/dev-2023-03)

## Run Demos

Once the all the necessary requirements are in place, we can test the cpu version with:
```shell
odin run demo_cpu.odin -file -out:./voicevox_core/lib/demo_cpu.exe
```

or the cuda version with
```shell
odin run demo_cuda_windows.odin -file -out:./demo_cuda.exe
```
