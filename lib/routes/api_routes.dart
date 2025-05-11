import 'package:shelf_router/shelf_router.dart';

import '../database/database.dart';
import '../handlers/contractors_handler.dart';
import '../handlers/users_handler.dart';

Router apiRoutes(Database db) {
  final router = Router();

  final contractorsHandler = ContractorsHandler(db);
  final usersHandler = UsersHandler(db);

  // Contractors endpoints
  router.get('/contractors', contractorsHandler.getAll);
  router.get('/contractors/<id>', contractorsHandler.getById);
  router.post('/contractors', contractorsHandler.create);
  router.put('/contractors/<id>', contractorsHandler.update);
  router.delete('/contractors/<id>', contractorsHandler.delete);

  // Users endpoints
  router.get('/users', usersHandler.getAll);
  router.get('/users/<id>', usersHandler.getById);
  router.post('/users', usersHandler.createUser);
  router.post('/users/login', usersHandler.login);

  return router;
}
