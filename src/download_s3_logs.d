module download_logs;

import std.algorithm;
import std.array;
import std.conv;
import std.stdio;

import aws;
import config;
import s3;

string output_prefix = "";

struct update_prefix
{
    static opCall() { output_prefix ~= "   "; update_prefix f; return f; }
    ~this() { output_prefix = output_prefix[0 .. $-3]; }
}

void checkDir(string path)
{
    import std.file : mkdirRecurse;

    static bool[string] paths;

    if (path in paths) return;

    mkdirRecurse(path);
    paths[path] = true;
}

bool processObject(S3Bucket bucket, string outputdir, S3Object obj)
{
    import std.conv : toLower;
    import std.digest.digest : toHexString;
    import std.digest.md : md5Of;
    import std.exception : enforce;
    import std.file : write;
    import std.path : dirName;

    auto unused = update_prefix();

    writef("%sprocessing '%s'...", output_prefix, obj.key);

    writef(" pulling from s3..."); stdout.flush;
    ubyte[] data = obj.get;

    writef(" validating md5sum..."); stdout.flush;
    auto md5str = "\"" ~ data.md5Of.toHexString.toLower ~ "\"";
    enforce(md5str == obj.etag, text(md5str, " != ", obj.etag));

    string filename = outputdir ~ obj.key;
    writef(" writing..."); stdout.flush;
    checkDir(dirName(filename));
    write(filename, data);

    writef(" deleting..."); stdout.flush;
    obj.del;

    writeln(" done.");
    return true;
}

bool processPrefix(S3Bucket bucket, string outputdir, string prefix, string sep)
{
    writefln("%sFetching objects from s3 for bucket '%s', prefix '%s', with '%s' as a separator", output_prefix, bucket.name, prefix, sep);
    S3ListResults contents = listBucketContents(bucket, prefix, sep);

    writeln(output_prefix, "Iterating over contents...");
    contents[].map!(a => processObject(bucket, outputdir, a)).array;
    writeln(output_prefix, "... done.");

    writeln;
    writeln(output_prefix, "Processing common prefixes:");
    {
        auto unused = update_prefix();
        contents.commonPrefixes.map!(a => processPrefix(bucket, outputdir, a, sep)).array;
    }
    writeln(output_prefix, "... done.");

    return true;
}

void main(string[] args)
{
    if (args.length < 5 || args.length > 6)
    {
        writeln("usage: downloads-logs <configfile> <outputdir> <bucket> <prefix> [<separator>]");
        writeln("examples:");
        writeln("   downloads-logs logs puremagic-logs \"\"");
        writeln("   downloads-logs logs puremagic-logs \"downloads.dlang.org/\"");
        return;
    }

    Config c = load_config(args[1]);

    string outputdir = args[2];
    if (outputdir[$-1] != '/')
        outputdir ~= '/';

    string bucket = args[3];
    string prefix = args[4];
    string sep = args.length == 6 ? args[5] : "/";

    auto a = new AWS;
    a.accessKey = c.aws_access_key;
    a.secretKey = c.aws_secret_key;
    a.endpoint = c.aws_endpoint;

    auto s3 = new S3(a);
    auto s3bucket = new S3Bucket(s3);
    s3bucket.name = bucket;

    processPrefix(s3bucket, outputdir, prefix, sep);
}
