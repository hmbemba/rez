import unittest
import os
import ic

discard """
nim c -r -d:ic ./src/rez/core.nim ; rm ./src/rez/core.exe
"""
when isMainModule:
    import ic

    type
        Person   * = object
            name * : string
            age  * : int


    ic Rez[int, string]
    ic Rez[Person, string]

    ic  ok(100)
    icr err[Person]("An error occurred")
    icr err[Person, Person] Person(name: "NA", age: -1)

    isOk err[Person]("An error occurred") :
        ic "This won't be printed"
    
    isErr err[Person]("An error occurred") :
        icr "This will be printed"


