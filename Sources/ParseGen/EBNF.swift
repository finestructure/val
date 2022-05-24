import CitronLexerModule

enum EBNF {
  struct Token: EBNFNode, Hashable {
    typealias ID = EBNFParser.CitronTokenCode

    init(_ id: ID, _ content: Substring, at position: SourceRegion) {
      self.id = id
      self.text = content
      self.position = position
    }

    let id: ID
    let text: Substring
    let position: SourceRegion

    func dumped(level: Int) -> String { String(text) }
  }

  typealias RuleList = [Rule]
  struct Rule: EBNFNode {
    enum Kind { case plain, token, oneOf, regexp }
    let kind: Kind
    let lhs: Token
    let rhs: AltList
  }

  typealias AltList = [Alt]
  typealias Alt = TermList
  typealias TermList = [Term]

  enum Term: EBNFNode {
    case group(AltList)
    case symbol(Token)
    case literal(String, position: SourceRegion)
    case regexp(Substring, position: SourceRegion)
    indirect case quantified(Term, Character, position: SourceRegion)
  }

  struct Grammar {
    typealias Symbol = Substring
    let rules: [Symbol: AltList]
    let start: Symbol
  }
}

extension EBNF.Token: CustomStringConvertible {
  var description: String {
    "Token(.\(id), \(String(reflecting: text)), at: \(String(reflecting: position)))"
  }
}


/// An EBNFNode node.
protocol EBNFNode {
  /// The region of source parsed as this node.
  var position: SourceRegion { get }

  /// A string representation in the original syntax.
  func dumped(level: Int)-> String
}

extension EBNFNode {
  var dump: String { dumped(level: 0) }
}

extension Array: EBNFNode where Element: EBNFNode {
  var position: SourceRegion {
    first != nil ? first!.position...last!.position : .empty
  }

  func dumped(level: Int) -> String {
    self.lazy.map { $0.dumped(level: level + 1) }
      .joined(separator: Self.dumpSeparator(level: level))
  }

  static func dumpSeparator(level: Int) -> String {
    return Element.self == EBNF.Rule.self ? "\n\n"
      : Element.self == EBNF.Alt.self ? (level == 0 ? "\n  " : " | ")
      : " "
  }
}

extension Optional: EBNFNode where Wrapped: EBNFNode {
  var position: SourceRegion {
    self?.position ?? .empty
  }
  func dumped(level: Int) -> String { self?.dumped(level: level + 1) ?? "" }
}

extension EBNF.Rule {
  var position: SourceRegion { lhs.position...rhs.position }
  func dumped(level: Int) -> String {
    let k = [.oneOf: " (one of)", .token: " (token)", .regexp: " (regexp)"][kind]

    return """
    \(position): note: rule
    \(lhs.dump) ::=\(k ?? "")
      \(rhs.dump)
    """
  }
}

extension EBNF.Term {
  var position: SourceRegion {
    switch self {
    case .group(let g): return g.position
    case .symbol(let s): return s.position
    case .regexp(_, let p): return p
    case .literal(_, let p): return p
    case .quantified(_, _, let p): return p
    }
  }
  func dumped(level: Int) -> String {
    switch self {
    case .group(let g): return "( \(g.dumped(level: level + 1) )"
    case .symbol(let s): return s.dumped(level: level)
    case .literal(let s, _):
      return "'\(s.replacingOccurrences(of: "'", with: "\\'"))'"
    case .regexp(let s, _): return "/\(s)/"
    case .quantified(let t, let q, _): return t.dumped(level: level + 1) + String(q)
    }
  }
}
