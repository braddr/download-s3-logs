module config;

import std.json;
import std.file;

struct Config
{
    string aws_access_key;
    string aws_secret_key;
    string aws_endpoint;
}

bool as_bool(JSONValue jv, string f)
{
    JSONValue* v = f in jv.object;
    if (!v) return false;

    return v.type == JSON_TYPE.TRUE;
}

string as_string(JSONValue jv, string f, string d = "")
{
    JSONValue* v = f in jv.object;
    if (!v) return d;
    if (v.type != JSON_TYPE.STRING) return d;

    return v.str;
}

Config load_config(string filename)
{
    Config c;

    string contents = cast(string)read(filename);

    JSONValue jv = parseJSON(contents);

    c.aws_access_key = jv.as_string("aws_access_key");
    c.aws_secret_key = jv.as_string("aws_secret_key");
    c.aws_endpoint  = jv.as_string("aws_endpoint");

    return c;
}

