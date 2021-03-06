public protocol Routable {
    var path: String { get }
}

public protocol RequestHandler: CustomStringConvertible {
    associatedtype Request: Routable
    associatedtype Response

    // the response returned when no routes match
    static var defaultResponse: Response { get }

    var path: String { get }
    func respond(request: Request, params: [String: String]) -> Response

    // have default implementations, but can be overridden
    func validMatch(request: Request, data: [String: String]) -> Bool
    // description is also overridable
}

public extension RequestHandler {
    var description: String {
        return path
    }
}

// would be cool to be able to nest routers
// maybe even have a pattern where a controller defines a router, and then nests it at a mount point?
// that would make refactoring routes really easy
// not sure if it's better to generate flat routes as they are added,
// or to have a nested scheme where the nesting is calculated at matching time...
// kinda prefer the latter
public struct Router<Route: RequestHandler> {

    public init() { }

    public var routes = [Route]()

    public mutating func register(routes: Route...) {
        register(routes)
    }
    public mutating func register(routes: [Route]...) {
        self.routes.append(contentsOf: routes.flatMap{$0})
    }

    public func handle(request: Route.Request) -> Route.Response {
        guard let matchData = routeMatchData(request) else { return Route.defaultResponse }
        return matchData.route.respond(request, params: matchData.data)
    }

    // if path matches but not method, could suggest that to warn the dev about the potential problem
    private func routeMatchData(request: Route.Request) -> (route: Route, data: [String: String])? {
        for route in routes {
            if let data = route.dataFromPath(request.path) where route.validMatch(request, data: data) {
                return (route, data)
            }
        }
        return nil
    }

    public var routeList: String {
        return routes.map { return String($0) }.joined(separator: "\n")
    }
}


public extension RequestHandler {

    // intended to be overridden by Request types that implement additional matching logic
    func validMatch(request: Request, data: [String: String]) -> Bool {
        return true
    }

    func dataFromPath(requestPath: String) -> [String: String]? {
        let templateComponents = path.unicodeScalars.split(separator: "/").map(String.init)
        let pathComponents = requestPath.unicodeScalars.split(separator: "/").map(String.init)

        guard templateComponents.count == pathComponents.count else { return nil }

        let valueIdentifiers = templateComponents.reduce([String]()) { result, component in
            var result = result
            if component.hasPrefix(":") {
                result.append(component)
            }
            return result
        }
        let valueIndices = valueIdentifiers.flatMap { templateComponents.index(of: $0) }

        var data = [String: String]()
        for (index, component) in templateComponents.enumerated() {
            guard index < pathComponents.endIndex else { return nil }

            if let valueIndex = valueIndices.index(of: index) {
                let key = String(valueIdentifiers[valueIndex].unicodeScalars.dropFirst())
                data[key] = pathComponents[index]
            } else {
                if component != pathComponents[index] {
                    return nil
                }
            }
        }

        return data
    }
}

