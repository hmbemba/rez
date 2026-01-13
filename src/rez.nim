import rez/core ; export core

discard """

# Uncomment as needed:
import rez/macros      ; export macros
import rez/combinators ; export combinators
import rez/parsers     ; export parsers
import rez/collections ; export collections
import rez/json        ; export json
when not defined(js):
    import rez/io; export io
when defined(js):
    import rez/js/[fetch, parsers, helpers]
    export fetch, parsers, helpers


rez/
├── rez.nim              # Main entry point, just exports submodules
├── rez/
│   ├── core.nim         # Rez type, ok, err, getOr, isOk, isErr, getOrElse
│   ├── macros.nim       # ?, catch
│   ├── combinators.nim  # map, mapErr, andThen, orElse, tap*, toOption, get, expect
│   ├── parsers.nim      # accessInt, accessFloat, accessBool
│   ├── collections.nim  # at, @, lastSafe, errIfEmpty guards
│   ├── json.nim         # accessKey, asObj (jsony-based)
│   ├── io.nim           # safeReadFile, safeDecodeBase64
│   └── js/
│       ├── fetch.nim    # Response.asObj, Future[Response].asObj
│       ├── parsers.nim  # JS-specific accessFloat
│       └── helpers.nim  # cstring err overload, exit code templates

"""
