package voicevox_core
foreign import "./lib/voicevox_core.lib"

AccelerationMode :: enum i32 {
    AUTO = 0,
    CPU = 1,
    GPU = 2,
}
ResultCode :: enum i32 {
    OK = 0,
    NOT_LOADED_OPENJTALK_DICT_ERROR = 1,
    LOAD_MODEL_ERROR = 2,
    GET_SUPPORTED_DEVICES_ERROR = 3,
    GPU_SUPPORT_ERROR = 4,
    LOAD_METAS_ERROR = 5,
    UNINITIALIZED_STATUS_ERROR = 6,
    INVALID_SPEAKER_ID_ERROR = 7,
    INVALID_MODEL_INDEX_ERROR = 8,
    INFERENCE_ERROR = 9,
    EXTRACT_FULL_CONTEXT_LABEL_ERROR = 10,
    INVALID_UTF8_INPUT_ERROR = 11,
    PARSE_KANA_ERROR = 12,
    INVALID_AUDIO_QUERY_ERROR = 13,
}
InitializeOptions :: struct {
    acceleration_mode: AccelerationMode,
    cpu_num_threads: u16,
    load_all_models: bool,
    open_jtalk_dict_dir: cstring,
}
AudioQueryOptions :: struct {
    kana: bool,
}
SynthesisOptions :: struct {
    enable_interrogative_upspeak: bool,
}
TtsOptions :: struct {
    kana: bool,
    enable_interrogative_upspeak: bool,
}

@(default_calling_convention="c", link_prefix="voicevox_")
foreign voicevox_core {
    make_default_initialize_options :: proc() -> InitializeOptions ---
    initialize                      :: proc(options: InitializeOptions) -> ResultCode ---
    get_version                     :: proc() -> cstring ---
    load_model                      :: proc(speaker_id: u32) -> ResultCode ---
    is_gpu_mode                     :: proc() -> bool ---
    is_model_loaded                 :: proc(speaker_id: u32) -> bool ---
    finalize                        :: proc() ---
    get_metas_json                  :: proc() -> cstring ---
    get_supported_devices_json      :: proc() -> cstring ---
    predict_duration                :: proc(length: uint, 
                                            phoneme_vector: [^]i64, 
                                            speaker_id: u32, 
                                            output_predict_duration_data_length: ^uint, 
                                            output_predict_duration_data: ^[^]f32) -> ResultCode ---
    predict_duration_data_free      :: proc(predict_duration_data: [^]f32) ---
    predict_intonation              :: proc(length: uint,
                                            vowel_phoneme_vector: [^]i64,
                                            consonant_phoneme_vector: [^]i64,
                                            start_accent_vector: [^]i64,
                                            end_accent_vector: [^]i64,
                                            start_accent_phrase_vector: [^]i64,
                                            end_accent_phrase_vector: [^]i64,
                                            speaker_id: u32,
                                            output_predict_intonation_data_length: ^uint,
                                            output_predict_intonation_data: ^[^]f32) -> ResultCode ---
    predict_intonation_data_free    :: proc(predict_intonation_data: [^]f32) ---
    decode                          :: proc(length: uint,
                                            phoneme_size: uint,
                                            f0: [^]f32,
                                            phoneme_vector: [^]f32,
                                            speaker_id: u32,
                                            output_decode_data_length: ^uint,
                                            output_decode_data: ^[^]f32) -> ResultCode ---
    decode_data_free                :: proc(decode_data: [^]f32) ---
    make_default_audio_query_options:: proc() -> AudioQueryOptions ---
    audio_query                     :: proc(text: cstring, 
                                            speaker_id: u32, 
                                            options: AudioQueryOptions, 
                                            output_audio_query_json: ^cstring) -> ResultCode ---
    make_default_synthesis_options  :: proc() -> SynthesisOptions ---
    synthesis                       :: proc(audio_query_json: cstring, 
                                            speaker_id: u32, 
                                            options: SynthesisOptions, 
                                            output_wav_length: ^uint, 
                                            output_wav: ^[^]byte) -> ResultCode ---
    make_default_tts_options        :: proc() -> TtsOptions ---
    tts                             :: proc(text: cstring, 
                                            speaker_id: u32, 
                                            options: TtsOptions, 
                                            output_wav_length: ^uint, 
                                            output_wav: ^[^]byte) -> ResultCode ---
    audio_query_json_free           :: proc(audio_query_json: cstring) ---
    wav_free                        :: proc(wav: [^]byte) ---
    error_result_to_message         :: proc(result_code: ResultCode) -> cstring ---
}
