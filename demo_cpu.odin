package demo
import "core:os"
import "core:log"
import "core:strings"
import "./voicevox_core"

main :: proc() {
    context.logger = log.create_console_logger()
    using voicevox_core
    text : cstring
    if len(os.args) != 2 {
        log.warn("使い方: demo <文章>")
        text = cstring("初めまして!")
    } else {
        text = strings.clone_to_cstring(os.args[1])
    }

    log.info("coreの初期化中...")
    initOpts := make_default_initialize_options()
    initOpts.acceleration_mode = .CPU // force using CPU because CUDA have some additional binary requirements, see [demo_cuda_windows.odin](./demo_cuda_windows.odin)
    initOpts.open_jtalk_dict_dir = "open_jtalk_dic_utf_8-1.11"
    if ret :=  initialize(initOpts); ret != .OK {
        log.errorf("voicevox_initialize failed due to %v", ret)
        return
    }
    speaker_id := u32(47) // ナースロボ＿タイプＴ "ノーマル"
    if ret := load_model(speaker_id); ret != .OK {
        log.errorf("voicevox_load_model failed due to %v", ret)
        return
    }

    output_wav_size : uint
    output_wav      : [^]byte
    log.info("音声生成中...")
    if ret := tts(text, speaker_id, make_default_tts_options(), &output_wav_size, &output_wav); ret != .OK {
        log.errorf("voicevox_tts failed due to %v", ret)
        return
    }
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
