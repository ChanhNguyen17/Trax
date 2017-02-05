//
//  ViewController.swift
//  Trax
//
//  Created by Chanh Nguyen on 2/5/17.
//  Copyright © 2017 Stanford University. All rights reserved.
//

import UIKit
import MapKit

class GPXViewController: UIViewController, MKMapViewDelegate {
    
    var gpxURL: URL? {
        didSet {
            clearWaypoints()
            if let url = gpxURL {
                GPX.parse(url) { gpx in
                    if gpx != nil {
                        self.addWaypoints(gpx!.waypoints)
                    }
                }
            }
        }
    }
    
    private func clearWaypoints() {
        mapView?.removeAnnotations(mapView.annotations)
    }
    
    private func addWaypoints(_ waypoints: [GPX.Waypoint]) {
        mapView?.addAnnotations(waypoints)
        mapView?.showAnnotations(waypoints, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        var view: MKAnnotationView! = mapView.dequeueReusableAnnotationView(withIdentifier: Constants.AnnotationViewReuseIdentifier)
        if view == nil {
            view = MKPinAnnotationView(annotation: annotation, reuseIdentifier: Constants.AnnotationViewReuseIdentifier)
            view.canShowCallout = true
        } else {
            view.annotation = annotation
        }
        
        view.isDraggable = annotation is EditableWaypoint
        
        view.leftCalloutAccessoryView = nil
        view.rightCalloutAccessoryView = nil
        if let waypoint = annotation as? GPX.Waypoint {
            if waypoint.thumbnailURL != nil {
                view.leftCalloutAccessoryView = UIButton(frame: Constants.LeftCalloutFrame)
            }
            if waypoint is EditableWaypoint {
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
        }
        
        return view
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let thumbnailImageButton = view.leftCalloutAccessoryView as? UIButton,
            let url = (view.annotation as? GPX.Waypoint)?.thumbnailURL,
            let imageData = try? Data(contentsOf: url as URL), // blocks main queue
            let image = UIImage(data: imageData) {
            thumbnailImageButton.setImage(image, for: .normal)
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == view.leftCalloutAccessoryView {
            performSegue(withIdentifier: Constants.ShowImageSegue, sender: view)
        } else if control == view.rightCalloutAccessoryView {
            mapView.deselectAnnotation(view.annotation, animated: true)
            performSegue(withIdentifier: Constants.EditUserWaypoint, sender: view)
        }
    }
    
    // MARK: Navigation
    
    @IBAction func updatedUserWaypoint(segue: UIStoryboardSegue) {
        selectWaypoint((segue.source.contentViewController as? EditWaypointViewController)?.waypointToEdit)
    }
    
    private func selectWaypoint(_ waypoint: GPX.Waypoint?) {
        if waypoint != nil {
            mapView.selectAnnotation(waypoint!, animated: true)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destination = segue.destination.contentViewController
        let annotationView = sender as? MKAnnotationView
        let waypoint = annotationView?.annotation as? GPX.Waypoint
        
        if segue.identifier == Constants.ShowImageSegue {
            if let ivc = destination as? ImageViewController {
                ivc.imageURL = waypoint?.imageURL
                ivc.title = waypoint?.name
            }
        } else if segue.identifier == Constants.EditUserWaypoint {
            if let editableWaypoint = waypoint as? EditableWaypoint,
                let ewvc = destination as? EditWaypointViewController {
                ewvc.waypointToEdit = editableWaypoint
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        gpxURL = URL(string: "http://cs193p.stanford.edu/Vacation.gpx")
    }
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet{
            mapView.mapType = .satellite
            mapView.delegate = self
        }
    }
    
    @IBAction func addWayPoint(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            let coordinate = mapView.convert(sender.location(in: mapView), toCoordinateFrom: mapView)
            let waypoint = EditableWaypoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
            waypoint.name = "Dropped"
            mapView.addAnnotation(waypoint)
        }
    }
    
    // MARK: Constants
    
    fileprivate struct Constants {
        static let LeftCalloutFrame = CGRect(x: 0, y: 0, width: 59, height: 59) // sad face
        static let AnnotationViewReuseIdentifier = "waypoint"
        static let ShowImageSegue = "Show Image"
        static let EditUserWaypoint = "Edit Waypoint"
    }
}

extension UIViewController {
    var contentViewController: UIViewController {
        if let navcon = self as? UINavigationController {
            return navcon.visibleViewController ?? navcon
        } else {
            return self
        }
    }
}

