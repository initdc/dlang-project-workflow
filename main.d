module d_demo;

import std.stdio : writeln;
import lib : hello_world;

void main()
{
    writeln(hello_world());
}

unittest
{
    assert("Hello, World!" == hello_world());
}