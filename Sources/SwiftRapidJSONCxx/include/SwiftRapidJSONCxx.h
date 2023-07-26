#include <stdbool.h>

/*
bool deserialize_json_from_string(void* context, char const* input);
*/

void* SrjCreateEncoder();
void SrjDestroyEncoder(void* ptr);
char const* SrjGetOutput(void* ptr);
unsigned char const* SrjGetUnsignedOutput(void* ptr, int*);
void SrjStartArray(void* ptr);

void SrjEndArray(void* ptr);
void SrjStartObject(void* ptr);
void SrjEndObject(void* ptr);
void SrjKey(void* ptr, char const* key);
void SrjInt(void* ptr, int value);
void SrjBool(void* ptr, bool value);
void SrjDouble(void* ptr, double value);
void SrjString(void* ptr, char const* value);
void SrjNull(void* ptr);
