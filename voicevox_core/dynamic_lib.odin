package voicevox_core
import "core:dynlib"
import "core:strings"
import "core:runtime"
import "core:log"

DynamicLib :: struct {
    make_default_initialize_options : proc "c"() -> InitializeOptions,
    initialize                      : proc "c"(options: InitializeOptions) -> ResultCode,
    get_version                     : proc "c"() -> cstring,
    load_model                      : proc "c"(speaker_id: u32) -> ResultCode,
    is_gpu_mode                     : proc "c"() -> bool,
    is_model_loaded                 : proc "c"(speaker_id: u32) -> bool,
    finalize                        : proc "c"(),
    get_metas_json                  : proc "c"() -> cstring,
    get_supported_devices_json      : proc "c"() -> cstring,
    predict_duration                : proc "c"(length: uint, 
                                            phoneme_vector: [^]i64, 
                                            speaker_id: u32, 
                                            output_predict_duration_data_length: ^uint, 
                                            output_predict_duration_data: ^[^]f32) -> ResultCode,
    predict_duration_data_free      : proc "c"(predict_duration_data: [^]f32),
    predict_intonation              : proc "c"(length: uint,
                                            vowel_phoneme_vector: [^]i64,
                                            consonant_phoneme_vector: [^]i64,
                                            start_accent_vector: [^]i64,
                                            end_accent_vector: [^]i64,
                                            start_accent_phrase_vector: [^]i64,
                                            end_accent_phrase_vector: [^]i64,
                                            speaker_id: u32,
                                            output_predict_intonation_data_length: ^uint,
                                            output_predict_intonation_data: ^[^]f32) -> ResultCode,
    predict_intonation_data_free    : proc "c"(predict_intonation_data: [^]f32),
    decode                          : proc "c"(length: uint,
                                            phoneme_size: uint,
                                            f0: [^]f32,
                                            phoneme_vector: [^]f32,
                                            speaker_id: u32,
                                            output_decode_data_length: ^uint,
                                            output_decode_data: ^[^]f32) -> ResultCode,
    decode_data_free                : proc "c"(decode_data: [^]f32),
    make_default_audio_query_options: proc "c"() -> AudioQueryOptions,
    audio_query                     : proc "c"(text: cstring, 
                                            speaker_id: u32, 
                                            options: AudioQueryOptions, 
                                            output_audio_query_json: ^cstring) -> ResultCode,
    make_default_synthesis_options  : proc "c"() -> SynthesisOptions,
    synthesis                       : proc "c"(audio_query_json: cstring, 
                                            speaker_id: u32, 
                                            options: SynthesisOptions, 
                                            output_wav_length: ^uint, 
                                            output_wav: ^[^]byte) -> ResultCode,
    make_default_tts_options        : proc "c"() -> TtsOptions,
    tts                             : proc "c"(text: cstring, 
                                            speaker_id: u32, 
                                            options: TtsOptions, 
                                            output_wav_length: ^uint, 
                                            output_wav: ^[^]byte) -> ResultCode,
    audio_query_json_free           : proc "c"(audio_query_json: cstring),
    wav_free                        : proc "c"(wav: [^]byte),
    error_result_to_message         : proc "c"(result_code: ResultCode) -> cstring,
    _lib : dynlib.Library,
}

load_dynamic_lib :: proc(path: string) -> (ret: DynamicLib, ok: bool) {
    ret._lib, ok = dynlib.load_library(path)
    if !ok {
        log.errorf("failed to load dynamic library at %s", path)
        return
    }
    tis, tis_ok := runtime.type_info_base(type_info_of(DynamicLib)).variant.(runtime.Type_Info_Struct)
    assert(tis_ok)
    for i in 0..<len(tis.names) {
        fname := tis.names[i]
        if fname == "_lib" do continue
        nbuf := [?]string{"voicevox_", fname}
        fname = strings.concatenate(nbuf[:], context.temp_allocator)
        fptr, found := dynlib.symbol_address(ret._lib, fname)
        if !found {
            ok = false
            log.errorf("failed to find symbol [%s] from the loaded lib, destroying", fname)
            dynlib.unload_library(ret._lib)
            ret = {}
            return
        }
        foffset := tis.offsets[i]
        pfield := uintptr(&ret) + foffset
        ((^rawptr)(pfield))^ = fptr
    }
    return
}

unload_dynamic_lib :: proc(dyn_lib: DynamicLib) {
    dynlib.unload_library(dyn_lib._lib)
}
