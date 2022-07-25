/// A set of declarations at the top-level of a source file.
public struct SourceDeclSet: Node, LexicalScope {

  public static let kind = NodeKind.sourceDeclSet

  /// The source from which the declarations where parser.
  public var file: SourceFile?

  /// The declarations in the set.
  public var decls: [AnyDeclID]

  public init(file: SourceFile? = nil, decls: [AnyDeclID] = []) {
    self.file = file
    self.decls = decls
  }

}
