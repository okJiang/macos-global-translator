import Foundation
@testable import GlobalTranslatorApp

actor RequestRecorder {
    private(set) var lastRequest: URLRequest?

    func record(_ request: URLRequest) {
        lastRequest = request
    }
}

struct MockHTTPClient: HTTPClient {
    let recorder: RequestRecorder
    let responseData: Data
    var statusCode = 200
    var headerFields = ["Content-Type": "application/json"]

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        await recorder.record(request)
        return (
            responseData,
            HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: headerFields
            )!
        )
    }
}

extension Data {
    func utf8String() throws -> String {
        guard let string = String(data: self, encoding: .utf8) else {
            throw URLError(.cannotDecodeContentData)
        }

        return string
    }

    func jsonObject() throws -> Any {
        try JSONSerialization.jsonObject(with: self)
    }
}
