// AI_EXECUTION_PLAN.md Phase 8, P8-02 - chat message deduplication.
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellness/app/models/message_model.dart';

MessageModel _msg({
  required String id,
  String? clientMessageId,
  String content = 'hi',
}) {
  return MessageModel(
    id: id,
    conversationId: 'conv-1',
    senderId: 'user-1',
    receiverId: 'user-2',
    content: content,
    createdAt: DateTime(2026, 1, 1),
    clientMessageId: clientMessageId,
  );
}

void main() {
  group('MessageModel.isDuplicate', () {
    test('same id is a duplicate', () {
      final existing = [_msg(id: 'server-1')];
      final incoming = _msg(id: 'server-1');
      expect(MessageModel.isDuplicate(existing, incoming), isTrue);
    });

    test('different id, no clientMessageId match, is not a duplicate', () {
      final existing = [_msg(id: 'server-1')];
      final incoming = _msg(id: 'server-2');
      expect(MessageModel.isDuplicate(existing, incoming), isFalse);
    });

    test(
      'matches an optimistic entry by clientMessageId even before the REST '
      'response has replaced its temp id with the real server id '
      '(the race this whole mechanism exists to close)',
      () {
        // Optimistic local message: id == clientMessageId == the temp id,
        // exactly how ChatController.sendMessage() creates it.
        final optimistic = _msg(id: 'temp-123', clientMessageId: 'temp-123');
        // Socket echo of the same send, now carrying the real server id.
        final socketEcho = _msg(id: 'server-99', clientMessageId: 'temp-123');

        expect(MessageModel.isDuplicate([optimistic], socketEcho), isTrue);
      },
    );

    test('an empty clientMessageId never matches anything', () {
      final existing = [_msg(id: 'a', clientMessageId: '')];
      final incoming = _msg(id: 'b', clientMessageId: '');
      expect(MessageModel.isDuplicate(existing, incoming), isFalse);
    });

    test('empty message list has no duplicates', () {
      expect(MessageModel.isDuplicate([], _msg(id: 'a')), isFalse);
    });
  });
}
