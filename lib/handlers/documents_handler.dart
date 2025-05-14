import 'dart:convert';

import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';

import '../database/database.dart';

class DocumentsHandler {
  final Database db;

  DocumentsHandler(this.db);

  Future<Response> getDocumentsByDelivery(
      Request req, String deliveryId) async {
    try {
      final result = await db.connection.execute(
        Sql.named('''
    SELECT c.contract_number, c.start_date, c.end_date, c.terms_conditions,
          ctr.name, ctr.contact_person, ctr.phone
    FROM deliveries d
    JOIN contracts c ON d.contract_id = c.id
    JOIN contractors ctr ON c.contractor_id = ctr.id
    WHERE d.id = @delivery_id
  '''),
        parameters: {'delivery_id': int.parse(deliveryId)},
      );

      if (result.isEmpty) {
        return Response.notFound('Документы для доставки не найдены');
      }

      final row = result.first;
      final document = {
        'contract_number': row[0],
        'start_date': row[1].toString(),
        'end_date': row[2].toString(),
        'terms_conditions': row[3],
        'contractor': {
          'name': row[4],
          'contact_person': row[5],
          'phone': row[6],
        }
      };

      return Response.ok(jsonEncode(document), headers: {
        'Content-Type': 'application/json',
      });
    } catch (e) {
      return Response.internalServerError(
          body: 'Ошибка получения документов: $e');
    }
  }
}
