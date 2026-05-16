// MARK: - PermissionPublisher (Combine)

#if canImport(Combine)
import Combine
import Foundation

extension Permission {
    /// A Combine publisher that emits the current permission status and subsequent changes.
    public var publisher: AnyPublisher<PermissionStatus, Never> {
        let stream = self.statusStream
        return AsyncStreamPublisher(stream: stream).eraseToAnyPublisher()
    }

    /// A Combine publisher that observes multiple permissions.
    public static func publisher(for permissions: [Permission]) -> AnyPublisher<(Permission, PermissionStatus), Never> {
        let stream = Permission.observe(permissions)
        return AsyncStreamPublisher(stream: stream).eraseToAnyPublisher()
    }
}

// MARK: - AsyncStreamPublisher

/// Bridges an AsyncStream to a Combine Publisher.
private struct AsyncStreamPublisher<Element: Sendable>: Publisher {
    typealias Output = Element
    typealias Failure = Never

    let stream: AsyncStream<Element>

    func receive<S: Subscriber>(subscriber: S) where S.Input == Element, S.Failure == Never {
        let subscription = AsyncStreamSubscription(stream: stream, subscriber: subscriber)
        subscriber.receive(subscription: subscription)
    }
}

private final class AsyncStreamSubscription<S: Subscriber, Element: Sendable>: Subscription, @unchecked Sendable
    where S.Input == Element, S.Failure == Never {

    private var task: Task<Void, Never>?
    private let stream: AsyncStream<Element>
    private let subscriber: S

    init(stream: AsyncStream<Element>, subscriber: S) {
        self.stream = stream
        self.subscriber = subscriber
    }

    func request(_ demand: Subscribers.Demand) {
        guard task == nil else { return }
        task = Task { [weak self] in
            guard let self else { return }
            for await element in self.stream {
                if Task.isCancelled { break }
                _ = self.subscriber.receive(element)
            }
            self.subscriber.receive(completion: .finished)
        }
    }

    func cancel() {
        task?.cancel()
        task = nil
    }
}
#endif
