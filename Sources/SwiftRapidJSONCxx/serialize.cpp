#define RAPIDJSON_NAMESPACE SRJ_rapidjson
#include <stdio.h>
#include <string>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>
#include <rapidjson/prettywriter.h>

struct SrjEncoder {
    SrjEncoder() : json_writer(stringBuffer) {
        json_writer.SetIndent(' ', 2);
    }
    
    void doit() {
        json_writer.StartObject();
        json_writer.Key("abc");
        json_writer.Int(123);
        
        json_writer.Key("plugh");
        json_writer.StartArray();
        json_writer.String("hi");
        json_writer.Int(7);
        json_writer.EndArray();
        json_writer.EndObject();
    }
    
    char const* output() {
        if (outputCache.empty()) {
            outputCache = stringBuffer.GetString();
        }
        return outputCache.c_str();
    }

    std::string outputCache;
    SRJ_rapidjson::StringBuffer stringBuffer;
    SRJ_rapidjson::PrettyWriter<SRJ_rapidjson::StringBuffer> json_writer;
};

inline static SrjEncoder* encoder(void* ptr) {
    return reinterpret_cast<SrjEncoder*>(ptr);
}

inline static SRJ_rapidjson::PrettyWriter<SRJ_rapidjson::StringBuffer>&
writer(void* ptr) {
    return encoder(ptr)->json_writer;
}

extern "C" void* SrjCreateEncoder() {
    return new SrjEncoder();
}

extern "C" void SrjDestroyEncoder(void* ptr) {
    delete encoder(ptr);
}

extern "C" char const* SrjGetOutput(void* ptr) {
    return encoder(ptr)->output();
}

extern "C" void SrjStartArray(void* ptr) {
    writer(ptr).StartArray();
}

extern "C" void SrjEndArray(void* ptr) {
    writer(ptr).EndArray();
}

extern "C" void SrjStartObject(void* ptr) {
    writer(ptr).StartObject();
}

extern "C" void SrjEndObject(void* ptr) {
    writer(ptr).EndObject();
}

extern "C" void SrjKey(void* ptr, char const* key) {
    writer(ptr).Key(key);
}

extern "C" void SrjInt(void* ptr, int value) {
    writer(ptr).Int(value);
}

extern "C" void SrjBool(void* ptr, bool value) {
    writer(ptr).Bool(value);
}

extern "C" void SrjDouble(void* ptr, double value) {
    writer(ptr).Double(value);
}

extern "C" void SrjString(void* ptr, char const* value) {
    writer(ptr).String(value);
}

extern "C" void SrjNull(void* ptr) {
    writer(ptr).Null();
}
