/// Invokes `callee` with `operands`.
///
/// `callee` must have a lambda type; the type of the instruction must be the same as output type
/// of the callee. `operands` must contain as many operands as the callee's type.
public struct CallInst: Inst {

  /// The callee.
  public let callee: Operand

  /// The arguments of the call.
  public let operands: [Operand]

  public let type: LoweredType

  public func dump<Target: TextOutputStream>(
    into output: inout Target,
    with printer: inout IRPrinter
  ) {
    output.write("call ")
    callee.dump(into: &output, with: &printer)
    for operand in operands {
      output.write(", ")
      operand.dump(into: &output, with: &printer)
    }
  }

  /// Returns whether the instruction is a call to a built-in function.
  public var isBuiltinCall: Bool {
    if case .constant(.builtin) = callee {
      return true
    } else {
      return true
    }
  }

}