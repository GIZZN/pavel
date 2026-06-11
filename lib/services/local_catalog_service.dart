import '../models/property_model.dart';

/// Локальное хранилище товаров. Полностью заменяет получение из БД.
/// Использует поле `propertyType` модели для категории, `location` — для бренда.
class LocalCatalogService {
  LocalCatalogService._();
  static final LocalCatalogService instance = LocalCatalogService._();

  // Маппинг публичных категорий на propertyType
  static const String catPhones = 'phones';
  static const String catLaptops = 'laptops';
  static const String catTablets = 'tablets';
  static const String catAudio = 'audio';
  static const String catWatches = 'watches';
  static const String catCameras = 'cameras';
  static const String catConsoles = 'consoles';

  static const List<String> allCategories = [
    catPhones, catLaptops, catTablets, catAudio, catWatches, catCameras, catConsoles,
  ];

  List<PropertyModel>? _cache;

  Future<List<PropertyModel>> getAll() async {
    _cache ??= _seed();
    return List<PropertyModel>.unmodifiable(_cache!);
  }

  PropertyModel? getById(int id) {
    if (_cache == null) return null;
    try {
      return _cache!.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  // ===== Сидер каталога =====
  List<PropertyModel> _seed() {
    final now = DateTime.now();
    int idGen = 1;
    PropertyModel make({
      required String type,
      required String brand,
      required String title,
      required String desc,
      required double price,
      required String image,
      bool premium = false,
      int daysAgo = 0,
    }) {
      return PropertyModel(
        id: idGen++,
        userId: 0,
        title: title,
        description: desc,
        location: brand,
        price: price,
        area: 0,
        rooms: 0,
        floor: '',
        propertyType: type,
        imageUrl: image,
        isPremium: premium,
        createdAt: now.subtract(Duration(days: daysAgo)),
      );
    }

    // Параметры для оптимизации: ширина 600, формат webp/jpeg, обрезка по центру
    String img(String id) =>
        'https://images.unsplash.com/photo-$id?w=600&q=80&auto=format&fit=crop';

    return <PropertyModel>[
      // Смартфоны
      make(type: catPhones, brand: 'Apple', title: 'iPhone 15 Pro 256GB',
          desc: 'Титановый корпус, чип A17 Pro, продвинутая камера 48 Мп.',
          price: 119990, premium: true, daysAgo: 1,
          image: img('1592750475338-74b7b21085ab')),
      make(type: catPhones, brand: 'Apple', title: 'iPhone 15 128GB',
          desc: 'USB-C, Dynamic Island, цвет Pink.', price: 79990, daysAgo: 3,
          image: img('1695048133142-1a20484d2569')),
      make(type: catPhones, brand: 'Samsung', title: 'Galaxy S24 Ultra',
          desc: 'S Pen, экран 6.8" QHD+, чип Snapdragon 8 Gen 3.',
          price: 134990, premium: true, daysAgo: 2,
          image: img('1610945415295-d9bbf067e59c')),
      make(type: catPhones, brand: 'Xiaomi', title: 'Xiaomi 14 Pro',
          desc: 'Камера Leica, экран LTPO 120 Гц, 50 Мп.', price: 84990, daysAgo: 5,
          image: img('1598327105666-5b89351aff97')),
      make(type: catPhones, brand: 'Google', title: 'Pixel 8 Pro 256GB',
          desc: 'Tensor G3, чистый Android, лучшая обработка фото.',
          price: 89990, daysAgo: 7,
          image: img('1598327105666-5b89351aff97')),

      // Ноутбуки
      make(type: catLaptops, brand: 'Apple', title: 'MacBook Air 13" M3 8/256',
          desc: 'Чип Apple M3, до 18 ч автономности, цвет Midnight.',
          price: 119990, premium: true, daysAgo: 1,
          image: img('1517336714731-489689fd1ca8')),
      make(type: catLaptops, brand: 'Apple', title: 'MacBook Pro 14" M3 Pro',
          desc: 'Liquid Retina XDR, 18 ГБ, 512 ГБ SSD.',
          price: 219990, premium: true, daysAgo: 4,
          image: img('1611186871348-b1ce696e52c9')),
      make(type: catLaptops, brand: 'Asus', title: 'ROG Zephyrus G14',
          desc: 'Ryzen 9, RTX 4060, 16/1024, OLED 165 Гц.',
          price: 179990, daysAgo: 6,
          image: img('1593642632559-0c6d3fc62b89')),
      make(type: catLaptops, brand: 'Lenovo', title: 'ThinkPad X1 Carbon Gen 11',
          desc: 'Intel Core i7-1365U, 16 ГБ, 1 ТБ, 14".',
          price: 159990, daysAgo: 10,
          image: img('1496181133206-80ce9b88a853')),
      make(type: catLaptops, brand: 'Dell', title: 'XPS 15 9530',
          desc: 'Core i7, RTX 4050, OLED 3.5K, 16/512.',
          price: 169990, daysAgo: 12,
          image: img('1588872657578-7efd1f1555ed')),

      // Планшеты
      make(type: catTablets, brand: 'Apple', title: 'iPad Pro 11" M4 256GB',
          desc: 'Tandem OLED, чип M4, поддержка Apple Pencil Pro.',
          price: 99990, premium: true, daysAgo: 0,
          image: img('1561154464-82e9adf32764')),
      make(type: catTablets, brand: 'Apple', title: 'iPad Air 11" M2',
          desc: 'Liquid Retina, чип M2, Wi-Fi, 128 ГБ.',
          price: 64990, daysAgo: 3,
          image: img('1544244015-0df4b3ffc6b0')),
      make(type: catTablets, brand: 'Samsung', title: 'Galaxy Tab S9+',
          desc: '12.4" AMOLED 120 Гц, S Pen в комплекте.',
          price: 79990, daysAgo: 8,
          image: img('1565130838609-c3a86655db61')),
      make(type: catTablets, brand: 'Xiaomi', title: 'Pad 6 Pro 8/256',
          desc: '11" 144 Гц, Snapdragon 8+ Gen 1.',
          price: 39990, daysAgo: 14,
          image: img('1623126908029-58cb08a2b272')),

      // Аудио
      make(type: catAudio, brand: 'Apple', title: 'AirPods Pro 2 USB-C',
          desc: 'Активное шумоподавление, режим Adaptive Audio.',
          price: 24990, premium: true, daysAgo: 2,
          image: img('1606220588913-b3aacb4d2f46')),
      make(type: catAudio, brand: 'Sony', title: 'WH-1000XM5',
          desc: 'Лучшее в классе шумоподавление, 30 ч работы.',
          price: 32990, daysAgo: 5,
          image: img('1583394838336-acd977736f90')),
      make(type: catAudio, brand: 'Bose', title: 'QuietComfort Ultra',
          desc: 'Иммерсивный звук, премиум посадка.',
          price: 36990, daysAgo: 9,
          image: img('1546435770-a3e426bf472b')),
      make(type: catAudio, brand: 'JBL', title: 'JBL Tour Pro 2',
          desc: 'TWS с экраном на кейсе, до 40 ч с кейсом.',
          price: 18990, daysAgo: 11,
          image: img('1590658268037-6bf12165a8df')),
      make(type: catAudio, brand: 'Marshall', title: 'Marshall Stanmore III',
          desc: 'Акустика 80 Вт, Bluetooth 5.2, классический дизайн.',
          price: 39990, daysAgo: 15,
          image: img('1545454675-3531b543be5d')),

      // Часы
      make(type: catWatches, brand: 'Apple', title: 'Apple Watch Series 9 45mm',
          desc: 'Чип S9, жест Double Tap, экран 2000 нит.',
          price: 39990, premium: true, daysAgo: 1,
          image: img('1551816230-ef5deaed4a26')),
      make(type: catWatches, brand: 'Apple', title: 'Apple Watch Ultra 2',
          desc: 'Титан 49 мм, до 36 ч автономности.',
          price: 89990, premium: true, daysAgo: 4,
          image: img('1579586337278-3befd40fd17a')),
      make(type: catWatches, brand: 'Garmin', title: 'Garmin Fenix 7 Pro',
          desc: 'Мультиспортивные часы с GPS и солнечной зарядкой.',
          price: 79990, daysAgo: 8,
          image: img('1523275335684-37898b6baf30')),
      make(type: catWatches, brand: 'Samsung', title: 'Galaxy Watch 6 Classic',
          desc: '47 мм, поворотный безель, Wear OS.',
          price: 32990, daysAgo: 12,
          image: img('1546868871-7041f2a55e12')),

      // Камеры
      make(type: catCameras, brand: 'Sony', title: 'Sony Alpha A7 IV',
          desc: 'Полный кадр 33 Мп, 4K 60p, IBIS 5.5 stops.',
          price: 229990, premium: true, daysAgo: 3,
          image: img('1502920917128-1aa500764cbd')),
      make(type: catCameras, brand: 'Canon', title: 'Canon EOS R6 Mark II',
          desc: 'Полный кадр 24 Мп, серийная съёмка 40 к/с.',
          price: 219990, daysAgo: 6,
          image: img('1542038784456-1ea8e935640e')),
      make(type: catCameras, brand: 'Fujifilm', title: 'Fujifilm X-T5',
          desc: 'APS-C 40 Мп, плёночные симуляции, 6.2K видео.',
          price: 179990, daysAgo: 10,
          image: img('1495707902641-75cac588d2e9')),
      make(type: catCameras, brand: 'GoPro', title: 'GoPro HERO 12 Black',
          desc: '5.3K 60p, HyperSmooth 6.0, защита до 10 м.',
          price: 49990, daysAgo: 13,
          image: img('1525385133512-2f3bdd039054')),

      // Игровые консоли
      make(type: catConsoles, brand: 'Sony', title: 'PlayStation 5 Slim',
          desc: 'Дисковая версия, 1 ТБ SSD, 4K HDR гейминг.',
          price: 64990, premium: true, daysAgo: 0,
          image: img('1606813907291-d86efa9b94db')),
      make(type: catConsoles, brand: 'Microsoft', title: 'Xbox Series X 1TB',
          desc: '4K 120 Гц, Quick Resume, Game Pass.',
          price: 59990, daysAgo: 5,
          image: img('1621259182978-fbf93132d53d')),
      make(type: catConsoles, brand: 'Nintendo', title: 'Nintendo Switch OLED',
          desc: 'Экран OLED 7", улучшенный звук, 64 ГБ.',
          price: 29990, daysAgo: 9,
          image: img('1612036782180-6f0b6cd846fe')),
      make(type: catConsoles, brand: 'Valve', title: 'Steam Deck OLED 1TB',
          desc: 'Портативный ПК для игр Steam, OLED HDR.',
          price: 79990, daysAgo: 14,
          image: img('1640955014216-75201056c829')),
    ];
  }
}

