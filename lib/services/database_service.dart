import 'package:postgres/postgres.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../models/property_model.dart';
import '../models/message_model.dart';

class DatabaseService {
  static DatabaseService? _instance;
  PostgreSQLConnection? _connection;

  DatabaseService._();

  static DatabaseService get instance {
    _instance ??= DatabaseService._();
    return _instance!;
  }

  // Подключение к PostgreSQL
  Future<void> connect() async {
    try {
      // Если уже подключено, не переподключаемся
      if (_connection != null && !_connection!.isClosed) {
        print('✅ Уже подключено к PostgreSQL');
        return;
      }
      
      print('🔄 Подключение к PostgreSQL...');
      
      // Подключение к удаленному серверу PostgreSQL
      _connection = PostgreSQLConnection(
        '185.239.49.27', // Хост сервера
        5432,            // Порт
        'pavel',         // База данных
        username: 'postgres',
        password: 'SArtem2006',
        timeoutInSeconds: 30,
        queryTimeoutInSeconds: 30,
        useSSL: false,
      );
      
      await _connection!.open();
      print('✅ Подключено к PostgreSQL на 185.239.49.27 (DB: pavel)');
      await _createTables();
    } catch (e) {
      print('❌ Ошибка подключения к БД: $e');
      _connection = null;
      rethrow;
    }
  }

  // Создание таблиц (каждая в своём try, чтобы ошибка одной не блокировала остальные)
  Future<void> _createTables() async {
    Future<void> exec(String sql, String label) async {
      try {
        await _connection!.execute(sql);
        print('✅ $label');
      } catch (e) {
        print('⚠️  $label: $e');
      }
    }

    await exec('''
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password_hash VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        phone VARCHAR(50),
        avatar_url TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''', 'users');

    await exec('''
      CREATE TABLE IF NOT EXISTS properties (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        title VARCHAR(255) NOT NULL,
        description TEXT NOT NULL,
        location VARCHAR(255) NOT NULL,
        price DECIMAL(15, 2) NOT NULL,
        area DECIMAL(10, 2) NOT NULL,
        rooms INTEGER NOT NULL,
        floor VARCHAR(50) NOT NULL,
        property_type VARCHAR(50) NOT NULL,
        image_url TEXT,
        is_premium BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''', 'properties');

    await exec('''
      CREATE TABLE IF NOT EXISTS favorites (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        property_id INTEGER NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, property_id)
      )
    ''', 'favorites');

    await exec('''
      CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        sender_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        receiver_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        message TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        is_read BOOLEAN DEFAULT FALSE
      )
    ''', 'messages');

    await exec('''
      CREATE INDEX IF NOT EXISTS idx_messages_users
      ON messages(sender_id, receiver_id, created_at)
    ''', 'idx messages');

    await exec('''
      CREATE TABLE IF NOT EXISTS password_reset_codes (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        code VARCHAR(6) NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        expires_at TIMESTAMP NOT NULL,
        is_used BOOLEAN DEFAULT FALSE
      )
    ''', 'password_reset_codes');

    // Корзина (product_id ссылается на локальный каталог, без FK)
    await exec('''
      CREATE TABLE IF NOT EXISTS cart_items (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, product_id)
      )
    ''', 'cart_items');

    // Уведомления
    await exec('''
      CREATE TABLE IF NOT EXISTS inbox_notifications (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        ext_id VARCHAR(64) NOT NULL,
        type VARCHAR(32) NOT NULL,
        title VARCHAR(255) NOT NULL,
        body TEXT NOT NULL,
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id, ext_id)
      )
    ''', 'inbox_notifications');

    await exec('''
      CREATE INDEX IF NOT EXISTS idx_inbox_user
      ON inbox_notifications(user_id, created_at DESC)
    ''', 'idx inbox');

    // Заказы — заголовок + позиции
    await exec('''
      CREATE TABLE IF NOT EXISTS orders (
        id SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        ext_id VARCHAR(32) NOT NULL,
        status VARCHAR(32) NOT NULL DEFAULT 'processing',
        subtotal DECIMAL(15, 2) NOT NULL,
        delivery_fee DECIMAL(15, 2) NOT NULL DEFAULT 0,
        total DECIMAL(15, 2) NOT NULL,
        address VARCHAR(500) NOT NULL DEFAULT '',
        phone VARCHAR(50) NOT NULL DEFAULT '',
        payment_method VARCHAR(32) NOT NULL DEFAULT '',
        delivery_method VARCHAR(32) NOT NULL DEFAULT '',
        created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
        expected_at TIMESTAMP NOT NULL,
        UNIQUE(user_id, ext_id)
      )
    ''', 'orders');

    await exec('''
      CREATE INDEX IF NOT EXISTS idx_orders_user
      ON orders(user_id, created_at DESC)
    ''', 'idx orders');

    await exec('''
      CREATE TABLE IF NOT EXISTS order_items (
        id SERIAL PRIMARY KEY,
        order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
        product_id INTEGER NOT NULL,
        title VARCHAR(255) NOT NULL,
        brand VARCHAR(255) NOT NULL DEFAULT '',
        image_url TEXT,
        price DECIMAL(15, 2) NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1
      )
    ''', 'order_items');

    print('✅ Все таблицы инициализированы');
  }

