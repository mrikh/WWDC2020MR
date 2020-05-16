import Foundation

public struct PhysicsCategory{

    public static let none : UInt32 = 0
    public static let all : UInt32 = UInt32.max
    public static let boulder : UInt32 = 0b1
    public static let player : UInt32 = 0b10

    public static let powerUp : UInt32 = 0b11
    public static let laser : UInt32 = 0b100
    public static let shield: UInt32 = 0b101
    public static let explosion : UInt32 = 0b110
}

