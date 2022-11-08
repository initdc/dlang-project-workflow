module lib.world;

import lib.hello : hello;

string world()
{
    return "World!";
}

string hello_world()
{
    return hello() ~ world();
}

unittest
{
    assert("Hello, " == hello());
    assert("Hello, World!" == hello_world());
}