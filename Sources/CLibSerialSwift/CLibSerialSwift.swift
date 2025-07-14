import Foundation
import libserialport

public enum SerialError: Error {
    case openFailed
    case configFailed
    case readFailed
    case writeFailed
}

public final class SerialPort {
    private var port: OpaquePointer?

    public init?(path: String) {
        var p: OpaquePointer?
        let result = sp_get_port_by_name(path, &p)
        if result != SP_OK || p == nil {
            return nil
        }
        self.port = p
    }

    deinit {
        if let port = port {
            sp_close(port)
            sp_free_port(port)
        }
    }

    public func open(baudRate: Int32 = 9600) throws {
        guard let port = port else { throw SerialError.openFailed }
        if sp_open(port, SP_MODE_READ_WRITE) != SP_OK {
            throw SerialError.openFailed
        }

        if sp_set_baudrate(port, baudRate) != SP_OK ||
           sp_set_bits(port, 8) != SP_OK ||
           sp_set_parity(port, SP_PARITY_NONE) != SP_OK ||
           sp_set_stopbits(port, 1) != SP_OK {
            throw SerialError.configFailed
        }
    }

    public func write(data: Data) throws {
        guard let port = port else { throw SerialError.writeFailed }
        let written = data.withUnsafeBytes { buffer in
            return sp_blocking_write(port, buffer.baseAddress, data.count, 1000)
        }
        if !isWriteSuccess(written, expected: data.count) {
            throw SerialError.writeFailed
        }
    }

    public func read(maxLength: Int = 512) throws -> Data {
        guard let port = port else { throw SerialError.readFailed }

        var buffer = [UInt8](repeating: 0, count: maxLength)
        let count = sp_blocking_read(port, &buffer, maxLength, 1000)

        if !isReadSuccess(count) {
            throw SerialError.readFailed
        }

        return Data(buffer.prefix(Int(count.rawValue)))
    }

    private func isWriteSuccess(_ written: sp_return, expected: Int) -> Bool {
        return written.rawValue >= 0 && written.rawValue == expected
    }

    private func isReadSuccess(_ count: sp_return) -> Bool {
        return count.rawValue >= 0
    }
}
