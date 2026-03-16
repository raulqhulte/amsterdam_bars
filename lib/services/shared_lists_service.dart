import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

class SharedListInfo {
  final String id;
  final String name;
  final String inviteCode;

  SharedListInfo({
    required this.id,
    required this.name,
    required this.inviteCode,
  });

  factory SharedListInfo.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return SharedListInfo(
      id: doc.id,
      name: data['name'] as String? ?? '',
      inviteCode: data['inviteCode'] as String? ?? '',
    );
  }
}

class SharedListsService {
  final _db = FirebaseFirestore.instance;

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<SharedListInfo> createList({
    required String listName,
    required String userId,
    required String userName,
  }) async {
    final inviteCode = _generateInviteCode();

    final docRef = await _db.collection('lists').add({
      'name': listName.trim(),
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'createdByUserId': userId,
      'createdByUserName': userName,
      'memberIds': [userId],
      'members': [
        {
          'userId': userId,
          'userName': userName,
        }
      ],
    });

    final doc = await docRef.get();
    return SharedListInfo.fromDoc(doc);
  }

  Future<SharedListInfo?> joinListByCode({
    required String inviteCode,
    required String userId,
    required String userName,
  }) async {
    final query = await _db
        .collection('lists')
        .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final data = doc.data();

    final memberIds =
        List<String>.from((data['memberIds'] as List?) ?? const []);
    final members =
        List<Map<String, dynamic>>.from((data['members'] as List?) ?? const []);

    if (!memberIds.contains(userId)) {
      memberIds.add(userId);
      members.add({
        'userId': userId,
        'userName': userName,
      });

      await doc.reference.update({
        'memberIds': memberIds,
        'members': members,
      });
    }

    return SharedListInfo.fromDoc(doc);
  }
}