  // Проверка и переподключение к БД
  Future<bool> _ensureConnection() async {
    try {
      if (_connection == null || _connection!.isClosed) {
        print('🔄 Переподключение к БД...');
        await connect();
      }
      return true;
    } catch (e) {
      print('❌ Не удалось подключиться к БД: $e');
      return false;
    }
  }

  // Хеширование пароля
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Регистрация пользователя
  Future<UserModel?> registerUser({
    required String email,
    required String password,
    required String name,
    String? phone,
  }) async {
    try {
      // Проверяем соединение
      if (!await _ensureConnection()) {
        return null;
      }
      
      final passwordHash = _hashPassword(password);
      
      final result = await _connection!.query(
        '''
          INSERT INTO users (email, password_hash, name, phone)
          VALUES (@email, @password_hash, @name, @phone)
          RETURNING id, email, name, phone, avatar_url, created_at
        ''',
        substitutionValues: {
          'email': email,
          'password_hash': passwordHash,
          'name': name,
          'phone': phone,
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return UserModel(
          id: row[0] as int?,
          email: row[1] as String,
          name: row[2] as String,
          phone: row[3] as String?,
          avatarUrl: row[4] as String?,
          createdAt: row[5] as DateTime?,
        );
      }
      return null;
    } catch (e) {
      print('❌ Ошибка регистрации: $e');
      return null;
    }
  }

  // Вход пользователя
  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      // Проверяем соединение
      if (!await _ensureConnection()) {
        return null;
      }
      
      final passwordHash = _hashPassword(password);
      
      final result = await _connection!.query(
        '''
          SELECT id, email, name, phone, avatar_url, created_at
          FROM users
          WHERE email = @email AND password_hash = @password_hash
        ''',
        substitutionValues: {
          'email': email,
          'password_hash': passwordHash,
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return UserModel(
          id: row[0] as int?,
          email: row[1] as String,
          name: row[2] as String,
          phone: row[3] as String?,
          avatarUrl: row[4] as String?,
          createdAt: row[5] as DateTime?,
        );
      }
      return null;
    } catch (e) {
      print('❌ Ошибка входа: $e');
      return null;
    }
  }

