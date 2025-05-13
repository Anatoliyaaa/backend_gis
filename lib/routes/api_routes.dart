import 'package:dotenv/dotenv.dart';
import 'package:shelf_router/shelf_router.dart';

import '../database/database.dart';
import '../handlers/contractors_handler.dart';
import '../handlers/deliveries_handler.dart';
import '../handlers/locations_handler.dart';
import '../handlers/road_routing_handler.dart';
import '../handlers/routes_handler.dart';
import '../handlers/users_handler.dart';
import '../handlers/vehicles_handler.dart';

Router apiRoutes(Database db, DotEnv env) {
  final router = Router();

  final contractorsHandler = ContractorsHandler(db);
  final usersHandler = UsersHandler(db);
  final locationsHandler = LocationsHandler(db);
  final routesHandler = RoutesHandler(db);
  final deliveriesHandler = DeliveriesHandler(db);
  final vehiclesHandler = VehiclesHandler(db);
  final roadRoutingHandler = RoadRoutingHandler(env);

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
  router.post('/users/verify_otp', usersHandler.verifyOtp);
  router.post('/users/send_otp', usersHandler.sendOtp);

  // Локации
  router.get('/locations', locationsHandler.getAll);

  // Маршруты
  router.get('/routes', routesHandler.getAll);
  router.post('/routes', routesHandler.create);
  router.put('/routes/<id|[0-9]+>', routesHandler.update);
  router.delete('/routes/<id|[0-9]+>', routesHandler.delete);

  // Доставки
  router.get('/deliveries', deliveriesHandler.getAll);
  router.post('/deliveries', deliveriesHandler.create);
  router.put('/deliveries/<id|[0-9]+>', deliveriesHandler.update);
  router.delete('/deliveries/<id|[0-9]+>', deliveriesHandler.delete);

  // Транспорт
  router.get('/vehicles', vehiclesHandler.getAll);
  router.get('/vehicles/<id|[0-9]+>', vehiclesHandler.getById);

  // Дорожная маршрутизация (OpenRouteService)
  router.get('/routes/road', roadRoutingHandler.getRoute);

  return router;
}
