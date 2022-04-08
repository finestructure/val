/// A parameter declaration in a function or subscript declaration.
public struct ParamDecl: Decl {

  /// The label of the parameter.
  public var label: SourceRepresentable<Identifier>

  /// The identifier of the parameter.
  public var identifier: SourceRepresentable<Identifier>

  /// The type annotation of the declaration, if any.
  public var annotation: SourceRepresentable<TypeExpr>?

  /// The default value of the declaration, if any.
  public var defaultValue: SourceRepresentable<Expr>?

  public var range: SourceRange?

  public func accept<V: DeclVisitor>(_ visitor: inout V) -> V.Result {
    visitor.visit(param: self)
  }

}
