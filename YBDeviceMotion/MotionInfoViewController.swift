//
//  ViewController.swift
//  YBDeviceMotion
//
//  Created by Alex Staravoitau on 06/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import CoreMotion
import SwiftyZeroMQ
import MessagePack

/// A `UIViewController` class that displays data from the motion sensors available on the device.
final class MotionInfoViewController: UITableViewController {

    var publisher : SwiftyZeroMQ.Socket?
    var context : SwiftyZeroMQ.Context?
    var confidence = 1.0
    // TODO Make this configurable via UI
    var side : Hand = .right
    // TODO Make this configurable via UI
    let ip = "10.18.0.46"
    //let ip = "192.168.2.101"

    override internal func viewDidLoad() {
        super.viewDidLoad()

        do {
            let endpoint = "tcp://\(ip):50020"
            self.context = try SwiftyZeroMQ.Context()

            let requester = try context?.socket(.request)
            try requester?.connect(endpoint)
            try requester?.send(string: "PUB_PORT")

            let pub_port = try requester?.recv()
            let publisher_endpoint = "tcp://\(ip):\(pub_port!)"

            self.publisher = try context?.socket(.publish)
            try self.publisher?.setSendHighWaterMark(0)

            try self.publisher?.connect(publisher_endpoint)
        } catch let error {
            print(error.localizedDescription)
        }

        // Initiate the `CoreMotion` updates to our callbacks.
        startAccelerometerUpdates()
        startGyroUpdates()
        startMagnetometerUpdates()
        startDeviceMotionUpdates()
    }

    /**
     *  Configure the Device Motion algorithm data callback.
     */
    fileprivate func startDeviceMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0

        var distance = Distance(0.0)
        var velocity = Vector(0.0)
        var calibration : Vector!
        var previousA : Vector?

        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (deviceMotion, error) in
            defer {
                self.report(distance: distance, inSection: .deviceDistance)
                self.report(acceleration: deviceMotion?.gravity, inSection: .gravity)
                self.report(acceleration: deviceMotion?.userAcceleration, inSection: .userAcceleration)
                self.report(rotationRate: deviceMotion?.rotationRate, inSection: .rotationRate)
                self.log(error: error, forSensor: .deviceMotion)
            }

            // TODO This is linear now (and dummy too), but it has to be quadratic
            if self.confidence - 0.001 < 0 {
                self.confidence = 0
            } else {
                self.confidence -= 0.001
            }

            var acceleration = Vector(deviceMotion!.userAcceleration)

            if let previousA = previousA, acceleration.rounded(decimals: 10) == previousA.rounded(decimals: 10) {
                return
            }

            previousA = acceleration

            acceleration.round()

            if calibration == nil {
                calibration = -acceleration
            }

            acceleration += calibration

            if acceleration.x != 0.0 {
                velocity.x = velocity.x + acceleration.x
                distance.x = distance.x + velocity.x
            }

            if acceleration.y != 0.0 {
                velocity.y = velocity.y + acceleration.y
                distance.y = distance.y + velocity.y
            }

            if acceleration.z != 0.0 {
                velocity.z = velocity.z + acceleration.z
                distance.z = distance.z + velocity.z
            }

            let msgData = distance.msgpackValue(self.confidence)
            let data = pack(msgData)

            try! self.publisher?.send(string: "han2.\(self.side)", options: .sendMore)
            try! self.publisher?.send(data: data)
        }
    }
    
    /// CoreMotion manager instance we receive updates from.
    fileprivate let motionManager = CMMotionManager()
    
    // MARK: - Configuring CoreMotion callbacks triggered for each sensor
    
    /**
     *  Configure the raw accelerometer data callback.
     */
    fileprivate func startAccelerometerUpdates() {
        if motionManager.isAccelerometerAvailable {
            motionManager.accelerometerUpdateInterval = 0.1
            motionManager.startAccelerometerUpdates(to: OperationQueue.main) { (accelerometerData, error) in
                self.report(acceleration: accelerometerData?.acceleration, inSection: .rawAccelerometerData)
                self.log(error: error, forSensor: .accelerometer)
            }
        }
    }
    
    /**
     *  Configure the raw gyroscope data callback.
     */
    fileprivate func startGyroUpdates() {
        if motionManager.isGyroAvailable {
            motionManager.gyroUpdateInterval = 0.1
            motionManager.startGyroUpdates(to: OperationQueue.main) { (gyroData, error) in
                self.report(rotationRate: gyroData?.rotationRate, inSection: .rawGyroData)
                self.log(error: error, forSensor: .gyro)
            }
        }
    }
    
    /**
     *  Configure the raw magnetometer data callback.
     */
    fileprivate func startMagnetometerUpdates() {
        if motionManager.isMagnetometerAvailable {
            motionManager.magnetometerUpdateInterval = 0.1
            motionManager.startMagnetometerUpdates(to: OperationQueue.main) { (magnetometerData, error) in
                self.report(magneticField: magnetometerData?.magneticField, inSection: .rawMagnetometerData)
                self.log(error: error, forSensor: .magnetometer)
            }
        }
    }

    /**
     Logs an error in a consistent format.
     
     - parameter error:  Error value.
     - parameter sensor: `DeviceSensor` that triggered the error.
     */
    fileprivate func log(error: Error?, forSensor sensor: DeviceSensor) {
        guard let error = error else { return }
        
        NSLog("Error reading data from \(sensor.description): \n \(error) \n")
    }

}
