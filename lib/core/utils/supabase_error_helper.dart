import 'package:supabase_flutter/supabase_flutter.dart';
import '../error_handling/error_handler.dart';

/// Helper pour gérer les erreurs Supabase de manière cohérente
class SupabaseErrorHelper {
  /// Exécute une opération Supabase avec gestion d'erreurs améliorée
  static Future<T> executeWithErrorHandling<T>(
    Future<T> Function() operation, {
    String? context,
    T? defaultValue,
  }) async {
    try {
      return await operation();
    } on PostgrestException catch (e) {
      print('❌ PostgrestException [$context]: ${e.code} - ${e.message}');
      print('   Détails: ${e.details}');
      throw Exception(ErrorHandler.getUserFriendlyMessage(e));
    } on AuthException catch (e) {
      print('❌ AuthException [$context]: ${e.statusCode} - ${e.message}');
      throw Exception(ErrorHandler.getUserFriendlyMessage(e));
    } on StorageException catch (e) {
      print('❌ StorageException [$context]: ${e.statusCode} - ${e.message}');
      throw Exception(ErrorHandler.getUserFriendlyMessage(e));
    } on Exception catch (e) {
      print('❌ Exception [$context]: $e');
      // Si c'est déjà une Exception avec un message utile, la relancer
      throw e;
    } catch (e, stackTrace) {
      print('❌ Erreur inattendue [$context]: $e');
      print('   Stack trace: $stackTrace');
      if (defaultValue != null) {
        return defaultValue;
      }
      throw Exception(ErrorHandler.getUserFriendlyMessage(e));
    }
  }

  /// Vérifie si une erreur est une erreur de réseau
  static bool isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('connection refused') ||
        errorString.contains('timeout');
  }

  /// Vérifie si une erreur est une erreur de permission
  static bool isPermissionError(dynamic error) {
    if (error is PostgrestException) {
      return error.code == '42501' || error.code == 'PGRST301';
    }
    final errorString = error.toString().toLowerCase();
    return errorString.contains('permission') ||
        errorString.contains('unauthorized') ||
        errorString.contains('forbidden') ||
        errorString.contains('access denied');
  }

  /// Vérifie si une erreur est une erreur de validation
  static bool isValidationError(dynamic error) {
    if (error is PostgrestException) {
      return error.code == '23505' || error.code == '23503';
    }
    final errorString = error.toString().toLowerCase();
    return errorString.contains('validation') ||
        errorString.contains('invalid') ||
        errorString.contains('required');
  }
}

