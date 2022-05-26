import CitronLexerModule

extension EBNF.Grammar {
  /// Adds errors to `errors` for any symbols that don't appear on the LHS of a definition.
  static func checkAllSymbolsDefined(in definitions: Definitions, into errors: inout EBNFErrorLog) {
    for d in definitions.values {
      checkDefined(d.alternatives)
    }

    func checkDefined(_ x: EBNF.Token) {
      if definitions[x.text] == nil {
        errors.insert(Error("undefined symbol '\(x.text)'", at: x.position))
      }
    }

    func checkDefined(_ x: EBNF.AlternativeList) {
      for a in x {
        for t in a { checkDefined(t) }
      }
    }

    func checkDefined(_ x: Term) {
      switch x {
      case .group(let g): checkDefined(g)
      case .symbol(let s): checkDefined(s)
      case .regexp(_, _): do {}
      case .literal(_, _): do {}
      case .quantified(let t, _, _): checkDefined(t)
      }
    }
  }

  /// Adds errors to `errors` for any symbols that can't be produced by the start symbol.
  func checkAllSymbolsReachable(into errors: inout EBNFErrorLog) {
    var reachable: Set<Symbol> = []
    reach(start)

    for d in definitions.values {
      if !reachable.contains(d.lhs.text) {
        errors.insert(
          Error("Symbol '\(d.lhs.text)' is unreachable from start symbol '\(start.text)'",
                at: d.lhs.position))
      }
    }

    func reach(_ x: Token) {
      if reachable.insert(x.text).inserted {
        reach(definitions[x.text]!.alternatives)
      }
    }

    func reach(_ x: EBNF.AlternativeList) {
      for a in x {
        for t in a { reach(t) }
      }
    }

    func reach(_ x: Term) {
      switch x {
      case .group(let g): reach(g)
      case .symbol(let s): reach(s)
      case .regexp(_, _): do {}
      case .literal(_, _): do {}
      case .quantified(let t, _, _): reach(t)
      }
    }
  }

  /// Adds errors to `errors` for any `(token)` rules that are (directly or
  /// indirectly) self-referential.
  func checkNoRecursiveTokens(into errors: inout EBNFErrorLog) {
    var stack: [Token] = []
    var visited: Set<String> = []
    for d in definitions.values where d.kind == .token {
      visit(d.lhs)
    }

    func visit(_ x: Token) {
      stack.append(x)
      defer { stack.removeLast() }

      if visited.contains(x.text) {
        errors.insert(
          Error(
            "Recursive token definition '\(stack[0].text)'", at: stack[0].position,
            notes: stack.dropFirst().map {
              .init(message: "via: '\($0.text)'", site: $0.position)
            }))
      }
      else {
        visited.insert(x.text)
        defer { visited.remove(x.text) }

        visit(definitions[x.text]!.alternatives)
      }
    }

    func visit(_ x: EBNF.AlternativeList) {
      for a in x {
        for t in a { visit(t) }
      }
    }

    func visit(_ x: Term) {
      switch x {
      case .group(let g): visit(g)
      case .symbol(let s): visit(s)
      case .regexp(_, _): do {}
      case .literal(_, _): do {}
      case .quantified(let t, _, _): visit(t)
      }
    }
  }

  /// Returns the set of literal strings recognized as terminals.
  func literals() -> Set<String> {
    var visited: Set<String> = []
    var r: Set<String> = []

    visit(start)

    func visit(_ x: Token) {
      if !visited.insert(x.text).inserted { return }
      let d = definitions[x.text]!
      if d.kind == .plain || d.kind == .oneOf {
        visit(d.alternatives)
      }
    }

    func visit(_ x: AlternativeList) {
      for a in x {
        for t in a { visit(t) }
      }
    }

    func visit(_ x: Term) {
      switch x {
      case .group(let g): 
        visit(g)
      case .symbol(let s): 
        visit(s)
      case .regexp(_, _): do {}
      case .literal(let l, _): 
        r.insert(l)
      case .quantified(let t, _, _):
        visit(t)
      }
    }
    return r
  }

  /*
  /// Returns a mapping from terminal symbols to the regular expressions that describe them.
  func regexps() -> [Symbol: String] {
    var r: [Alternative: String] = [:]
    var memo: [String: String] = []

    func visit(_ x: Token, ) {
      if memo[x.text] != nil { return }

      let d = definitions[x.text]!
      if d.kind == .token || d.kind == .regexp {
        memo[x.text] = visitToken(d.alternatives)
      }
      else {
        memo[x.text] = ""
        visitNonterminal(d.alternatives)
      }
    }

    func visit(_ x: AlternativeList) {
      for a in x {
        for t in a { visit(t) }
      }
    }

    func visit(_ x: Term) {
      switch x {
      case .group(let g):
        visit(g)
      case .symbol(let s):
        visit(s)
      case .regexp(_, _): do {}
      case .literal(let l, _):
        r.insert(l)
      case .quantified(let t, _, _):
        visit(t)
      }
    }

    visit(start)
    return r
  }
   */
}
