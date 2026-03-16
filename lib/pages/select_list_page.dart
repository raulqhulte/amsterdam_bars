import 'package:flutter/material.dart';

import '../services/shared_lists_service.dart';
import '../services/user_session.dart';

class SelectListPage extends StatefulWidget {
  const SelectListPage({super.key});

  @override
  State<SelectListPage> createState() => _SelectListPageState();
}

class _SelectListPageState extends State<SelectListPage> {
  final _listsService = SharedListsService();
  final _session = UserSession();

  final _createController = TextEditingController();
  final _joinController = TextEditingController();

  bool _loading = false;

  Future<void> _createList() async {
    final name = _createController.text.trim();
    if (name.isEmpty) return;

    setState(() => _loading = true);

    final userId = await _session.getOrCreateUserId();
    final userName = await _session.getUserName() ?? '';

    final list = await _listsService.createList(
      listName: name,
      userId: userId,
      userName: userName,
    );

    await _session.saveCurrentList(
      listId: list.id,
      listName: list.name,
      inviteCode: list.inviteCode,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  Future<void> _joinList() async {
    final code = _joinController.text.trim();
    if (code.isEmpty) return;

    setState(() => _loading = true);

    final userId = await _session.getOrCreateUserId();
    final userName = await _session.getUserName() ?? '';

    final list = await _listsService.joinListByCode(
      inviteCode: code,
      userId: userId,
      userName: userName,
    );

    if (list == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('List not found')),
      );
      return;
    }

    await _session.saveCurrentList(
      listId: list.id,
      listName: list.name,
      inviteCode: list.inviteCode,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _createController.dispose();
    _joinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Shared list')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Create a new list'),
            const SizedBox(height: 8),

            TextField(
              controller: _createController,
              decoration: const InputDecoration(
                labelText: 'List name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _createList,
              child: const Text('Create list'),
            ),

            const SizedBox(height: 32),

            const Text('Join with invite code'),
            const SizedBox(height: 8),

            TextField(
              controller: _joinController,
              decoration: const InputDecoration(
                labelText: 'Invite code',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _joinList,
              child: const Text('Join list'),
            ),
          ],
        ),
      ),
    );
  }
}