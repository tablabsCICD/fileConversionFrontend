class ConversionHelper {
  /// "DOCX to PDF" → ["docx"]
  static List<String> allowedExtensionsFromTitle(String title) {
    final lower = title.toLowerCase();

    if (lower.startsWith("pdf")) return ["pdf"];
    if (lower.startsWith("docx")) return ["docx"];
    if (lower.startsWith("doc ")) return ["doc"];
    if (lower.startsWith("png")) return ["png"];
    if (lower.startsWith("jpg")) return ["jpg", "jpeg"];
    if (lower.startsWith("mp4")) return ["mp4"];
    if (lower.startsWith("mp3")) return ["mp3"];
    if (lower.startsWith("wav")) return ["wav"];
    if (lower.startsWith("csv")) return ["csv"];
    if (lower.startsWith("json")) return ["json"];
    if (lower.startsWith("xml")) return ["xml"];
    if (lower.startsWith("txt")) return ["txt"];
    if (lower.startsWith("markdown")) return ["md"];

    return [];
  }

  static String subtitleFromTitle(String title) {
    return "Convert ${title.split(' to ').first} files easily.";
  }
}
