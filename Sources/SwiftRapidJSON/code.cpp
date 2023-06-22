#include <string>
#include <rapidjson/stringbuffer.h>
#include <rapidjson/writer.h>
#include <rapidjson/prettywriter.h>

static std::string x1 = "hello, there: version2";
static std::string lastResult;

extern "C"
char const* fixed_string() {
    rapidjson::StringBuffer s;
    rapidjson::PrettyWriter<decltype(s)> json_writer(s);
    json_writer.SetIndent(' ', 4);

    json_writer.StartObject();
    json_writer.Key("abc");
    json_writer.Int(123);
    
    json_writer.Key("plugh");
    json_writer.StartArray();
    json_writer.String("hi");
    json_writer.Int(7);
    json_writer.EndArray();
    json_writer.EndObject();

    lastResult = s.GetString();
    return lastResult.c_str();
}

    


    
    
    

    
    




