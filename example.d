import hyperloglog;
import std.stdio;

void main()
{
	string[] words = ["data", "value", "foo", "bar"];
	auto hyper = HyperLogLog(6,words);
	writeln(hyper.compute());
}