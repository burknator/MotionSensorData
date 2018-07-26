//
//  ViewController.swift
//  YBDeviceMotion
//
//  Created by Alex Staravoitau on 06/04/2016.
//  Copyright © 2016 Old Yellow Bricks. All rights reserved.
//

import UIKit
import CoreMotion

/// A `UIViewController` class that displays data from the motion sensors available on the device.
final class MotionInfoViewController: UITableViewController {
    
    override internal func viewDidLoad() {
        super.viewDidLoad()
        
        // Initiate the `CoreMotion` updates to our callbacks.
        startAccelerometerUpdates()
        startGyroUpdates()
        startMagnetometerUpdates()
        startDeviceMotionUpdates()
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
     *  Configure the Device Motion algorithm data callback.
     */
    fileprivate func startDeviceMotionUpdates() {
        if !motionManager.isDeviceMotionAvailable { return }

        motionManager.deviceMotionUpdateInterval = 0.1
        
        var d = Vector(0.0)
        var v = Vector(0.0)
        var calibration : Vector!
        var previousA : Vector?
        
        motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (deviceMotion, error) in
            defer {
                self.report(distance: Distance(d.x, d.y, d.z), inSection: .deviceDistance)
                self.report(acceleration: deviceMotion?.gravity, inSection: .gravity)
                self.report(acceleration: deviceMotion?.userAcceleration, inSection: .userAcceleration)
                self.report(rotationRate: deviceMotion?.rotationRate, inSection: .rotationRate)
                self.log(error: error, forSensor: .deviceMotion)
            }
            
            // Ab hier muss eigentlich alles fuer jede x, y und z Variable gemacht werden
            var a = Vector(deviceMotion!.userAcceleration)
            
            if let prev = previousA, a.rounded(decimals: 3) == prev.rounded(decimals: 3) {
                return
            }
            
            previousA = a
            
            a.round()
            
            if calibration == nil {
                calibration = -a
            }
            
            if a.x + calibration.x != 0.0 {
                v.x = v.x + a.x + calibration.x
                d.x = d.x + v.x
            }
            
            if a.y + calibration.y != 0.0 {
                v.y = v.y + a.y + calibration.y
                d.y = d.y + v.y
            }
            
            if a.z + calibration.z != 0.0 {
                v.z = v.z + a.z + calibration.z
                d.z = d.z + v.z
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

