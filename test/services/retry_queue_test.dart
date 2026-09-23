import 'package:cracha_app/services/retry_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RetryQueue.resetForTest();
  });

  group('RetryQueue', () {
    test('add enfileira e persiste', () async {
      final op = PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {'nome': 'João'},
        createdAt: DateTime.now(),
      );
      await RetryQueue.add(op);
      expect(RetryQueue.length, 1);
      expect(RetryQueue.pending.first.id, 'badge-1');

      // A fila sobrevive a um "reboot" (novo init lendo do storage).
      RetryQueue.resetForTest();
      await RetryQueue.init();
      expect(RetryQueue.length, 1);
      expect(RetryQueue.pending.first.payload['nome'], 'João');
    });

    test('add do mesmo id+tipo substitui em vez de duplicar', () async {
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {'nome': 'Antigo'},
        createdAt: DateTime.now(),
      ));
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {'nome': 'Novo'},
        createdAt: DateTime.now(),
      ));

      expect(RetryQueue.length, 1);
      expect(RetryQueue.pending.first.payload['nome'], 'Novo');
    });

    test('add com mesmo id mas tipo diferente coexiste', () async {
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.deleteBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));

      expect(RetryQueue.length, 2);
      expect(RetryQueue.ofType(PendingOpType.saveBadge), hasLength(1));
      expect(RetryQueue.ofType(PendingOpType.deleteBadge), hasLength(1));
    });

    test('markAttemptremove ao atingir o limite de 3', () async {
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));

      expect(await RetryQueue.markAttempt('badge-1'), isFalse);
      expect(RetryQueue.length, 1);
      expect(await RetryQueue.markAttempt('badge-1'), isFalse);
      expect(RetryQueue.length, 1);

      // 3ª tentativa: esgotada, some da fila.
      expect(await RetryQueue.markAttempt('badge-1'), isTrue);
      expect(RetryQueue.length, 0);
    });

    test('markAttempt de id ausente não faz nada', () async {
      expect(await RetryQueue.markAttempt('nao-existe'), isFalse);
    });

    test('remove apaga só a operação do tipo pedido', () async {
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.deleteBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));

      await RetryQueue.remove('badge-1', type: PendingOpType.saveBadge);
      expect(RetryQueue.ofType(PendingOpType.saveBadge), isEmpty);
      expect(RetryQueue.ofType(PendingOpType.deleteBadge), hasLength(1));
    });

    test('entrada corrompida não derruba a fila inteira', () async {
      SharedPreferences.setMockInitialValues({
        'pending_operations':
            '[{"id":"ok","type":"saveBadge","payload":{},"createdAt":"2026-01-01T00:00:00.000","attempts":0},{"id":"ruim","type":"tipo-inexistente","payload":"nao-e-map","createdAt":12345}]',
      });
      RetryQueue.resetForTest();
      await RetryQueue.init();

      // A entrada válida sobrevive; a corrompida é descartada.
      expect(RetryQueue.length, 1);
      expect(RetryQueue.pending.first.id, 'ok');
    });

    test('clear esvazia a fila', () async {
      await RetryQueue.add(PendingOperation(
        id: 'badge-1',
        type: PendingOpType.saveBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));
      await RetryQueue.clear();
      expect(RetryQueue.isEmpty, isTrue);
    });

    test('isEmpty/isNotEmpty refletem o estado', () async {
      expect(RetryQueue.isEmpty, isTrue);
      expect(RetryQueue.isNotEmpty, isFalse);

      await RetryQueue.add(PendingOperation(
        id: 'b',
        type: PendingOpType.saveBadge,
        payload: const {},
        createdAt: DateTime.now(),
      ));
      expect(RetryQueue.isNotEmpty, isTrue);
    });
  });
}
