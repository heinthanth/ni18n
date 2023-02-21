import macros, strutils, sugar, sequtils, tables, sets

# since ni18n depends on strutils.format
export strutils.format

proc concatIdent(a: NimNode, b: varargs[NimNode]): NimNode {.compileTime.} =
    ## Concatenates list of identifiers with "_".
    var newTokens: seq[string]
    expectKind(a, {nnkIdent, nnkSym, nnkEmpty})
    # don't add a if it's empty otherwise, we will get "_something" and Nim compiler will complain about it
    if a.kind != nnkEmpty: newTokens.add(a.strVal())
    # add other identifiers
    for b in b: expectKind(b, nnkIdent); newTokens.add(b.strVal())
    return ident(newTokens.join("_"))

proc identToDotNotation(name: NimNode): string {.inline, compileTime.} =
    ## convert parent_child to parent.child
    expectKind(name, {nnkIdent, nnkSym})
    return name.strVal().replace("_", ".")

proc sameSignatureProc(a, b: NimNode): bool {.inline, compileTime.} =
    ## Checks if two proc definitions have the same signature.
    expectKind(a, nnkProcDef)
    expectKind(b, nnkProcDef)
    result = true

    # see above comment for ProcDef structure
    # to check if two procs have the same signature,
    # we need to check nnkGenericParams, nnkFormalParams and nnkPragma.
    # But generic can't be used in Lambda and not supported in ni18n,
    # so we will check just nnkFormalParams and nnkPragma
    if a[3] != b[3] or a[4] != b[4]: return false

proc sameSignatureProcs(fns: varargs[NimNode]): bool {.inline, compileTime.} =
    ## Checks if all procs in list have the same signature.
    for i in 1 ..< fns.len(): (if not sameSignatureProc(fns[0], fns[i]): return false)
    result = true

proc genLocalSpecificFn(pIdent: NimNode, assignExpr: NimNode): NimNode {.compileTime.} =
    expectKind(assignExpr[1], {nnkStrLit, nnkLambda})
    # generate function name in the form of /(parent_)*current_locale/
    let curIdent = concatIdent(pIdent, assignExpr[0])

    case assignExpr[1].kind
    of nnkLambda:
        # for lambda, just generate a function as the same as the lambda except name
        return nnkProcDef.newTree(
            curIdent,                                       # ident
            newEmptyNode(),                                 # rewrite patterns
            newEmptyNode(),                                 # generic params
            assignExpr[1][3],                               # params
            assignExpr[1][4],                               # pragma
            newEmptyNode(),                                 # reserved slot
            assignExpr[1][6])                               # proc inner stmts
    of nnkStrLit:
        # since we're generating function for strutils.format,
        # we need to add varargs[string] argument
        let dollar = nnkAccQuoted.newTree(ident("$"))
        let args = nnkIdentDefs.newTree(
            ident("arguments"),
            nnkBracketExpr.newTree(ident("varargs"), ident("string"), dollar),
            nnkBracket.newTree())
        # generate strutils.format call
        let callStmt = newCall(
            ident("format"),
            assignExpr[1], ident("arguments"))
        # this will generate a proc like this:
        # proc curIdent(args: varargs[string]): string {.inline.} = strutils.format(translation[1], args)
        return nnkProcDef.newTree(
            curIdent,                                       # ident
            newEmptyNode(),                                 # rewrite patterns
            newEmptyNode(),                                 # generic params
            nnkFormalParams.newTree(ident("string"), args), # params
            nnkPragma.newTree(ident("inline")),             # pragma
            newEmptyNode(),                                 # reserved slot
            newStmtList(nnkReturnStmt.newTree(callStmt)))   # proc inner stmts
    else: assert(false) # should not reach here

proc generateLookupFn(shouldExportLookup: bool, enumT: NimNode,
                curIdent: NimNode, signature: NimNode): NimNode {.compileTime.} =
    result = newEmptyNode()
    # allowed enums
    let localeEnums = enumT[2][1..^1].map(e => ident(e.strVal()))

    # case statement "case locale" with locale parameter
    # from function that will be generated soon
    let caseStmt = nnkCaseStmt.newTree(ident("locale"))

    # lookup function will be in `curIdent(locale: enumT, ...)` signature
    # generated function parameters
    let params = nnkFormalParams.newTree(
        signature[3][0],
        nnkIdentDefs.newTree(ident("locale"), ident(enumT[0].strVal()), newEmptyNode()))
    # arguments to call locale specific functions
    var arguments: seq[NimNode]

    # generate params def and arguments ident
    for i in 1 ..< signature[3].len():
        arguments.add signature[3][i][0].copyNimTree()
        params.add signature[3][i].copyNimTree()

    # generate `of branches` for all available locales
    for available in localeEnums:
        let fn = concatIdent(curIdent, available)
        let callStmt = nnkCall.newTree(fn)
        for arg in arguments: callStmt.add arg
        # generate `of Branch` like:
        # of locale1: return curIdent_locale1(args)
        let returnStmt = nnkReturnStmt.newTree(callStmt)
        caseStmt.add nnkOfBranch.newTree(available, returnStmt)

    # this will generate a proc like this:
    # proc curIdent(locale: enumT, ...): ... =
    #   case locale
    #   of locale1: return curIdent_locale1(args)
    #   of locale2: return curIdent_locale2(args)
    #   ...
    return nnkProcDef.newTree(
        nnkPostfix.newTree(ident("*"), curIdent),       # ident
        newEmptyNode(),                                 # rewrite patterns
        newEmptyNode(),                                 # generic params
        params,                                         # params
        signature[4],                                   # pragma
        newEmptyNode(),                                 # reserved slot
        newStmtList(caseStmt))                          # codes

