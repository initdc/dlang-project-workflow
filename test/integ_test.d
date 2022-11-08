module integ_test;

import std.stdio : writeln;
import lib : hello, world;

void main(){}

unittest
{
    assert("Hello, World!" == hello() ~ world());
}