  // Получить пользователя по ID
  Future<UserModel?> getUserById(int id) async {
    try {
      // Проверяем соединение
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }
      
      final result = await _connection!.query(
        '''
          SELECT id, email, name, phone, avatar_url, created_at
          FROM users
          WHERE id = @id
        ''',
        substitutionValues: {'id': id},
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return UserModel(
          id: row[0] as int?,
          email: row[1] as String,
          name: row[2] as String,
          phone: row[3] as String?,
          avatarUrl: row[4] as String?,
          createdAt: row[5] as DateTime?,
        );
      }
      return null;
    } catch (e) {
      print('❌ Ошибка получения пользователя: $e');
      return null;
    }
  }

  // Обновить профиль
  Future<bool> updateUser({
    required int id,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      // Проверяем соединение
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }
      
      await _connection!.query(
        '''
          UPDATE users
          SET name = COALESCE(@name, name),
              phone = COALESCE(@phone, phone),
              avatar_url = COALESCE(@avatar_url, avatar_url)
          WHERE id = @id
        ''',
        substitutionValues: {
          'id': id,
          'name': name,
          'phone': phone,
          'avatar_url': avatarUrl,
        },
      );
      return true;
    } catch (e) {
      print('❌ Ошибка обновления: $e');
      return false;
    }
  }

  // Закрыть соединение
  Future<void> close() async {
    await _connection?.close();
    print('🔌 Соединение с БД закрыто');
  }

  // ========== МЕТОДЫ ДЛЯ ОБЪЯВЛЕНИЙ ==========

  // Создать объявление
  Future<PropertyModel?> createProperty(PropertyModel property) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          INSERT INTO properties (user_id, title, description, location, price, area, rooms, floor, property_type, image_url, is_premium)
          VALUES (@user_id, @title, @description, @location, @price, @area, @rooms, @floor, @property_type, @image_url, @is_premium)
          RETURNING id, user_id, title, description, location, price, area, rooms, floor, property_type, image_url, is_premium, created_at
        ''',
        substitutionValues: {
          'user_id': property.userId,
          'title': property.title,
          'description': property.description,
          'location': property.location,
          'price': property.price,
          'area': property.area,
          'rooms': property.rooms,
          'floor': property.floor,
          'property_type': property.propertyType,
          'image_url': property.imageUrl,
          'is_premium': property.isPremium,
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        return PropertyModel(
          id: row[0] as int,
          userId: row[1] as int,
          title: row[2] as String,
          description: row[3] as String,
          location: row[4] as String,
          price: double.parse(row[5].toString()),
          area: double.parse(row[6].toString()),
          rooms: row[7] as int,
          floor: row[8] as String,
          propertyType: row[9] as String,
          imageUrl: row[10] as String?,
          isPremium: row[11] as bool,
          createdAt: row[12] as DateTime,
        );
      }
      return null;
    } catch (e) {
      print('❌ Ошибка создания объявления: $e');
      return null;
    }
  }

  // Получить все объявления
  Future<List<PropertyModel>> getAllProperties() async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          SELECT id, user_id, title, description, location, price, area, rooms, floor, property_type, image_url, is_premium, created_at
          FROM properties
          ORDER BY is_premium DESC, created_at DESC
        ''',
      );

      print('📊 Загружено объявлений: ${result.length}');
      
      return result.map((row) {
        final imageUrl = row[10] as String?;
        print('🖼️ Объявление "${row[2]}": imageUrl ${imageUrl != null ? "есть (${imageUrl.length} символов)" : "отсутствует"}');
        
        return PropertyModel(
          id: row[0] as int,
          userId: row[1] as int,
          title: row[2] as String,
          description: row[3] as String,
          location: row[4] as String,
          price: double.parse(row[5].toString()),
          area: double.parse(row[6].toString()),
          rooms: row[7] as int,
          floor: row[8] as String,
          propertyType: row[9] as String,
          imageUrl: imageUrl,
          isPremium: row[11] as bool,
          createdAt: row[12] as DateTime,
        );
      }).toList();
    } catch (e) {
      print('❌ Ошибка получения объявлений: $e');
      return [];
    }
  }

  // Получить объявления пользователя
  Future<List<PropertyModel>> getUserProperties(int userId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          SELECT id, user_id, title, description, location, price, area, rooms, floor, property_type, image_url, is_premium, created_at
          FROM properties
          WHERE user_id = @user_id
          ORDER BY created_at DESC
        ''',
        substitutionValues: {'user_id': userId},
      );

      return result.map((row) => PropertyModel(
        id: row[0] as int,
        userId: row[1] as int,
        title: row[2] as String,
        description: row[3] as String,
        location: row[4] as String,
        price: double.parse(row[5].toString()),
        area: double.parse(row[6].toString()),
        rooms: row[7] as int,
        floor: row[8] as String,
        propertyType: row[9] as String,
        imageUrl: row[10] as String?,
        isPremium: row[11] as bool,
        createdAt: row[12] as DateTime,
      )).toList();
    } catch (e) {
      print('❌ Ошибка получения объявлений пользователя: $e');
      return [];
    }
  }

  // Удалить объявление
  Future<bool> deleteProperty(int propertyId, int userId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      await _connection!.query(
        '''
          DELETE FROM properties
          WHERE id = @id AND user_id = @user_id
        ''',
        substitutionValues: {
          'id': propertyId,
          'user_id': userId,
        },
      );
      return true;
    } catch (e) {
      print('❌ Ошибка удаления объявления: $e');
      return false;
    }
  }

  // ========== МЕТОДЫ ДЛЯ ИЗБРАННОГО ==========

  // Добавить в избранное
  Future<bool> addToFavorites(int userId, int propertyId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      await _connection!.query(
        '''
          INSERT INTO favorites (user_id, property_id)
          VALUES (@user_id, @property_id)
          ON CONFLICT (user_id, property_id) DO NOTHING
        ''',
        substitutionValues: {
          'user_id': userId,
          'property_id': propertyId,
        },
      );
      return true;
    } catch (e) {
      print('❌ Ошибка добавления в избранное: $e');
      return false;
    }
  }

  // Удалить из избранного
  Future<bool> removeFromFavorites(int userId, int propertyId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      await _connection!.query(
        '''
          DELETE FROM favorites
          WHERE user_id = @user_id AND property_id = @property_id
        ''',
        substitutionValues: {
          'user_id': userId,
          'property_id': propertyId,
        },
      );
      return true;
    } catch (e) {
      print('❌ Ошибка удаления из избранного: $e');
      return false;
    }
  }

  // Проверить, в избранном ли объявление
  Future<bool> isFavorite(int userId, int propertyId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          SELECT COUNT(*) as count
          FROM favorites
          WHERE user_id = @user_id AND property_id = @property_id
        ''',
        substitutionValues: {
          'user_id': userId,
          'property_id': propertyId,
        },
      );

      return result.isNotEmpty && (result.first[0] as int) > 0;
    } catch (e) {
      print('❌ Ошибка проверки избранного: $e');
      return false;
    }
  }

  // Получить избранные объявления пользователя
  Future<List<PropertyModel>> getFavoriteProperties(int userId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          SELECT p.id, p.user_id, p.title, p.description, p.location, p.price, p.area, p.rooms, p.floor, p.property_type, p.image_url, p.is_premium, p.created_at
          FROM properties p
          INNER JOIN favorites f ON p.id = f.property_id
          WHERE f.user_id = @user_id
          ORDER BY f.created_at DESC
        ''',
        substitutionValues: {'user_id': userId},
      );

      return result.map((row) => PropertyModel(
        id: row[0] as int,
        userId: row[1] as int,
        title: row[2] as String,
        description: row[3] as String,
        location: row[4] as String,
        price: double.parse(row[5].toString()),
        area: double.parse(row[6].toString()),
        rooms: row[7] as int,
        floor: row[8] as String,
        propertyType: row[9] as String,
        imageUrl: row[10] as String?,
        isPremium: row[11] as bool,
        createdAt: row[12] as DateTime,
      )).toList();
    } catch (e) {
      print('❌ Ошибка получения избранного: $e');
      return [];
    }
  }

  // Получить ID избранных объявлений пользователя
  Future<Set<int>> getFavoriteIds(int userId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          SELECT property_id
          FROM favorites
          WHERE user_id = @user_id
        ''',
        substitutionValues: {'user_id': userId},
      );

      return result.map((row) => row[0] as int).toSet();
    } catch (e) {
      print('❌ Ошибка получения ID избранного: $e');
      return {};
    }
  }

  // ========== МЕТОДЫ ДЛЯ ЧАТА ==========

  // Отправить сообщение
  Future<bool> sendMessage(int senderId, int receiverId, String message) async {
    try {
      await _connection!.query(
        '''
          INSERT INTO messages (sender_id, receiver_id, message, created_at, is_read)
          VALUES (@sender_id, @receiver_id, @message, @created_at, false)
        ''',
        substitutionValues: {
          'sender_id': senderId,
          'receiver_id': receiverId,
          'message': message,
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      print('✅ Сообщение отправлено');
      return true;
    } catch (e) {
      print('❌ Ошибка отправки сообщения: $e');
      return false;
    }
  }

  // Получить сообщения между двумя пользователями
  Future<List<MessageModel>> getChatMessages(int userId, int otherUserId) async {
    try {
      final result = await _connection!.query(
        '''
          SELECT id, sender_id, receiver_id, message, created_at, is_read
          FROM messages
          WHERE (sender_id = @user_id AND receiver_id = @other_user_id)
             OR (sender_id = @other_user_id AND receiver_id = @user_id)
          ORDER BY created_at ASC
        ''',
        substitutionValues: {
          'user_id': userId,
          'other_user_id': otherUserId,
        },
      );

      return result.map((row) {
        final createdAt = row[4];
        return MessageModel(
          id: row[0] as int,
          senderId: row[1] as int,
          receiverId: row[2] as int,
          message: row[3] as String,
          createdAt: createdAt is DateTime ? createdAt : DateTime.parse(createdAt as String),
          isRead: row[5] as bool,
        );
      }).toList();
    } catch (e) {
      print('❌ Ошибка получения сообщений: $e');
      return [];
    }
  }

  // Пометить сообщения как прочитанные
  Future<void> markMessagesAsRead(int userId, int otherUserId) async {
    try {
      await _connection!.query(
        '''
          UPDATE messages
          SET is_read = true
          WHERE sender_id = @other_user_id AND receiver_id = @user_id AND is_read = false
        ''',
        substitutionValues: {
          'user_id': userId,
          'other_user_id': otherUserId,
        },
      );
    } catch (e) {
      print('❌ Ошибка пометки сообщений как прочитанных: $e');
    }
  }

  // Получить список чатов пользователя
  Future<List<Map<String, dynamic>>> getUserChats(int userId) async {
    try {
      final result = await _connection!.query(
        '''
          WITH chat_partners AS (
            SELECT DISTINCT
              CASE 
                WHEN sender_id = @user_id THEN receiver_id
                ELSE sender_id
              END as partner_id
            FROM messages
            WHERE sender_id = @user_id OR receiver_id = @user_id
          )
          SELECT 
            cp.partner_id as other_user_id,
            u.name as other_user_name,
            u.avatar_url as other_user_avatar,
            (SELECT message FROM messages 
             WHERE (sender_id = @user_id AND receiver_id = cp.partner_id)
                OR (sender_id = cp.partner_id AND receiver_id = @user_id)
             ORDER BY created_at DESC LIMIT 1) as last_message,
            (SELECT created_at FROM messages 
             WHERE (sender_id = @user_id AND receiver_id = cp.partner_id)
                OR (sender_id = cp.partner_id AND receiver_id = @user_id)
             ORDER BY created_at DESC LIMIT 1) as last_message_time,
            (SELECT COUNT(*) FROM messages 
             WHERE sender_id = cp.partner_id AND receiver_id = @user_id AND is_read = false) as unread_count
          FROM chat_partners cp
          JOIN users u ON u.id = cp.partner_id
          ORDER BY last_message_time DESC NULLS LAST
        ''',
        substitutionValues: {'user_id': userId},
      );

      return result.map((row) {
        final lastMessageTime = row[4];
        return {
          'other_user_id': row[0] as int,
          'other_user_name': row[1] as String,
          'other_user_avatar': row[2] as String?,
          'last_message': row[3] as String?,
          'last_message_time': lastMessageTime != null 
              ? (lastMessageTime is DateTime ? lastMessageTime : DateTime.parse(lastMessageTime as String))
              : null,
          'unread_count': row[5] as int,
        };
      }).toList();
    } catch (e) {
      print('❌ Ошибка получения списка чатов: $e');
      return [];
    }
  }

  // ========== МЕТОДЫ ДЛЯ ВОССТАНОВЛЕНИЯ ПАРОЛЯ ==========

  // Создать код восстановления
  Future<String?> createPasswordResetCode(String email) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      // Проверяем существование пользователя
      final userResult = await _connection!.query(
        'SELECT id FROM users WHERE email = @email',
        substitutionValues: {'email': email},
      );

      if (userResult.isEmpty) {
        return null;
      }

      final userId = userResult.first[0] as int;

      // Генерируем 6-значный код
      final code = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      final expiresAt = DateTime.now().add(const Duration(minutes: 15));

      await _connection!.query(
        '''
          INSERT INTO password_reset_codes (user_id, code, expires_at)
          VALUES (@user_id, @code, @expires_at)
        ''',
        substitutionValues: {
          'user_id': userId,
          'code': code,
          'expires_at': expiresAt.toIso8601String(),
        },
      );

      print('✅ Код восстановления создан: $code');
      return code;
    } catch (e) {
      print('❌ Ошибка создания кода восстановления: $e');
      return null;
    }
  }

  // Проверить код восстановления
  Future<int?> verifyPasswordResetCode(String email, String code) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        '''
          SELECT prc.id, prc.user_id, prc.expires_at, prc.is_used
          FROM password_reset_codes prc
          JOIN users u ON u.id = prc.user_id
          WHERE u.email = @email AND prc.code = @code
          ORDER BY prc.created_at DESC
          LIMIT 1
        ''',
        substitutionValues: {
          'email': email,
          'code': code,
        },
      );

      if (result.isEmpty) {
        print('❌ Код не найден');
        return null;
      }

      final row = result.first;
      final codeId = row[0] as int;
      final userId = row[1] as int;
      final expiresAt = row[2] is DateTime ? row[2] as DateTime : DateTime.parse(row[2] as String);
      final isUsed = row[3] as bool;

      if (isUsed) {
        print('❌ Код уже использован');
        return null;
      }

      if (DateTime.now().isAfter(expiresAt)) {
        print('❌ Код истек');
        return null;
      }

      // Помечаем код как использованный
      await _connection!.query(
        'UPDATE password_reset_codes SET is_used = true WHERE id = @id',
        substitutionValues: {'id': codeId},
      );

      print('✅ Код верифицирован');
      return userId;
    } catch (e) {
      print('❌ Ошибка верификации кода: $e');
      return null;
    }
  }

  // Сбросить пароль
  Future<bool> resetPassword(int userId, String newPassword) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final passwordHash = _hashPassword(newPassword);

      await _connection!.query(
        'UPDATE users SET password_hash = @password_hash WHERE id = @id',
        substitutionValues: {
          'id': userId,
          'password_hash': passwordHash,
        },
      );

      print('✅ Пароль сброшен');
      return true;
    } catch (e) {
      print('❌ Ошибка сброса пароля: $e');
      return false;
    }
  }

  // Получить email пользователя по ID
  Future<String?> getUserEmail(int userId) async {
    try {
      if (_connection == null || _connection!.isClosed) {
        await connect();
      }

      final result = await _connection!.query(
        'SELECT email FROM users WHERE id = @id',
        substitutionValues: {'id': userId},
      );

      if (result.isNotEmpty) {
        return result.first[0] as String;
      }
      return null;
    } catch (e) {
      print('❌ Ошибка получения email: $e');
      return null;
    }
  }

  // ========== МЕТОДЫ ДЛЯ КОРЗИНЫ ==========

  Future<Map<int, int>> getCartItems(int userId) async {
    try {
      if (!await _ensureConnection()) return {};
      final result = await _connection!.query(
        'SELECT product_id, qty FROM cart_items WHERE user_id = @uid',
        substitutionValues: {'uid': userId},
      );
      return {
        for (final r in result) (r[0] as int): (r[1] as int),
      };
    } catch (e) {
      print('❌ Ошибка получения корзины: $e');
      return {};
    }
  }

  Future<bool> upsertCartItem(int userId, int productId, int qty) async {
    try {
      if (!await _ensureConnection()) return false;
      if (qty <= 0) return removeCartItem(userId, productId);
      await _connection!.query(
        '''
          INSERT INTO cart_items (user_id, product_id, qty, updated_at)
          VALUES (@uid, @pid, @qty, CURRENT_TIMESTAMP)
          ON CONFLICT (user_id, product_id)
          DO UPDATE SET qty = EXCLUDED.qty, updated_at = CURRENT_TIMESTAMP
        ''',
        substitutionValues: {'uid': userId, 'pid': productId, 'qty': qty},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка сохранения позиции корзины: $e');
      return false;
    }
  }

  Future<bool> removeCartItem(int userId, int productId) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        'DELETE FROM cart_items WHERE user_id = @uid AND product_id = @pid',
        substitutionValues: {'uid': userId, 'pid': productId},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка удаления позиции корзины: $e');
      return false;
    }
  }

  Future<bool> clearCart(int userId) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        'DELETE FROM cart_items WHERE user_id = @uid',
        substitutionValues: {'uid': userId},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка очистки корзины: $e');
      return false;
    }
  }

  // ========== МЕТОДЫ ДЛЯ УВЕДОМЛЕНИЙ ==========

  Future<List<Map<String, dynamic>>> getInbox(int userId) async {
    try {
      if (!await _ensureConnection()) return [];
      final result = await _connection!.query(
        '''
          SELECT ext_id, type, title, body, is_read, created_at
          FROM inbox_notifications
          WHERE user_id = @uid
          ORDER BY created_at DESC
        ''',
        substitutionValues: {'uid': userId},
      );
      return result.map((r) {
        final created = r[5];
        return {
          'ext_id': r[0] as String,
          'type': r[1] as String,
          'title': r[2] as String,
          'body': r[3] as String,
          'is_read': r[4] as bool,
          'created_at': created is DateTime ? created : DateTime.parse(created as String),
        };
      }).toList();
    } catch (e) {
      print('❌ Ошибка получения inbox: $e');
      return [];
    }
  }

  Future<bool> upsertInbox({
    required int userId,
    required String extId,
    required String type,
    required String title,
    required String body,
    bool isRead = false,
    DateTime? createdAt,
  }) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        '''
          INSERT INTO inbox_notifications (user_id, ext_id, type, title, body, is_read, created_at)
          VALUES (@uid, @ext, @type, @title, @body, @read, COALESCE(@ts, CURRENT_TIMESTAMP))
          ON CONFLICT (user_id, ext_id)
          DO UPDATE SET title = EXCLUDED.title, body = EXCLUDED.body, type = EXCLUDED.type
        ''',
        substitutionValues: {
          'uid': userId,
          'ext': extId,
          'type': type,
          'title': title,
          'body': body,
          'read': isRead,
          'ts': createdAt?.toIso8601String(),
        },
      );
      return true;
    } catch (e) {
      print('❌ Ошибка записи уведомления: $e');
      return false;
    }
  }

  Future<bool> markInboxAllRead(int userId) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        'UPDATE inbox_notifications SET is_read = TRUE WHERE user_id = @uid AND is_read = FALSE',
        substitutionValues: {'uid': userId},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка пометки как прочитанные: $e');
      return false;
    }
  }

  Future<bool> markInboxRead(int userId, String extId) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        '''
          UPDATE inbox_notifications SET is_read = TRUE
          WHERE user_id = @uid AND ext_id = @ext
        ''',
        substitutionValues: {'uid': userId, 'ext': extId},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка пометки как прочитано: $e');
      return false;
    }
  }

  Future<bool> clearInbox(int userId) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        'DELETE FROM inbox_notifications WHERE user_id = @uid',
        substitutionValues: {'uid': userId},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка очистки inbox: $e');
      return false;
    }
  }

  // ========== МЕТОДЫ ДЛЯ ЗАКАЗОВ ==========

  Future<List<Map<String, dynamic>>> getOrders(int userId) async {
    try {
      if (!await _ensureConnection()) return [];
      final orders = await _connection!.query(
        '''
          SELECT id, ext_id, status, subtotal, delivery_fee, total,
                 address, phone, payment_method, delivery_method,
                 created_at, expected_at
          FROM orders
          WHERE user_id = @uid
          ORDER BY created_at DESC
        ''',
        substitutionValues: {'uid': userId},
      );

      final result = <Map<String, dynamic>>[];
      for (final row in orders) {
        final orderId = row[0] as int;
        final items = await _connection!.query(
          '''
            SELECT product_id, title, brand, image_url, price, qty
            FROM order_items WHERE order_id = @oid
          ''',
          substitutionValues: {'oid': orderId},
        );
        result.add({
          'ext_id': row[1] as String,
          'status': row[2] as String,
          'subtotal': double.parse(row[3].toString()),
          'delivery_fee': double.parse(row[4].toString()),
          'total': double.parse(row[5].toString()),
          'address': row[6] as String? ?? '',
          'phone': row[7] as String? ?? '',
          'payment_method': row[8] as String? ?? '',
          'delivery_method': row[9] as String? ?? '',
          'created_at': row[10] is DateTime ? row[10] : DateTime.parse(row[10] as String),
          'expected_at': row[11] is DateTime ? row[11] : DateTime.parse(row[11] as String),
          'items': items
              .map((r) => {
                    'product_id': r[0] as int,
                    'title': r[1] as String,
                    'brand': r[2] as String? ?? '',
                    'image_url': r[3] as String?,
                    'price': double.parse(r[4].toString()),
                    'qty': r[5] as int,
                  })
              .toList(),
        });
      }
      return result;
    } catch (e) {
      print('❌ Ошибка получения заказов: $e');
      return [];
    }
  }

  Future<bool> insertOrder({
    required int userId,
    required String extId,
    required String status,
    required double subtotal,
    required double deliveryFee,
    required double total,
    required String address,
    required String phone,
    required String paymentMethod,
    required String deliveryMethod,
    required DateTime createdAt,
    required DateTime expectedAt,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      if (!await _ensureConnection()) return false;

      final inserted = await _connection!.query(
        '''
          INSERT INTO orders (
            user_id, ext_id, status, subtotal, delivery_fee, total,
            address, phone, payment_method, delivery_method, created_at, expected_at
          )
          VALUES (
            @uid, @ext, @status, @subtotal, @df, @total,
            @addr, @phone, @pay, @del, @ts, @exp
          )
          ON CONFLICT (user_id, ext_id) DO NOTHING
          RETURNING id
        ''',
        substitutionValues: {
          'uid': userId,
          'ext': extId,
          'status': status,
          'subtotal': subtotal,
          'df': deliveryFee,
          'total': total,
          'addr': address,
          'phone': phone,
          'pay': paymentMethod,
          'del': deliveryMethod,
          'ts': createdAt.toIso8601String(),
          'exp': expectedAt.toIso8601String(),
        },
      );

      if (inserted.isEmpty) return true; // уже существовал
      final orderId = inserted.first[0] as int;

      for (final it in items) {
        await _connection!.query(
          '''
            INSERT INTO order_items (order_id, product_id, title, brand, image_url, price, qty)
            VALUES (@oid, @pid, @title, @brand, @img, @price, @qty)
          ''',
          substitutionValues: {
            'oid': orderId,
            'pid': it['product_id'],
            'title': it['title'],
            'brand': it['brand'],
            'img': it['image_url'],
            'price': it['price'],
            'qty': it['qty'],
          },
        );
      }
      return true;
    } catch (e) {
      print('❌ Ошибка вставки заказа: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(int userId, String extId, String status) async {
    try {
      if (!await _ensureConnection()) return false;
      await _connection!.query(
        'UPDATE orders SET status = @st WHERE user_id = @uid AND ext_id = @ext',
        substitutionValues: {'uid': userId, 'ext': extId, 'st': status},
      );
      return true;
    } catch (e) {
      print('❌ Ошибка обновления статуса заказа: $e');
      return false;
    }
  }
}