proc handleTranslation(enumT: NimNode, shouldExportLookup: bool,
                pIdent: NimNode, namePair: NimNode): NimNode {.compileTime.} =
    ## Handles translation node and generate function for it and its children.
    result = newStmtList()
    # translation can be assign statement, call statement or discard statement
    expectKind(namePair, {nnkAsgn, nnkCall})

    case namePair.kind
    of nnkAsgn:
        # this is a leaf translation and must have a form of `locale = translation`
        expectKind(namePair[0], nnkIdent)
        let locale = namePair[0].strVal()
        # allowed locale ident ( member from enumT )
        let allowedEnums = enumT[2][1..^1].map(e => e.strVal())
        if locale in allowedEnums: return newStmtList(genLocalSpecificFn(pIdent, namePair))
        error(
            "invalid an enum member: got $# but expected one of $#" %
            [escape(locale), allowedEnums.map(l => escape(l)).join(", ")],
            namePair[0])
    of nnkCall:
        # nnkCall statement means we still have children translations, so we must visit them
        expectKind(namePair[0], nnkIdent)
        let curIdent = concatIdent(pIdent, namePair[0])
        expectKind(namePair[1], nnkStmtList)

        # allowed locale ident ( member from enumT )
        let allowedEnums = enumT[2][1..^1].map(e => e.strVal())

        # keep track of all procs we generated for current name ( not its children )
        var generatedFns = initTable[string, NimNode]()

        # generate inner functions and track them if it's a translation
        for statement in namePair[1]:
            let generatedFunctions = handleTranslation(enumT,
                shouldExportLookup,
                curIdent, statement)
            for fn in generatedFunctions: result.add fn

            # check if statement is a translation at current level
            let isTranslation = statement.kind == nnkAsgn and
            statement[0].kind == nnkIdent and
            statement[0].strVal() in allowedEnums
            if isTranslation: generatedFns[statement[0].strVal()] = generatedFunctions[0]

        # check if this call has a locale translation
        # sometimes, user provides only children translations and
        # no translation at current level
        if generatedFns.len() == 0: return result
        var missingLocales = allowedEnums.toHashSet()
        for locale in generatedFns.keys: missingLocales.excl(locale)

        if missingLocales.len() > 0:
            # shall we allow missing locales? and fallback to default?
            let missing = missingLocales.toSeq().map(l => escape(l)).join(", ")
            error("missing $# translations for $#" %
            [missing, escape(identToDotNotation(curIdent))], namePair)
        elif not sameSignatureProcs(generatedFns.values.toSeq()):
            # check if all translations have the same signature to generate lookup Fn
            error("lambda signature of translations for $# is different across locales" %
            escape(identToDotNotation(curIdent)), namePair)
        else:
            # since all functions have the same signature, we can generate lookup function
            let fnSignature = generatedFns.values.toSeq()[0]
            result.add generateLookupFn(shouldExportLookup, enumT, curIdent, fnSignature)
    else: assert(false) # unreachable

macro i18nInit*(enumT: typedesc, exportLookup: static bool, names: untyped): untyped =
    result = newStmtList()
    # translations must be a list of nnkCall statements
    expectKind(names, nnkStmtList)
    expectKind(enumT, nnkSym)

    # resolve enumT to its root declaration
    let rootEnum = nnkTypeDef.newTree(
        ident(enumT.strVal()),
        newEmptyNode(), enumT.getType()[1])
    
    # just a helper to merge multiple NimNode
    template merge(stmts: NimNode) = (for s in stmts: result.add s)

    # generate translations
    for name in names:
        # top-level ( root ) translation must be nnkCall statement
        expectKind(name, nnkCall)
        merge handleTranslation(rootEnum, exportLookup, newEmptyNode(), name)
