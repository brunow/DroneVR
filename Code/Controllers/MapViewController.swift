//
//	DroneVR.
//	Created by:				Bruno Wernimont
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {
    
    let viewModel = RecoveryViewModel()
    
    private lazy var locationManager = CLLocationManager()
    
    let regionRadius: CLLocationDistance = 2000
    
    private var shouldCentereUserLocation = true
    
    private var userLocation: CLLocation?
    
    private var droneLocation: CLLocation {
        return viewModel.lastLocation()!
    }
    
    private let customView = MapView()
    
    private var degrees: Double = 0
    
    var mapView: MKMapView {
        return customView.mapView
    }
    
    required init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func loadView() {
        view = customView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(MapViewController.didPressDone))
        
        title = "Find my drone"
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
        locationManager.distanceFilter = kCLDistanceFilterNone
        
        mapView.showsUserLocation = true
        
        let ann = MKPointAnnotation()
        ann.title = "Drone"
        ann.coordinate = droneLocation.coordinate
        mapView.addAnnotation(ann)
        centerMapOnLocations()
        
        customView.dateView.value = viewModel.lastStringDate
        
        customView.closeBtn.addTarget(self, action: #selector(MapViewController.closeAction), forControlEvents: .TouchUpInside)
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func didPressDone() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func closeAction() {
        dismissViewControllerAnimated(true, completion: nil)
    }

}

// MARK: Private
extension MapViewController {
    
    private func calculateUserAngle(current: CLLocationCoordinate2D) {
        var x: Double = 0
        var y: Double = 0
        var deg: Double = 0
        var delLon: Double = 0
        let fixLon = droneLocation.coordinate.longitude
        let fixLat = droneLocation.coordinate.latitude
        
        delLon = fixLon - current.longitude
        y = sin(delLon) * cos(fixLat)
        x = cos(current.latitude) * sin(fixLat) - sin(current.latitude) * cos(fixLat) * cos(delLon)
        deg = atan2(y, x).radiansToDegrees
        
        if deg < 0 {
            deg = -deg
        } else {
            deg = 360 - deg
        }
        
        degrees = deg
    }
    
    private func centerMapOnLocations() {
        if let userLocation = userLocation {
            var locations: [CLLocationCoordinate2D] = []
            locations.append(userLocation.coordinate)
            locations.append(droneLocation.coordinate)
            
            var r = MKMapRectNull
            
            for coordinate in locations {
                let p = MKMapPointForCoordinate(coordinate)
                r = MKMapRectUnion(r, MKMapRectMake(p.x, p.y, 0, 0))
            }
            
            let padding: CGFloat = 50
            mapView.setVisibleMapRect(r, edgePadding: UIEdgeInsetsMake(padding, padding, padding, padding), animated: true)
            
        } else {
            let coordinateRegion = MKCoordinateRegionMakeWithDistance(droneLocation.coordinate, regionRadius * 2.0, regionRadius * 2.0)
            mapView.setRegion(coordinateRegion, animated: true)
        }
    }
    
}

// MARK: CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard locations.count > 0 else { return }
        userLocation = locations.first
        calculateUserAngle(userLocation!.coordinate)
        
        let distance = viewModel.distanceFromLocation(userLocation!)
        customView.distanceView.value = distance
        
        if shouldCentereUserLocation {
            centerMapOnLocations()
            shouldCentereUserLocation = false
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let rotation = (degrees - newHeading.trueHeading) * M_PI / 180
        customView.compassView.transform = CGAffineTransformMakeRotation(CGFloat(rotation))
    }
    
}

// MARK: MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKPointAnnotation {
            let identifier = "drone"
            var view: MKPinAnnotationView

            if let dequeuedView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView {
                dequeuedView.annotation = annotation
                view = dequeuedView

            } else {
                view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                viewModel
            }

            return view
        }
        
        return nil
    }
    
}
