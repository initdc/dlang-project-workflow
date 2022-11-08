module lib.hello;

string hello()
{
    return "Hello, ";
}

unittest
{
    assert("Hello, " == hello());
}