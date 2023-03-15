package voicevox_core
import "core:encoding/json"
import "core:log"
import "core:runtime"
import "core:io"
import "core:strings"
//! direct mapping to https://github.com/VOICEVOX/voicevox_core/blob/main/crates/voicevox_core/src/engine/model.rs

MoraModel :: struct {
    text: string,
    consonant: string,
    consonant_length: f32,
    vowel: string,
    vowel_length: f32,
    pitch: f32,
}

AccentPhraseModel :: struct {
    moras: []MoraModel,
    accent: uint,
    pause_mora: ^MoraModel,
    is_interrogative: bool,
}

AudioQueryModel :: struct {
    accent_phrases : []AccentPhraseModel,
    speed_scale: f32,
    pitch_scale: f32,
    intonation_scale: f32,
    volume_scale: f32,
    pre_phoneme_length: f32,
    post_phoneme_length: f32,
    output_sampling_rate: u32,
    output_stereo: bool,
    kana: string,
}

to_audio_query_json :: proc(audio_query_model: AudioQueryModel, allocator:=context.allocator) -> (ret: cstring) {
    sb := strings.builder_make_len_cap(0, 1024, allocator)
    to_audio_query_json_writer(strings.to_writer(&sb), audio_query_model)
    str := strings.to_string(sb)
    //log.infof("%v",(byte)(str[0]))
    return strings.unsafe_string_to_cstring(str)
}

to_audio_query_json_writer :: proc(w: io.Writer, audio_query_model: AudioQueryModel) -> (err: io.Error) {
    io.write_string(w, "{\"accent_phrases\":[") or_return
    for ap, ap_idx in audio_query_model.accent_phrases {
        io.write_string(w, "{\"moras\":[") or_return
        for mora_idx in 0..<len(ap.moras) {
            _write_mora(w, &ap.moras[mora_idx]) or_return
            if (mora_idx < len(ap.moras)-1) {
                io.write_byte(w, ',') or_return
            }
        }
        io.write_string(w, "],\"accent\":") or_return
        io.write_uint(w, ap.accent) or_return
        io.write_string(w, ",\"pause_mora\":") or_return
        _write_mora(w, ap.pause_mora) or_return
        io.write_string(w, ",\"is_interrogative\":") or_return
        io.write_string(w, ap.is_interrogative ? "true" : "false") or_return
        io.write_byte(w, '}') or_return
        if (ap_idx < len(audio_query_model.accent_phrases)-1) {
            io.write_byte(w, ',') or_return
        }
    }
    io.write_string(w, "],\"speed_scale\":") or_return
    io.write_f32(w, audio_query_model.speed_scale) or_return
    io.write_string(w, ",\"pitch_scale\":") or_return
    io.write_f32(w, audio_query_model.pitch_scale) or_return
    io.write_string(w, ",\"intonation_scale\":") or_return
    io.write_f32(w, audio_query_model.intonation_scale) or_return
    io.write_string(w, ",\"volume_scale\":") or_return
    io.write_f32(w, audio_query_model.volume_scale) or_return
    io.write_string(w, ",\"pre_phoneme_length\":") or_return
    io.write_f32(w, audio_query_model.pre_phoneme_length) or_return
    io.write_string(w, ",\"post_phoneme_length\":") or_return
    io.write_f32(w, audio_query_model.post_phoneme_length) or_return
    io.write_string(w, ",\"output_sampling_rate\":") or_return
    io.write_u64(w, cast(u64)audio_query_model.output_sampling_rate) or_return
    io.write_string(w, ",\"output_stereo\":") or_return
    io.write_string(w, audio_query_model.output_stereo?"true":"false") or_return
    io.write_string(w, ",\"kana\":\"") or_return
    io.write_string(w, audio_query_model.kana) or_return
    io.write_string(w, "\"}\u0000") or_return
    return nil
}
_write_mora :: proc(w: io.Writer, mora: ^MoraModel) -> (err: io.Error) {
    if mora == nil {
        io.write_string(w, "null")
        return
    }
    io.write_string(w, "{\"text\":\"") or_return
    io.write_string(w, mora.text) or_return
    io.write_string(w, "\",\"consonant\":") or_return
    if len(mora.consonant) > 0 {
        io.write_byte(w, '\"') or_return
        io.write_string(w, mora.consonant) or_return
        io.write_byte(w, '\"') or_return
    } else {
        io.write_string(w, "null") or_return
    }
    io.write_string(w, ",\"consonant_length\":")
    if len(mora.consonant) > 0 {
        io.write_f32(w, mora.consonant_length) or_return
    } else {
        io.write_string(w, "null") or_return
    }
    io.write_string(w, ",\"vowel\":\"")
    io.write_string(w, mora.vowel) or_return
    io.write_string(w, "\",\"vowel_length\":")
    io.write_f32(w, mora.vowel_length) or_return
    io.write_string(w, ",\"pitch\":")
    io.write_f32(w, mora.pitch) or_return
    io.write_byte(w, '}') or_return
    return nil
}

