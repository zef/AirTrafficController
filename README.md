# AirTrafficController - A Generic Router in Swift

This router can be used in many contexts because the Request and Response types are generics. You
simply need to provide a struct conforming to `RequestHandler`, with a routes conforming to
`Routable`. Your Response type can be whatever you want.

For example, in an iOS app you might want `Request` to be simply a `String` and response to be a
`Bool`, while in a web context, you would want more complex `Request` and `Response` types.

