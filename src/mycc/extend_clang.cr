class Clang::TranslationUnit
  def has_errors?
    count = LibC.clang_getNumDiagnostics(self)
    (0...count).any? do |i|
      diag = LibC.clang_getDiagnostic(self, i)
      severity = LibC.clang_getDiagnosticSeverity(diag)
      LibC.clang_disposeDiagnostic(diag)
      severity >= LibC::CXDiagnosticSeverity::Error
    end
  end

  def error_messages : Array(String)
    count = LibC.clang_getNumDiagnostics(self)
    (0...count).map do |i|
      diag = LibC.clang_getDiagnostic(self, i)
      severity = LibC.clang_getDiagnosticSeverity(diag)
      msg = if severity >= LibC::CXDiagnosticSeverity::Error
              str = LibC.clang_formatDiagnostic(diag, LibC.clang_defaultDiagnosticDisplayOptions)
              Clang.string(str)
            end
      LibC.clang_disposeDiagnostic(diag)
      msg
    end.compact
  end
end
