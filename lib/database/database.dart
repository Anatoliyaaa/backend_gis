import 'package:dotenv/dotenv.dart';
import 'package:postgres/postgres.dart';

class Database {
  late Connection connection;

  Database();

  Future<void> open() async {
    final env = DotEnv()..load();

    connection = await Connection.open(
      Endpoint(
        host: env['DB_HOST']!,
        port: int.parse(env['DB_PORT']!),
        database: env['DB_NAME']!,
        username: env['DB_USERNAME']!,
        password: env['DB_PASSWORD']!,
      ),
      settings: ConnectionSettings(sslMode: SslMode.disable),
    );

    print('Connected to PostgreSQL');
  }

  Future<void> close() async {
    await connection.close();
    print('Connection closed');
  }
}
