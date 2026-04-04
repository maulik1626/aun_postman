enum BodyType {
  none,
  rawJson,
  rawXml,
  rawText,
  rawHtml,
  formData,
  urlEncoded,
  binary;

  String get label {
    switch (this) {
      case BodyType.none:
        return 'None';
      case BodyType.rawJson:
        return 'JSON';
      case BodyType.rawXml:
        return 'XML';
      case BodyType.rawText:
        return 'Text';
      case BodyType.rawHtml:
        return 'HTML';
      case BodyType.formData:
        return 'Form Data';
      case BodyType.urlEncoded:
        return 'URL Encoded';
      case BodyType.binary:
        return 'Binary';
    }
  }
}
