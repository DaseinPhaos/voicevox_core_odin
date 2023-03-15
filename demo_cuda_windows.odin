package demo
import "core:os"
import "core:log"
import "core:strings"
import "./voicevox_core"
import path "core:path/filepath"
import "core:sys/windows"
foreign import kernel32 "system:Kernel32.lib"

USE_CUDA :: true

main :: proc() {
    context.logger = log.create_console_logger()
    when USE_CUDA {
        // when USE_CUDA, compile with `odin build demo_cuda_windows.odin -file -out:./demo_cuda.exe`
        // make sure to download the following dependencies:
        // 1. [open_jtalk_dic_utf_8-1.11](https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-1.11/open_jtalk_dic_utf_8-1.11.tar.gz), download and extract the files to `./voicevox_core/lib/open_jtalk_dic_utf_8-1.11`
        // 2. the cuda release from voicevox_core. the demo is tested with [0.14.1](https://github.com/VOICEVOX/voicevox_core/releases/tag/0.14.1). Download and extract the files under `./voicevox_core/lib`
        // 3. CUDA-windows-x64.zip from voicevox_additional_libraries. the demo is tested with [0.1.0](https://github.com/VOICEVOX/voicevox_additional_libraries/releases/tag/0.1.0). Download and extract the files under `./voicevox_core/lib/CUDA-windows-x64`
        // 4. `zlibwapi.dll` as required by [cuDNN](https://docs.nvidia.com/deeplearning/cudnn/install-guide/index.html#install-windows). As the link provided by the official [is dead](https://forums.developer.nvidia.com/t/zlib-dll-for-latest-cudnn-in-official-install-guide-is-missing/197630) at the time of testing, I grabbed it from somewhere else and uploaded under `/voicevox_core/lib` for convenience
        SetDefaultDllDirectories(0x0000_1000)
        libPathBuf := [?]string {path.dir(get_executable_path()), "voicevox_core\\lib"}
        dllDirCookie := AddDllDirectory(windows.utf8_to_wstring(path.join(libPathBuf[:]), context.temp_allocator))
        assert(dllDirCookie != nil)
        libPathBuf[1] = "voicevox_core\\lib\\CUDA-windows-x64"
        dllDirCookie = AddDllDirectory(windows.utf8_to_wstring(path.join(libPathBuf[:]), context.temp_allocator))
        assert(dllDirCookie != nil)
        vcd, vcd_load := voicevox_core.load_dynamic_lib("voicevox_core.dll")
        assert(vcd_load)
        defer voicevox_core.unload_dynamic_lib(vcd)
        using vcd
    } else {
        // otherwise, compile with `odin build demo_cuda_windows.odin -file -out:./voicevox_core/lib/demo_cpu.exe`
        // make sure to download the following dependencies:
        // 1. [open_jtalk_dic_utf_8-1.11](https://jaist.dl.sourceforge.net/project/open-jtalk/Dictionary/open_jtalk_dic-1.11/open_jtalk_dic_utf_8-1.11.tar.gz), download and extract the files to `./voicevox_core/lib/open_jtalk_dic_utf_8-1.11`
        // 2. the cpu release from voicevox_core. the demo is tested with [0.14.1](https://github.com/VOICEVOX/voicevox_core/releases/tag/0.14.1). Download and extract the files under `./voicevox_core/lib`
        using voicevox_core
    }

    text : cstring

    if len(os.args) != 2 {
        log.warn("使い方: demo <文章>")
        text = cstring("初めまして!")
    } else {
        text = strings.clone_to_cstring(os.args[1])
    }

    log.infof("voicevox version: %v",    get_version())
    //log.infof("voicevox metas: %v",      get_metas_json())
    log.infof("supported_devices: %v",   get_supported_devices_json())
    log.info("coreの初期化中...")
    initOpts := make_default_initialize_options()
    when USE_CUDA {
        initOpts.acceleration_mode = .GPU
        initOpts.open_jtalk_dict_dir = "./voicevox_core/lib/open_jtalk_dic_utf_8-1.11"
    } else {
        initOpts.acceleration_mode = .CPU
        initOpts.open_jtalk_dict_dir = "open_jtalk_dic_utf_8-1.11"
    }
    //initOpts.load_all_models = true
    if ret :=  initialize(initOpts); ret != .OK {
        log.errorf("voicevox_initialize failed due to %v", ret)
        return
    }

    //speaker_id := u32(14) // 冥鳴ひまり 
    //speaker_id := u32(16) // 九州そら "ノーマル"
    //speaker_id := u32(19) // 九州そら "ささやき"
    //speaker_id := u32(20) // もち子さん
    //speaker_id := u32(29) // No.7 "ノーマル"
    //speaker_id := u32(31) // No.7 "読み聞かせ"
    speaker_id := u32(47) // ナースロボ＿タイプＴ "ノーマル"
    //speaker_id := u32(50) // ナースロボ＿タイプＴ "内緒話"

    if ret := load_model(speaker_id); ret != .OK {
        log.errorf("voicevox_load_model failed due to %v", ret)
        return
    }

    output_wav_size := uint(0)
    output_wav : [^]byte
    log.info("音声生成中...")
    if ret := tts(text, speaker_id, make_default_tts_options(), &output_wav_size, &output_wav); ret != .OK {
        log.errorf("voicevox_tts failed due to %v", ret)
        return
    }
    // output_audio_query_json : cstring
    // if ret := audio_query(text, speaker_id, make_default_audio_query_options(), &output_audio_query_json); ret != .OK {
    //     log.errorf("voicevox_audio_query failed due to %v", ret)
    //     return
    // }
    // log.infof("%v", output_audio_query_json)

    log.info("音声ファイル保存中...")
    out_dir :: "./out.wav"
    fd, err := os.open(out_dir, os.O_WRONLY|os.O_CREATE|os.O_TRUNC)
    assert(err == {})
    defer os.close(fd)
    written : int
    written, err = os.write(fd, output_wav[:output_wav_size])
    assert(written == int(output_wav_size))
    log.infof("all done! Saved to %v", out_dir)
}

// === win32 bindings to load the dlls ==
DLL_DIRECTORY_COOKIE :: distinct rawptr
@(default_calling_convention="std")
foreign kernel32 {
    AddDllDirectory :: proc(NewDirectory: windows.wstring) -> DLL_DIRECTORY_COOKIE ---
    SetDefaultDllDirectories :: proc(DirectoryFlags: windows.DWORD) -> windows.BOOL ---
    RemoveDllDirectory :: proc(Cookie: DLL_DIRECTORY_COOKIE) -> windows.BOOL ---
}
get_executable_path :: proc(allocator := context.temp_allocator) -> string {
    nameBuf : [windows.MAX_PATH]u16
    pBuf := &nameBuf[0]
    nameLen := windows.GetModuleFileNameW(nil, pBuf, len(nameBuf))
    path, err := windows.wstring_to_utf8(pBuf, cast(int)nameLen, allocator)
    assert(err == nil)
    return path
}