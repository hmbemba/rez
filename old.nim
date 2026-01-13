# https://claude.ai/chat/351f7b66-e59d-46b4-a36f-7462cf61fc76

# A small "Results" + safe helpers library that works on native + JS,
# and avoids invalid states by using a variant object.

import std/[options, strutils, sequtils, tables, json, macros]
export options, strutils

when not defined(nimscript):
    import jsony
    import std/base64

# ------------------------------------------------------------------------------
# Core Rez type 
# ------------------------------------------------------------------------------






# ------------------------------------------------------------------------------
# Macros for ergonomics: ?r early return, and catch for custom handling
# ------------------------------------------------------------------------------
macro `?`*(resExpr: untyped): untyped =
    let tmp = genSym(nskLet, "tmpRes")
    result = quote do:
        block:
            let `tmp` = `resExpr`
            if not `tmp`.ok:
                return Rez[type(result.val), type(`tmp`.err)](ok: false, err: `tmp`.err)
            `tmp`.val

macro catch*(resExpr: untyped; body: untyped): untyped =
    ## Evaluates a Rez. If Err, runs body with `it` injected as the Rez.
    ## Otherwise returns getped value.
    ## Usage:
    ##     let x = catch(accessInt("x")):
    ##         echo it.err
    ##         return err[int](it.err)
    let tmp = genSym(nskLet, "tmpRes")
    result = quote do:
        block:
            let `tmp` = `resExpr`
            if not `tmp`.ok:
                let it {.inject.} = `tmp`
                `body`
            else:
                `tmp`.val



# ------------------------------------------------------------------------------
# Cross-target exception formatting (centralized)
# ------------------------------------------------------------------------------

proc currentExcMsg*(): string =
    let e = getCurrentException()
    let msg = getCurrentExceptionMsg()
    when defined(js):
        # JS target: repr(e) is problematic / noisy.
        result = msg
    else:
        result = repr(e) & ": " & msg



# ------------------------------------------------------------------------------
# Safe helpers (native + JS)
# ------------------------------------------------------------------------------

when not defined(nimscript):

    # when not defined(js):
    #     proc safeReadFile*(filePath: string): Rez[string] =
    #         try:
    #             ok(readFile(filePath))
    #         except CatchableError:
    #             err[string](currentExcMsg())

    # proc lastSafe*[T](s: seq[T]): Rez[T] =
    #     if s.len == 0: return err[T]("Seq has a len of 0")
    #     ok(s[^1])

    # proc safeDecodeBase64*(s: string): Rez[string] =
    #     ## Removes newlines and base64-decodes.
    #     try:
    #         ok(s.replace("\n", "").decode())
    #     except CatchableError:
    #         err[string](currentExcMsg())

    proc accessInt*(s: string | cstring): Rez[int] =
        try:
            ok(parseInt($s))
        except CatchableError:
            err[string,int](currentExcMsg())

    # proc accessFloat*(s: string): Rez[float] =
    #     try:
    #         ok(parseFloat(s))
    #     except CatchableError:
    #         err[float](currentExcMsg())

    # proc accessBool*(s: string): Rez[bool] =
    #     try:
    #         ok(s.parseBool)
    #     except CatchableError:
    #         err[bool](currentExcMsg())

    # # JsonNode accessors
    # proc accessKey*(j: JsonNode, key: string): Rez[JsonNode] =
    #     if j.kind != JObject: return err[JsonNode]("Not a JSON object")
    #     if not j.hasKey(key): return err[JsonNode]("Key not found: " & key)
    #     if j[key].kind == JNull: return err[JsonNode](key & " is null")
    #     ok(j[key])

    # proc accessKey*(j: JsonNode, key: string, kind: JsonNodeKind): Rez[JsonNode] =
    #     if j.kind != JObject: return err[JsonNode]("Not a JSON object")
    #     if not j.hasKey(key): return err[JsonNode]("Key not found: " & key)
    #     if j[key].kind != kind:
    #         return err[JsonNode](key & " is a " & $j[key].kind & " not a " & $kind)
    #     ok(j[key])

    # # Safe indexing
    # proc at*[T](s: seq[T], idx: int): Rez[T] =
    #     if s.len == 0: return err[T]("Seq has a len of 0")
    #     if idx < 0 or idx >= s.len: return err[T]("Index out of range")
    #     ok(s[idx])

    # # Compatibility operator for seq indexing: mySeq @ 3
    # proc `@`*[T](s: seq[T], idx: int): Rez[T] {.inline.} = s.at(idx)

    # # ONLY for tables keyed by int (avoid misleading "table by index" API)
    # proc `@`*[V](t: Table[int, V], idx: int): Rez[V] =
    #     if t.len == 0: return err[V]("Table has a len of 0")
    #     if not t.hasKey(idx): return err[V]("Key not found: " & $idx)
    #     ok(t[idx])

    # proc asObj*[T](s: string, obj: typedesc[T]): Rez[T] =
    #     try:
    #         ok(s.fromJson(obj))
    #     except CatchableError:
    #         err[T](currentExcMsg())





