//
//  MotionInfoEnums.swift
//  YBDeviceMotion
//
//  Created by Alex Staravoitau on 06/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import CoreMotion
import MessagePack

/**
 Device sensors available on an iOS device.
 
 - `gyro`:          Gyroscope.
 - `accelerometer`: Accelerometer.
 - `magnetormeter`: Magnetormeter.
 - `deviceMotion`:  A set of iOS SDK algorithms that work with raw sensors data.
 */
internal enum DeviceSensor {
    
    /// Gyroscope
    case gyro
    /// Accelerometer
    case accelerometer
    /// Magnetormeter
    case magnetometer
    /// A set of iOS SDK algorithms that work with raw sensors data
    case deviceMotion
    
    /// A description of the sensor as a `String`.
    internal var description: String {
        switch self {
        case .gyro:
            return "Gyroscope"
        case .accelerometer:
            return "Accelerometer"
        case .magnetometer:
            return "Magnetometer"
        case .deviceMotion:
            return "Device Motion Algorithm"
        }
    }
    
}

/**
 Sections of the `UITableView` we use to display sensors' data.
 
 - `rawGyroData`:                     Raw gyroscope data.
 - `rawAccelerometerData`:            Raw accelerometer data.
 - `rawMagnetometerData`:             Raw magnetometer data.
 - `rotationRate`:        Rotation rate as returned by the `DeviceMotion` algorithms.
 - `userAcceleration`:    User acceleration as returned by the `DeviceMotion` algorithms.
 - `gravity`:             Gravity value as returned by the `DeviceMotion` algorithms.
 */
internal enum DataTableSection {
    
    /// Raw gyroscope data.
    case rawGyroData
    /// Raw accelerometer data.
    case rawAccelerometerData
    /// Raw magnetometer data.
    case rawMagnetometerData
    /// Rotation rate as returned by the `DeviceMotion` algorithms.
    case rotationRate
    /// User acceleration as returned by the `DeviceMotion` algorithms.
    case userAcceleration
    /// Gravity value as returned by the `DeviceMotion` algorithms.
    case gravity
    /// Distance travelled of the device, measured using deviceMotion data
    case deviceDistance
    
    /// An `Array` of all sections in the order specified in the storyboard.
    internal static let allSections = [deviceDistance, userAcceleration, gravity, rotationRate, rawAccelerometerData, rawGyroData, rawMagnetometerData]
    
    /// `Int` index of the section in `UITableView`.
    internal var index: Int {
        return DataTableSection.allSections.index(of: self) ?? 0
    }
    
}

/**
 Rows we use for displaying data in `UITableView`.
 
 - `axisX`: `X` axis value index
 - `axisY`: `Y` axis value index
 - `axisZ`: `Z` axis value index
 */
internal enum DataTableRow: Int {
    
    case axisX = 0
    case axisY = 1
    case axisZ = 2
    
    /// We are going to assign a color for each axis to display values fluctiation visually.
    internal var color: UIColor {
        switch self {
        case .axisX:
            return UIColor.red
        case .axisY:
            return UIColor.green
        case .axisZ:
            return UIColor.blue
        }
    }

}

internal struct Vector {
    var x : Double
    var y : Double
    var z : Double
    
    init(_ x : Double, _ y : Double, _ z : Double) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(_ acceleration : CMAcceleration) {
        self.init(acceleration.x, acceleration.y, acceleration.z)
    }
    
    init(_ all : Double) {
        self.init(all, all, all)
    }
}

extension Vector {
    static func +(lhs : Vector, rhs : Vector) -> Vector {
        return Vector(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    static prefix func -(vector: Vector) -> Vector {
        return Vector(-vector.x, -vector.y, -vector.z)
    }
    
    static func +=(left: inout Vector, right: Vector) {
        left = left + right
    }
    
    static func ==(lhs : Vector, rhs : Double) -> Bool {
        return lhs.x == rhs && lhs.y == rhs && lhs.z == rhs
    }
    
    static func ==(lhs : Vector, rhs : Vector) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z
    }
    
    static func !=(lhs : Vector, rhs : Double) -> Bool {
        return !(lhs == rhs)
    }
    
    mutating func round(decimals : Int = 1) -> Void {
        let fac = Double(truncating:pow(10.0, decimals) as NSNumber)
        self.x = (self.x * fac).rounded() / fac
        self.y = (self.y * fac).rounded() / fac
        self.z = (self.z * fac).rounded() / fac
    }
    
    func rounded(decimals : Int = 1) -> Vector {
        var copy = self
        
        copy.round(decimals: decimals)
        
        return copy
    }

    func msgpackValue() -> MessagePackValue {
        return MessagePackValue([
            MessagePackValue(self.x),
            MessagePackValue(self.y),
            MessagePackValue(self.z)
        ])
    }
}

typealias Distance = Vector

var Timestamp: String {
    return "\(NSDate().timeIntervalSince1970 * 1000)"
}

enum Hand : String {
    case right
    case left
}
