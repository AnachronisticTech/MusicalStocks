//
//  StockPriceDownloader.swift
//  MusicalStocks
//
//  Created by Daniel Marriner on 25/09/2021.
//

import Foundation
import Combine

class StockPriceDownloader: ObservableObject {
    public static var shared = StockPriceDownloader()

    private init() {}

    func fetchStockData(
        for symbol: String = "AAPL",
        _ completion: @escaping (Result<WebData, MusicalStocksError>) -> () = { _ in }
    ) throws {
        let currentTime = Date()
            .timeIntervalSince1970
            .rounded()
        let url = URL(string: "https://finnhub.io/api/v1/stock/candle?symbol=\(symbol)&resolution=1&from=\(Int(currentTime)-15000)&to=\(Int(currentTime))")!
        var request = URLRequest(url: url)
        request.addValue(Constants.finnhubSandboxAPIKey, forHTTPHeaderField: "X-Finnhub-Token")
        URLSession.shared
            .dataTask(with: request) { result in
                completion(Decoders.dataDecoder.decode(result))
            }
            .resume()
    }
}

public enum MusicalStocksError: Error, CustomStringConvertible {
    case bearerTokenNotSetError
    case transporError(Error)
    case serverError(statusCode: Int)
    case emptyData
    case decodingError(Error)

    init?(data: Data?, response: URLResponse?, error: Error?) {
        if let error = error {
            self = .transporError(error)
            return
        }

        if let response = response as? HTTPURLResponse, response.statusCode != 200 {
            self = .serverError(statusCode: response.statusCode)
            return
        }

        if data == nil {
            self = .emptyData
            return
        }

        return nil
    }

    public var description: String {
        switch self {
            case .bearerTokenNotSetError:
                return "[ERROR] No Bearer token was provided for authentication. Please set one using `TVDB.setToken(_:)`. A v4 auth token can be obtained from https://www.themoviedb.org/settings/api."
            case .transporError(let error):
                return "[ERROR] There was a problem communicating with the server: \(error)"
            case .serverError(statusCode: let code):
                return "[ERROR] The server reported en error of type \(code)."
            case .emptyData:
                return "[ERROR] The server response contained no data."
            case .decodingError(let error):
                return "[ERROR] There was a problem decoding the data received from the server: \(error)"
        }
    }
}

typealias DataResult = Result<Data, MusicalStocksError>

extension URLSession {
    func dataTask(with request: URLRequest, resultHandler: @escaping (DataResult) -> ()) -> URLSessionDataTask {
        dataTask(with: request) { data, response, error in
            if let networkError = MusicalStocksError(data: data, response: response, error: error) {
                resultHandler(.failure(networkError))
                return
            }
            resultHandler(.success(data!))
        }
    }
}

struct ResultDecoder<T> {
    private let transform: (Data) throws -> T

    init(_ transform: @escaping (Data) throws -> T) {
        self.transform = transform
    }

    func decode(_ result: DataResult) -> Result<T, MusicalStocksError> {
        result.flatMap { data in
            Result { try transform(data) }
                .mapError { MusicalStocksError.decodingError($0) }
        }
    }
}

protocol ModelDecoders {
    static var dataDecoder: ResultDecoder<WebData> { get }
}

class Decoders: ModelDecoders {
    private init() {}

    static let dataDecoder = ResultDecoder<WebData> { data in
        try JSONDecoder().decode(WebData.self, from: data)
    }
}

struct WebData: Codable {
    let c: [Double]
}

struct Constants {
    static let polygonAPIKey = "PcMBQ9pydWrK3LAnC8NtYe3YbrsYSr8K"
    static let finnhubSandboxAPIKey = "sandbox_c57n1jiad3idnp0qq8f0"
}
