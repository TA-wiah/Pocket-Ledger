import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/person_model.dart';
import '../models/transaction_model.dart';
import '../services/hive_service.dart';
import 'transaction_provider.dart';

class PersonNotifier extends StateNotifier<List<PersonModel>> {
  PersonNotifier() : super(_loadSorted());

  static List<PersonModel> _loadSorted() {
    final list = HiveService.peopleBox.values.toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  void _refresh() => state = _loadSorted();

  Future<PersonModel> addPerson({required String name, String notes = ''}) async {
    final person = PersonModel(
      id: const Uuid().v4(),
      name: name,
      notes: notes,
      createdAt: DateTime.now(),
    );
    await HiveService.peopleBox.put(person.id, person);
    _refresh();
    return person;
  }

  Future<void> updatePerson(PersonModel person, {required String name, String notes = ''}) async {
    person.name = name;
    person.notes = notes;
    await person.save();
    _refresh();
  }

  Future<void> deletePerson(String id) async {
    await HiveService.peopleBox.delete(id);
    _refresh();
  }
}

final personProvider = StateNotifierProvider<PersonNotifier, List<PersonModel>>(
  (ref) => PersonNotifier(),
);

class PersonBalance {
  final PersonModel person;
  final double given;
  final double received;
  final int transactionCount;
  final DateTime? lastActivity;

  const PersonBalance({
    required this.person,
    required this.given,
    required this.received,
    required this.transactionCount,
    required this.lastActivity,
  });

  double get balance => given - received;
}

final personBalancesProvider = Provider<List<PersonBalance>>((ref) {
  final people = ref.watch(personProvider);
  final transactions = ref.watch(transactionProvider);

  return people.map((person) {
    final personTx = transactions.where((t) => t.personId == person.id).toList();
    final given = personTx
        .where((t) => t.category == 'Loan Given')
        .fold(0.0, (sum, t) => sum + t.amount);
    final received = personTx
        .where((t) => t.category == 'Loan Received')
        .fold(0.0, (sum, t) => sum + t.amount);
    DateTime? lastActivity;
    for (final t in personTx) {
      if (lastActivity == null || t.date.isAfter(lastActivity)) {
        lastActivity = t.date;
      }
    }
    return PersonBalance(
      person: person,
      given: given,
      received: received,
      transactionCount: personTx.length,
      lastActivity: lastActivity,
    );
  }).toList();
});

List<TransactionModel> transactionsForPerson(List<TransactionModel> all, String personId) {
  final list = all.where((t) => t.personId == personId).toList();
  list.sort((a, b) => b.date.compareTo(a.date));
  return list;
}
