/// A floating-point number literal expression.
public struct FloatLiteralExpr: Expr {

  public static let kind = NodeKind.floatLiteralExpr

  /// The value of the literal.
  public let value: String

  public init(value: String) {
    self.value = value
  }

}
