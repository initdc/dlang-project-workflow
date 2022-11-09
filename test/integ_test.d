module integ_test;

import lib : hello, world;

void main(){}

unittest
{
    assert("Hello, World!" == hello() ~ world());
}