import 'package:nabour_app/services/contacts_service.dart';
import 'package:nabour_app/services/friend_request_service.dart';

/// Merged UIDs for network-only rides: Nabour contacts from phone + accepted friend peers.
class PassengerAllowedDriverUids {
  PassengerAllowedDriverUids._();

  static Future<List<String>> loadMergedUidList({
    ContactsService? contactsService,
    bool forceRefreshContacts = false,
  }) async {
    await FriendRequestService.instance.ensureFriendPeersForAcceptedOutgoing();
    final svc = contactsService ?? ContactsService();
    final users = await svc.loadContactUsers(forceRefresh: forceRefreshContacts);
    final peers = await FriendRequestService.instance.loadFriendPeerUidSet();
    final fromAgenda = users.map((u) => u.uid).toSet();
    final merged = {...fromAgenda, ...peers};
    return merged.toList();
  }
}
