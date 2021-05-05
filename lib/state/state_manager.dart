import 'package:anna_chat/model/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatUser = StateProvider((ref) => UserModel());
final userLogged = StateProvider((ref) => UserModel());
