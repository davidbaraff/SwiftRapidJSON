#if false

#define RAPIDJSON_NAMESPACE OTIO_rapidjson
#include <string>
#include <functional>
#include <rapidjson/filereadstream.h>
#include <rapidjson/cursorstreamwrapper.h>
#include <rapidjson/reader.h>
#include <rapidjson/error/en.h>

extern "C" bool srj_store_bool(void*, bool);
extern "C" bool srj_store_int(void*, int);
extern "C" bool srj_store_int64(void*, int64_t);
extern "C" bool srj_store_double(void*, double);
extern "C" bool srj_store_string(void*, char const*);
extern "C" bool srj_store_null(void*);
extern "C" bool srj_handle_key(void*, char const*);
extern "C" bool srj_start_object(void*);
extern "C" bool srj_end_object(void*);
extern "C" bool srj_start_array(void*);
extern "C" bool srj_end_array(void*);
extern "C" bool srj_parse_error(void*, char const*);

template<typename ... Args>
std::string string_printf(char const* format, Args ... args )
{
    char buffer[4096];
    size_t size = snprintf(buffer, sizeof(buffer), format, args ... ) + 1;
    if (size < sizeof(buffer)) {
        return std::string(buffer);
    }
    
    std::unique_ptr<char[]> buf(new char[size]);
    std::snprintf(buf.get(), size, format, args ...);
    return std::string(buf.get());
}

class JSONDecoder : public OTIO_rapidjson::BaseReaderHandler<OTIO_rapidjson::UTF8<>, JSONDecoder> {
public:
    JSONDecoder(void* context)
        : _context {context} {
    }
    
    bool Null() {  return srj_store_null(_context); }
    bool Bool(bool b) { return srj_store_bool(_context, b); }
    bool Int(int i) {  return srj_store_int(_context, i); }
    bool Uint(unsigned u) {  return srj_store_int(_context, int(u)); }
    bool Int64(int64_t i) { return srj_store_int64(_context, i); }
    bool Uint64(uint64_t u) { return srj_store_int64(_context, int64_t(u)); }
    bool Double(double d) { return srj_store_double(_context, d); }
    bool String(const char* str, OTIO_rapidjson::SizeType length, bool /* copy */) {
        return srj_store_string(_context, str);
    }

    bool Key(const char* str, OTIO_rapidjson::SizeType length, bool /* copy */) {
        return srj_handle_key(_context, str);
    }

    bool StartArray() {
        return srj_start_array(_context);
    }

    bool StartObject() {
        return srj_start_object(_context);
    }

    bool EndArray(OTIO_rapidjson::SizeType) {
        return srj_end_array(_context);
    }

    bool EndObject(OTIO_rapidjson::SizeType) {
        return srj_end_object(_context);
    }

    void* _context;
};

extern "C"
bool deserialize_json_from_string(void* context, char const* input) {
    OTIO_rapidjson::Reader reader;
    OTIO_rapidjson::StringStream ss(input);
    OTIO_rapidjson::CursorStreamWrapper<decltype(ss)> csw(ss);
    JSONDecoder handler(context);

    bool status = reader.Parse(csw, handler);
    if (!status) {
        auto msg = GetParseError_En(reader.GetParseErrorCode());
        std::string descr = string_printf("JSON parse error on input string: %s "
                                          "(line %d, column %d)",
                                          msg, csw.GetLine(), csw.GetColumn());
        srj_parse_error(context, descr.c_str());
        return false;
    }

    return true;
}

#endif

