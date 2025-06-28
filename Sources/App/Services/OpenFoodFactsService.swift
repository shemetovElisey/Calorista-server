import Vapor
import AsyncHTTPClient
import NIOCore

// Сервис для работы с Open Food Facts API
struct OpenFoodFactsService {
    private let baseURL = "https://world.openfoodfacts.org/api/v2"
    private let searchURL = "https://world.openfoodfacts.org/cgi/search.pl"
    
    // Rate limiting: 100 req/min для продуктов, 10 req/min для поиска
    private var lastProductRequest: Date = Date().addingTimeInterval(-60)
    private var lastSearchRequest: Date = Date().addingTimeInterval(-60)
    private var productRequestCount = 0
    private var searchRequestCount = 0
    
    // Получить продукт по штрих-коду
    mutating func getProduct(by barcode: String, on req: Request) async throws -> Product? {
        try await checkProductRateLimit()
        let url = "\(baseURL)/product/\(barcode).json"
        guard let requestURL = URL(string: url) else {
            throw Abort(.badRequest, reason: "Invalid URL")
        }
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(req.eventLoop))
        defer { Task { try? await httpClient.shutdown() } }
        let response = try await httpClient.get(url: requestURL.absoluteString).get()
        guard response.status == .ok, var body = response.body else {
            return nil
        }
        let data = body.readData(length: body.readableBytes) ?? Data()
        let decoder = JSONDecoder()
        let offResponse = try decoder.decode(OpenFoodFactsResponse.self, from: data)
        guard offResponse.status == 1, let product = offResponse.product else {
            return nil
        }
        return Product(
            barcode: barcode,
            name: product.productName ?? product.genericName ?? "Unknown Product",
            brand: product.brands,
            caloriesPer100g: product.nutriments?.energyKcal100g,
            proteinPer100g: product.nutriments?.proteins100g,
            fatPer100g: product.nutriments?.fat100g,
            carbohydratesPer100g: product.nutriments?.carbohydrates100g,
            category: product.categories,
            imageUrl: product.imageUrl
        )
    }
    
    // Поиск продуктов по названию
    mutating func searchProducts(query: String, on req: Request) async throws -> [Product] {
        try await checkSearchRateLimit()
        var components = URLComponents(string: searchURL)!
        components.queryItems = [
            URLQueryItem(name: "search_terms", value: query),
            URLQueryItem(name: "search_simple", value: "1"),
            URLQueryItem(name: "action", value: "process"),
            URLQueryItem(name: "json", value: "1"),
            URLQueryItem(name: "page_size", value: "20")
        ]
        guard let url = components.url else {
            throw Abort(.badRequest, reason: "Invalid URL")
        }
        let httpClient = HTTPClient(eventLoopGroupProvider: .shared(req.eventLoop))
        defer { Task { try? await httpClient.shutdown() } }
        let response = try await httpClient.get(url: url.absoluteString).get()
        guard response.status == .ok, var body = response.body else {
            return []
        }
        let data = body.readData(length: body.readableBytes) ?? Data()
        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(OpenFoodFactsSearchResponse.self, from: data)
        return searchResponse.products.map { offProduct in
            Product(
                barcode: offProduct.code ?? "",
                name: offProduct.productName ?? offProduct.genericName ?? "Unknown Product",
                brand: offProduct.brands,
                caloriesPer100g: offProduct.nutriments?.energyKcal100g,
                proteinPer100g: offProduct.nutriments?.proteins100g,
                fatPer100g: offProduct.nutriments?.fat100g,
                carbohydratesPer100g: offProduct.nutriments?.carbohydrates100g,
                category: offProduct.categories,
                imageUrl: offProduct.imageUrl
            )
        }
    }
    
    // Проверка rate limit для продуктов (100 req/min)
    private mutating func checkProductRateLimit() async throws {
        let now = Date()
        if now.timeIntervalSince(lastProductRequest) >= 60 {
            // Сброс счетчика каждую минуту
            productRequestCount = 0
            lastProductRequest = now
        }
        
        if productRequestCount >= 100 {
            let waitTime = 60 - now.timeIntervalSince(lastProductRequest)
            if waitTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
            productRequestCount = 0
            lastProductRequest = Date()
        }
        
        productRequestCount += 1
    }
    
    // Проверка rate limit для поиска (10 req/min)
    private mutating func checkSearchRateLimit() async throws {
        let now = Date()
        if now.timeIntervalSince(lastSearchRequest) >= 60 {
            searchRequestCount = 0
            lastSearchRequest = now
        }
        
        if searchRequestCount >= 10 {
            let waitTime = 60 - now.timeIntervalSince(lastSearchRequest)
            if waitTime > 0 {
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
            }
            searchRequestCount = 0
            lastSearchRequest = Date()
        }
        
        searchRequestCount += 1
    }
}

// Структуры для парсинга ответов Open Food Facts
struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
}

struct OpenFoodFactsSearchResponse: Codable {
    let products: [OpenFoodFactsProduct]
}

struct OpenFoodFactsProduct: Codable {
    let code: String?
    let productName: String?
    let genericName: String?
    let brands: String?
    let categories: String?
    let imageUrl: String?
    let nutriments: OpenFoodFactsNutriments?
}

struct OpenFoodFactsNutriments: Codable {
    let energyKcal100g: Double?
    let proteins100g: Double?
    let fat100g: Double?
    let carbohydrates100g: Double?
    
    enum CodingKeys: String, CodingKey {
        case energyKcal100g = "energy-kcal_100g"
        case proteins100g = "proteins_100g"
        case fat100g = "fat_100g"
        case carbohydrates100g = "carbohydrates_100g"
    }
} 