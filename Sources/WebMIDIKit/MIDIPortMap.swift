//
//  MIDIPortMap.swift
//  WebMIDIKit
//
//  Created by Adam Nemecek on 1/31/17.
//
//

import CoreMIDI

public class MIDIPortMap<Value: MIDIPort> : Collection, CustomStringConvertible, CustomDebugStringConvertible {
    public typealias Key = Int
    public typealias Index = Dictionary<Key, Value>.Index

    public final var startIndex: Index {
        return _content.startIndex
    }

    public final var endIndex: Index {
        return _content.endIndex
    }

    public final subscript (key: Key) -> Value? {
        get {
            return _content[key]
        }
        set {
            _content[key] = newValue
        }
    }

    public final subscript(index: Index) -> (Key, Value) {
        return _content[index]
    }

    public final func index(after i: Index) -> Index {
        return _content.index(after: i)
    }

    public final var description: String {
        return dump(_content).description
    }

    public func port(with name: String) -> Value? {
        return _content.first { $0.value.displayName == name }?.value
    }
    
    /// Return a MIDIPort upon selection on API level
    /// (Remove the need to use WebMIDIKit in the console
    /// and allow automation)
    public final func select(choice: Int) -> Value? {
        guard let _ = first?.1.type else { print("No ports found"); return nil }
        
        let ports = map { $0.1 }
        return ports[safe: choice]
    }

    /// Prompts the user to select a MIDIPort (non-standard)
    public final func prompt() -> Value? {
        guard let type = first?.1.type else { print("No ports found"); return nil }
        print("Select \(type) by typing the associated number")
        let ports = map { $0.1 }

        for (i, port) in ports.enumerated() {
            print("  #\(i) = \(port)")
        }

        print("Select: ", terminator: "")
        guard let choice = (readLine().flatMap { Int($0) }) else { return nil }
        return ports[safe: choice]
    }

    internal final func add(_ port: Value) -> Value? {
        assert(self[port.id] == nil)
        self[port.id] = port
        return port
    }

    internal final func remove(_ endpoint: MIDIEndpoint) -> Value? {
        //disconnect?
        guard let port = self[endpoint] else { assert(false); return nil }
        assert(port.state == .connected)
        self[port.id] = nil
        return port
    }

    //
    fileprivate init(client: MIDIClient, ports: [Value]) {
        self._client = client
        self._content = .init(uniqueKeysWithValues: ports.lazy.map { ($0.id, $0) } )
    }

    //
    // todo should this be doing key, value?
    //
    private final subscript (endpoint: MIDIEndpoint) -> Value? {
        return _content.first { $0.value.endpoint == endpoint }?.value
    }

    private final var _content: [Key: Value]
    fileprivate final weak var _client: MIDIClient!
}

public final class MIDIInputMap : MIDIPortMap<MIDIInput> {
    internal init(client: MIDIClient) {
        let inputs = MIDISources().map { MIDIInput(client: client, endpoint: $0) }
        super.init(client: client, ports: inputs)
    }

    internal final func add(_ endpoint: MIDIEndpoint) -> MIDIPort? {
        return add(MIDIInput(client: _client, endpoint: endpoint))
    }
}

public final class MIDIOutputMap : MIDIPortMap<MIDIOutput> {
    internal init(client: MIDIClient) {
        let outputs = MIDIDestinations().map { MIDIOutput(client: client, endpoint: $0) }
        super.init(client: client, ports: outputs)
    }

    internal final func add(_ endpoint: MIDIEndpoint) -> MIDIPort? {
        return add(MIDIOutput(client: _client, endpoint: endpoint))
    }
}


@inline(__always) fileprivate
func MIDISources() -> [MIDIEndpoint] {
    return (0..<MIDIGetNumberOfSources()).map {
        .init(ref: MIDIGetSource($0))
    }
}

@inline(__always) fileprivate
func MIDIDestinations() -> [MIDIEndpoint] {
    return (0..<MIDIGetNumberOfDestinations()).map {
        .init(ref: MIDIGetDestination($0))
    }
}
