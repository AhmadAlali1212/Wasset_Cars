import '../models/ad_model.dart';
import '../models/auction_model.dart';
import '../models/car_model.dart';
import '../models/workshop_model.dart';

class MockData {
  static List<Ad> get featuredAds {
    return [
      Ad(
        id: 1,
        carId: 1,
        userId: 1,
        price: "25,000,000",
        status: "pending",
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 1,
          userId: 1,
          make: "Toyota",
          userName: 'يمان النوفل',
          model: "Camry",
          year: 2020,
          condition: "used",
          description: "سيارة بحالة ممتازة، صيانة دورية، مكيف بارد، فرش جلد، عداد 80,000 كم فقط. لا تحتاج لأي صيانة.",
          location: "دمشق - المزة",
          images: [
            "https://images.unsplash.com/photo-1542362567-b07e54358753",
            "https://images.unsplash.com/photo-1542362567-b07e54358753",
            "https://images.unsplash.com/photo-1542362567-b07e54358753",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
      ),
      Ad(
        id: 2,
        carId: 2,
        userId: 2,
        price: "35,500,000",
        status: "approved",
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 2,
          userId: 2,
          userName: 'يمان النوفل',
          make: "Hyundai",
          model: "Tucson",
          year: 2021,
          condition: "used",
          description: "سيارة دفع رباعي، موديل حديث، فتحة سقف، شاشة لمس، كاميرا خلفية، نظام ملاحة.",
          location: "حلب - الشهباء",
          images: [
            "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7",
            "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7",
            "https://images.unsplash.com/photo-1568605117036-5fe5e7bab0b7",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
      ),
    ];
  }

  static List<Ad> get recommendedAds {
    return [
      Ad(
        id: 3,
        carId: 3,
        userId: 3,
        price: "18,500,000",
        status: "approved",
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 3,
          userId: 3,
          userName: 'يمان النوفل',
          make: "Kia",
          model: "Picanto",
          year: 2019,
          condition: "used",
          description: "سيارة اقتصادية، استهلاك وقود منخفض، مثالية للمدينة.",
          location: "دمشق - كفرسوسة",
          images: [
            "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2",
            "https://images.unsplash.com/photo-1549317661-bd32c8ce0db2",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
      ),
      Ad(
        id: 4,
        carId: 4,
        userId: 4,
        price: "42,000,000",
        status: "approved",
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 4,
          userName: 'يمان النوفل',
          userId: 4,
          make: "Mercedes",
          model: "C200",
          year: 2018,
          condition: "used",
          description: "فئة C موديل 2018، فخامة وأداء عالي، صيانة وكالة.",
          location: "اللاذقية - المدينة",
          images: [
            "https://images.unsplash.com/photo-1553440569-bcc63803a83d",
            "https://images.unsplash.com/photo-1553440569-bcc63803a83d",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
      ),
      Ad(
        id: 5,
        carId: 5,
        userId: 5,
        price: "15,750,000",
        status: "pending",
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 5,
          userId: 5,
          userName: 'يمان النوفل',
          make: "Nissan",
          model: "Sunny",
          year: 2017,
          condition: "used",
          description: "سيارة عائلية، مريحة، استهلاك وقود اقتصادي.",
          location: "حمص - الحميدية",
          images: [
            "https://images.unsplash.com/photo-1550355291-bbee04a92027",
            "https://images.unsplash.com/photo-1550355291-bbee04a92027",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
      ),
    ];
  }

  static List<Car> getCarsForRental() {
    return [
      Car(
        id: 21,
        userId: 4,
        make: "Hyundai",
        model: "Elantra",
        year: 2022,
        condition: "new",
        description: "سيارة حديثة ومريحة للإيجار.",
        location: "حلب",
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), userName: 'يمان النوفل',
      ),
      Car(
        id: 22,
        userId: 4,
        make: "Toyota",
        model: "Camry",
        year: 2021,
        condition: "used",
        description: "سيارة فاخرة للإيجار.",
        location: "دمشق",
        images: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(), userName: 'يمان النوفل',
      ),
    ];
  }

  static List<Ad> get rentalAds {
    return [
      Ad(
        id: 6,
        carId: 6,
        userId: 6,
        price: "",
        status: "approved",
        isFeatured: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 6,
          userId: 6,
          userName: 'يمان النوفل',
          make: "Hyundai",
          model: "Elantra",
          year: 2022,
          condition: "new",
          description: "سيارة حديثة ومريحة للإيجار اليومي والشهري.",
          location: "دمشق",
          images: [
            "https://images.unsplash.com/photo-1623018035782-5d454d3a2e5a",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
        dailyPrice: "50,000",
        monthlyPrice: "1,200,000",
        rentalConditions: "رخصة قيادة سارية، تأمين شامل، دفعة أولى 20%",
        location: "دمشق - المزة",
      ),
      Ad(
        id: 7,
        carId: 7,
        userId: 7,
        price: "",
        status: "approved",
        isFeatured: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        car: Car(
          id: 7,
          userId: 7,
          userName: 'يمان النوفل',
          make: "Kia",
          model: "Sportage",
          year: 2021,
          condition: "used",
          description: "سيارة دفع رباعي مريحة للإيجار الطويل.",
          location: "حلب",
          images: [
            "https://images.unsplash.com/photo-1617814076367-b759c7d7e738",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        auctions: [],
        dailyPrice: "70,000",
        monthlyPrice: "1,800,000",
        rentalConditions: "رخصة قيادة سارية، تأمين شامل، دفعة أولى 30%",
        location: "حلب - الشهباء",
      ),
    ];
  }

  static List<Auction> get auctions {
    return [
      Auction(
        id: 1,
        adId: 1,
        startingPrice: "30,000,000",
        currentPrice: "32,500,000",
        startTime: DateTime.now().subtract(const Duration(days: 2)),
        endTime: DateTime.now().add(const Duration(days: 3)),
        status: "active",
        bids: [
          Bid(
            userId: 1,
            amount: "31,000,000",
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          Bid(
            userId: 2,
            amount: "32,500,000",
            createdAt: DateTime.now(),
          ),
        ],
        car: Car(
          id: 1,
          userId: 1,
          userName: 'يمان النوفل',
          make: "BMW",
          model: "X5",
          year: 2020,
          condition: "used",
          description: "سيارة فاخرة للبيع بالمزاد العلني",
          location: "دمشق",
          images: [
            "https://images.unsplash.com/photo-1580273916550-e323be2ae537",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
      Auction(
        id: 2,
        adId: 2,
        startingPrice: "15,000,000",
        currentPrice: "16,750,000",
        startTime: DateTime.now().subtract(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(hours: 12)),
        status: "active",
        bids: [
          Bid(
            userId: 3,
            amount: "15,500,000",
            createdAt: DateTime.now().subtract(const Duration(hours: 10)),
          ),
          Bid(
            userId: 4,
            amount: "16,000,000",
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          Bid(
            userId: 5,
            amount: "16,750,000",
            createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ],
        car: Car(
          id: 2,
          userId: 2,
          userName: 'يمان النوفل',
          make: "Mercedes",
          model: "E200",
          year: 2017,
          condition: "used",
          description: "سيارة فخمة للبيع بالمزاد",
          location: "حلب",
          images: [
            "https://images.unsplash.com/photo-1563720223880-2d85e3e3d899",
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    ];
  }

  // دالة لاختبار التحويل من وإلى JSON
  static void testJsonConversion() {
    print("=== Testing JSON Conversion ===");

    // اختبار تحويل Ad إلى JSON ثم العودة
    Ad originalAd = featuredAds.first;
    Map<String, dynamic> jsonData = originalAd.toJson();
    Ad convertedAd = Ad.fromJson(jsonData);

    print("Original Ad: ${originalAd.car.make} ${originalAd.car.model}");
    print("Converted Ad: ${convertedAd.car.make} ${convertedAd.car.model}");
    print("Is Equal: ${originalAd.id == convertedAd.id}");

    // اختبار تحويل Auction إلى JSON ثم العودة
    Auction originalAuction = auctions.first;
    Map<String, dynamic> auctionJson = originalAuction.toJson();
    Auction convertedAuction = Auction.fromJson(auctionJson);

    print("\nOriginal Auction: ${originalAuction.car.make} ${originalAuction.car.model}");
    print("Converted Auction: ${convertedAuction.car.make} ${convertedAuction.car.model}");
    print("Bids Count: ${originalAuction.bids.length} vs ${convertedAuction.bids.length}");
  }
  // إضافة إلى ملف mock_data.dart

  static List<Workshop> get workshops {
    return [
      Workshop(
        id: 1,
        userId: 1,
        name: "ورشة النوفل للسيارات",
        description: "ورشة متخصصة في صيانة السيارات الألمانية واليابانية، لدينا فريق فني مؤهل وقطع غيار أصلية.",
        location: "دمشق - المزة",
        services: [
          "صيانة ميكانيكية",
          "كهرباء سيارات",
          "دهان وتصليح هياكل",
          "فك وتركيب زجاج"
        ],
        images: [
          "https://images.unsplash.com/photo-1600861195091-690c92f1d2cc",
          "https://images.unsplash.com/photo-1584735422188-3599b444a0b5"
        ],
        createdAt: DateTime.now().subtract(Duration(days: 30)),
        updatedAt: DateTime.now(),
        featured: true,
      ),
      Workshop(
        id: 2,
        userId: 2,
        name: "مركز الشهباء للخدمات السريعة",
        description: "خدمات سريعة وجودة عالية في تصليح جميع أعطال السيارات، صيانة دورية وتغيير زيت.",
        location: "حلب - الشهباء",
        services: [
          "صيانة دورية",
          "تغيير زيت وفلاتر",
          "توضيب محركات",
          "تصليح أنظمة التبريد"
        ],
        images: [
          "https://images.unsplash.com/photo-1492144534655-ae79c964c9d7",
          "https://images.unsplash.com/photo-1502877338535-766e1452684a"
        ],
        createdAt: DateTime.now().subtract(Duration(days: 15)),
        updatedAt: DateTime.now(),
        featured: true,
      ),
      Workshop(
        id: 3,
        userId: 3,
        name: "ورشة الفرات للكهرباء",
        description: "متخصصون في أعطال كهرباء السيارات وأنظمة التحكم الإلكترونية، تصليح كمبيوتر السيارات.",
        location: "دير الزور - الجورة",
        services: [
          "تصليح أنظمة الكهرباء",
          "برمجة مفاتيح",
          "إصلاح أنظمة التحكم",
          "صيانة أنظمة التكييف"
        ],
        images: [
          "https://images.unsplash.com/photo-1494972308805-463bc619d34e",
          "https://images.unsplash.com/photo-1504215680853-026ed2a45def"
        ],
        createdAt: DateTime.now().subtract(Duration(days: 7)),
        updatedAt: DateTime.now(),
        featured: false,
      ),
      Workshop(
        id: 4,
        userId: 4,
        name: "مركز اللاذقية للدهان",
        description: "أحدث تقنيات الدهان وتصليح الهياكل، ضمان على العمل، ألوان متعددة وخدمة سريعة.",
        location: "اللاذقية - شارع 8 آذار",
        services: [
          "دهان كامل",
          "تصليح هياكل",
          "تلميع سيارات",
          "إصلاح خدوش"
        ],
        images: [
          "https://images.unsplash.com/photo-1557223562-6c77ef16210f",
          "https://images.unsplash.com/photo-1503376780353-7e6692767b70"
        ],
        createdAt: DateTime.now().subtract(Duration(days: 3)),
        updatedAt: DateTime.now(),
        featured: false,
      ),
      Workshop(
        id: 5,
        userId: 5,
        name: "ورشة حمص للمحركات",
        description: "متخصصون في توضيب المحركات وإصلاح علب السرعة، ضمان على العمل، أسعار مناسبة.",
        location: "حمص - باب تدمر",
        services: [
          "توضيب محركات",
          "إصلاح علب سرعة",
          "صيانة دفرنسات",
          "إصلاح أنظمة العادم"
        ],
        images: [
          "https://images.unsplash.com/photo-1541899481282-d53bffe3c35d",
          "https://images.unsplash.com/photo-1492144534655-ae79c964c9d7"
        ],
        createdAt: DateTime.now().subtract(Duration(days: 1)),
        updatedAt: DateTime.now(),
        featured: true,
      ),
    ];
  }

// إضافة إلى قسم الاختبارات
  static void testWorkshopJsonConversion() {
    print("\n=== Testing Workshop JSON Conversion ===");

    Workshop originalWorkshop = workshops.first;
    Map<String, dynamic> jsonData = originalWorkshop.toJson();
    Workshop convertedWorkshop = Workshop.fromJson(jsonData);

    print("Original Workshop: ${originalWorkshop.name}");
    print("Converted Workshop: ${convertedWorkshop.name}");
    print("Services Count: ${originalWorkshop.services
        .length} vs ${convertedWorkshop.services.length}");
    print(
        "Images Count: ${originalWorkshop.images.length} vs ${convertedWorkshop
            .images.length}");
  } }