// TODO: speed: directly deal with json marshalling?
from_audio_query_json :: proc(audio_query_json: cstring, allocator:= context.allocator, json_alloc := context.allocator) -> (model: AudioQueryModel, ok: bool) {
    jaqv, error := json.parse_string(string(audio_query_json), json.DEFAULT_SPECIFICATION, false, json_alloc)
    if error != nil {
        log.errorf("Parse audio_query_json failed due to %v", error)
        return
    }
    defer {
        context.allocator = json_alloc
        json.destroy_value(jaqv)
    }
    jaq := jaqv.(json.Object)
    model.speed_scale = cast(f32)jaq["speed_scale"].(json.Float)
    model.pitch_scale = cast(f32)jaq["pitch_scale"].(json.Float)
    model.intonation_scale = cast(f32)jaq["intonation_scale"].(json.Float)
    model.volume_scale = cast(f32)jaq["volume_scale"].(json.Float)
    model.pre_phoneme_length = cast(f32)jaq["pre_phoneme_length"].(json.Float)
    model.post_phoneme_length = cast(f32)jaq["post_phoneme_length"].(json.Float)
    model.output_sampling_rate = cast(u32)jaq["output_sampling_rate"].(json.Float)
    model.output_stereo = jaq["output_stereo"].(json.Boolean)
    model.kana = strings.clone(jaq["kana"].(json.String), allocator)
    japs := jaq["accent_phrases"].(json.Array)
    model.accent_phrases = make([]AccentPhraseModel, len(japs), allocator)
    for pi in 0..<len(japs) {
        jap := japs[pi].(json.Object)
        ap := &model.accent_phrases[pi]
        ap.accent = cast(uint)jap["accent"].(json.Float)
        #partial switch v in jap["pause_mora"] {
        case json.Null: ap.pause_mora = nil
        case json.Object: 
            ap.pause_mora = new(MoraModel, allocator)
            _parse_mora_model(ap.pause_mora, v, allocator)
        case: assert(false)
        }
        ap.is_interrogative = jap["is_interrogative"].(json.Boolean)
        jmoras := jap["moras"].(json.Array)
        ap.moras = make([]MoraModel, len(jmoras), allocator)
        for mi in 0..<len(jmoras) {
            jmora := jmoras[mi].(json.Object)
            mora := &ap.moras[mi]
            _parse_mora_model(mora, jmora, allocator)
        }
    }
    ok = true
    return
}

_parse_mora_model :: proc(mora: ^MoraModel, jmora: json.Object, allocator: runtime.Allocator) {
    mora.text = strings.clone(jmora["text"].(json.String), allocator)
    #partial switch v in jmora["consonant"] {
    case json.Null: mora.consonant = ""
    case json.String: mora.consonant = strings.clone(v, allocator)
    case: assert(false)
    }
    #partial switch v in jmora["consonant_length"] {
    case json.Null: mora.consonant_length = 0
    case json.Float: mora.consonant_length = f32(v)
    case: assert(false)
    }
    mora.vowel = strings.clone(jmora["vowel"].(json.String), allocator)
    mora.vowel_length = cast(f32)jmora["vowel_length"].(json.Float)
    mora.pitch = cast(f32)jmora["pitch"].(json.Float)
}
