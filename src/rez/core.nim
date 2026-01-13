type
    Rez                       * [T, E = string] = object
        case ok               * : bool
        of true  : val        * : T
        of false : err        * : E

runnableExamples:
    discard """
    The first Type parameter is the value type when `ok` is true,
    and the second Type parameter is the error type when `ok` is false.
    """
    Rez[int, string](ok: true, val: 10)
    Rez[int, string](ok: false, err: "An error occurred")

    discard """
    The 2nd Type is usually `string` by default but can be customized.
    """
    Rez[int](ok: true, val: 20)
    Rez[int, IOError](ok: false, err: IOError("File not found"))
    Rez[int, MyErrorType](ok: false, err: MyErrorType())

proc ok*[T](v: T): Rez[T, string] {.inline.} =
    return Rez[T, string](ok: true, val: v)

    runnableExamples:
        let result = ok(42)
        assert result.ok
        assert result.val == 42

proc err*[T](e: string): Rez[T, string] {.inline.} =
    return Rez[T, string](ok: false, err: e)
    
    runnableExamples:
        let result = err[int]("Something went wrong")
        assert not result.ok
        assert result.err == "Something went wrong"

proc err*[T, E](e: E): Rez[T, E] {.inline.} =
    return Rez[T, E](ok: false, err: e)

    runnableExamples:
        let result = err[int, IOError](IOError("File not found"))
        assert not result.ok
        assert result.err.msg == "File not found"

proc getOr*[T, E](r: Rez[T, E], default: T): T {.inline.} =
    if r.ok: r.val else: default

template isOk*(r: untyped, body: untyped) =
    if (r).ok: body

template isErr*(r: untyped, body: untyped) =
    if not (r).ok: body

proc getOrElse*[T, E](r: Rez[T, E], f: proc(e: E): T {.closure.}): T =
    if r.ok: r.val else: f(r.err)





