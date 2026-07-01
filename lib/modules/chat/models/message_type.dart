enum MessageType {
  text,
  image,
  file,
  audio,
  video,
  call;

  String get value => name;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => MessageType.text,
    );
  }
}
