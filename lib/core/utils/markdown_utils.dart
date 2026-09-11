/// Helpers for cleaning model output for UI and TTS.
class MarkdownUtils {
  MarkdownUtils._();

  /// Strip markdown / widget blocks so TTS does not read syntax aloud.
  static String forSpeech(String input) {
    var text = input;
    // Remove fenced code / widget blocks
    text = text.replaceAll(RegExp(r'```[\s\S]*?```'), ' ');
    text = text.replaceAll(RegExp(r'`[^`]+`'), ' ');
    // widget: lines
    text = text.replaceAll(RegExp(r'widget:\w+\s*'), ' ');
    // headings, bold, italic, links
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\*\*|__'), '');
    text = text.replaceAll(RegExp(r'\*|_'), '');
    text = text.replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
    text = text.replaceAll(RegExp(r'^\s*[-*•]\s+', multiLine: true), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }

  /// Prefer a short spoken summary: first non-empty sentence-ish chunk.
  static String spokenSummary(String verdict, String explanation) {
    final combined = forSpeech(
      explanation.trim().isEmpty ? verdict : '$verdict. $explanation',
    );
    if (combined.length <= 280) return combined;
    final cut = combined.substring(0, 280);
    final lastStop = cut.lastIndexOf(RegExp(r'[.!?]'));
    return lastStop > 40 ? cut.substring(0, lastStop + 1) : '$cut…';
  }
}