when defined false:

    proc get*[T, E](r: Rez[T, E]): T =
        ## Panics if r is Err. Prefer `?r`, getOr, or expect.
        if r.ok : r.val
        else    : raise newException(ValueError, $r.err)

    proc expect*[T, E](r: Rez[T, E], msg: string): T =
        if r.ok : r.val
        else    : raise newException(ValueError, msg & ": " & $r.err)


    proc toOption*[T, E](r: Rez[T, E]): Option[T] {.inline.} =
        if r.ok: some(r.val) else: none(T)

    # Functional composition
    proc map*[T, U, E](r: Rez[T, E], f: proc(x: T): U {.closure.}): Rez[U, E] =
        if r.ok: ok[U, E](f(r.val)) else: err[U, E](r.err)

    proc mapErr*[T, E, F](r: Rez[T, E], f: proc(e: E): F {.closure.}): Rez[T, F] =
        if r.ok: ok[T, F](r.val) else: err[T, F](f(r.err))

    proc andThen*[T, U, E](r: Rez[T, E], f: proc(x: T): Rez[U, E] {.closure.}): Rez[U, E] =
        if r.ok: f(r.val) else: err[U, E](r.err)

    proc orElse*[T, E](r: Rez[T, E], f: proc(e: E): Rez[T, E] {.closure.}): Rez[T, E] =
        if r.ok: r else: f(r.err)

    proc tapOk*[T, E](r: Rez[T, E], f: proc(x: T) {.closure.}): Rez[T, E] =
        if r.ok: f(r.val)
        r

    proc tapErr*[T, E](r: Rez[T, E], f: proc(e: E) {.closure.}): Rez[T, E] =
        if not r.ok: f(r.err)
        r



    # ------------------------------------------------------------------------------
    # Tiny conditional helper
    # ------------------------------------------------------------------------------

  



    # ------------------------------------------------------------------------------
    # "Empty" guards (prefer explicit overloads over duck-typed `.len`)
    # ------------------------------------------------------------------------------

    template errIfEmptyStr*[T](s: string, msg: string = "String has a len of 0") =
        if s.len == 0:
            return err[T](msg)

    template errIfAnyEmptyStr*[T](ss: seq[string], msg: string = "One or more strings are empty") =
        if ss.anyIt(it.len == 0):
            return err[T](msg)

    template errIfEmpty*(s: cstring | string, body: untyped) =
        if s.len == 0:
            body

    # ------------------------------------------------------------------------------
    # JS-specific helpers
    # ------------------------------------------------------------------------------

    when defined(js):
        import std/math
        import mynimlib/nimjs
        import icecream

        # Parse float from cstring in JS with NaN/Inf checks (keeps your old behavior)
        proc accessFloat*(s: cstring): Rez[float] =
            var x {.exportc:"safenim_get_float".} = 0.0
            {.emit: "safenim_get_float = parseFloat(`s`);".}
            if x.classify == fcNaN: err[float]("NaN")
            elif x.classify == fcInf: err[float]("Inf")
            else: ok(x)

        # JSON decode from fetch Response
        proc asObj*[T](r: jsfetch.Response, obj: typedesc[T]): Future[Rez[T]] {.async.} =
            try:
                let text: cstring = await r.text()
                ic text
                ok(($text).fromJson(obj))
            except CatchableError:
                err[T](currentExcMsg())

        proc asObj*[T](futureResp: Future[jsfetch.Response], obj: typedesc[T]): Future[Rez[T]] {.async.} =
            try:
                let resp = await futureResp
                let text: cstring = await resp.text()
                ok(($text).fromJson(obj))
            except CatchableError:
                err[T](currentExcMsg())

        proc asObj*[T](s: cstring, obj: typedesc[T]): Rez[T] =
            try:
                ok(s.string.fromJson(obj))
            except CatchableError:
                err[T](currentExcMsg())

        proc err*[T](msg: cstring): Rez[T] {.inline.} =
            err[T]($msg)

    # ------------------------------------------------------------------------------
    # Native-only "exit code err" helpers (kept, but simplified)
    # ------------------------------------------------------------------------------

    when not defined(js):
        template err*(exitCode: int, body: untyped) =
            if exitCode != 0:
                body

        template err*(toop: tuple[output: string, exitCode: int], body: untyped) =
            if toop.exitCode != 0:
                body




discard """
    nim c -d:ic -d:ssl -r main.nim
"""

