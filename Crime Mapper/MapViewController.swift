//
//  MapViewController.swift
//  Crime Mapper
//
//  Created by Donal O'Callaghan on 06/03/2017.
//  Copyright © 2017 Donal O'Callaghan. All rights reserved.
//

import UIKit
import MapKit
import Alamofire
import HandyJSON
import CoreActionSheetPicker

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            let noLocation = CLLocationCoordinate2D(latitude: 51.507983, longitude: -0.127545)
            let viewRegion = MKCoordinateRegionMakeWithDistance(noLocation, 1500, 1500)
            self.mapView.setRegion(viewRegion, animated: false)
        }
    }
    
    @IBOutlet weak var dateButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let baseUrl = "http://data.police.uk/api/"
    
    let datesPath = "crimes-street-dates"
    
    let categoriesPath = "crime-categories?date="
    
    let streetCrimePath = "crimes-street/all-crime"
    
    let regionRadius: CLLocationDistance = 2
    
    var currentDate: String = ""
    
    var streetLevelAvailabilityDates: [String] = []
    
    var crimeCategories: NSMutableDictionary = [:]
    
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        self.view.bringSubview(toFront: activityIndicator)
        checkLocationAuthorizationStatus()
    }
    
    // MARK: - location manager to authorize user location for Maps app
    
    func checkLocationAuthorizationStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            enableUserLocation()
        } else {
            locationManager.requestWhenInUseAuthorization()
            getCrimeAvailability()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.authorizedWhenInUse)
        {
            enableUserLocation()
        }
    }
    
    func enableUserLocation(){
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        getCrimeAvailability()
    }
    
    // MARK: - Navigation
    
    @IBAction func refreshButtonClicked(_ sender: Any) {
        if(streetLevelAvailabilityDates.count == 0)
        {
            showLoading()
            getCrimeAvailability()
        }
        else{
            refreshCrimeData()
        }
    }
    
    @IBAction func dateButtonClicked(_ sender: Any) {
        ActionSheetStringPicker.show(withTitle: "Select date", rows: streetLevelAvailabilityDates, initialSelection: 0, doneBlock: {
            picker, indexes, values in
            self.setDate(date: self.streetLevelAvailabilityDates[indexes])
            self.refreshCrimeData()
            
            return
        }, cancel: { ActionMultipleStringCancelBlock in return }, origin: sender)
    }
    
    private func updateDateButtonTitle(){
        self.dateButton.setTitle(currentDate, for: UIControlState.selected)
        self.dateButton.setTitle(currentDate, for: UIControlState.normal)
    }
    
    private func getCrimeAvailability(){
        let url = baseUrl+datesPath
        
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseString { response in
            if let status = response.response?.statusCode {
                if status == 200
                {
                    if let result = response.result.value {
                        if let items = [StreetLevelAvailabilityDate].deserialize(from: result)
                        {
                            if(items.count > 0){
                                self.streetLevelAvailabilityDates.removeAll()
                                for date in items
                                {
                                    self.streetLevelAvailabilityDates.append(date!.date)
                                }
                                
                                let first = items.first
                                self.setDate(date: first!!.date)
                                self.getCrimeCategoryMap(date: self.currentDate)
                            }
                            else
                            {
                                self.showError(error: "Error getting availability, array was empty")
                            }
                        }
                        else
                        {
                            self.showError(error: "Error parsing json")
                        }
                    }
                }
            }
        }
    }
    
    func setDate(date: String){
        self.currentDate = date
        updateDateButtonTitle()
    }
    
    private func getCrimeCategoryMap(date: String){
        let url = baseUrl+categoriesPath+date
        Alamofire.request(url, method: .get, encoding: JSONEncoding.default).responseString { response in
            if let status = response.response?.statusCode {
                if status == 200
                {
                    if let result = response.result.value {
                        if let items = [CrimeCategory].deserialize(from: result)
                        {
                            if(items.count > 0)
                            {
                                for crimeCategory in items
                                {
                                    let unwrappedCategory = crimeCategory!
                                    self.crimeCategories[unwrappedCategory.url] = unwrappedCategory.name
                                }
                                self.refreshCrimeData()
                            }
                            else
                            {
                                self.showError(error: "Empty category list")
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func refreshCrimeData(){
        showLoading()
        getCrimeData(location:mapView.centerCoordinate)
    }
    
    private func showLoading(){
        activityIndicator.startAnimating()
    }
    
    private func hideLoading(){
        activityIndicator.stopAnimating()
    }
    
    private func showError(error: String){
        hideLoading()
    }
    
    private func getCrimeData(location: CLLocationCoordinate2D)
    {
        let url = "https://data.police.uk/api/crimes-street/all-crime?lat=\(location.latitude)&lng=\(location.longitude)&date=\(currentDate)"
        
        Alamofire.request(url,   method: .get, encoding: JSONEncoding.default).responseString { response in
            let allAnnotations = self.mapView.annotations
            self.mapView.removeAnnotations(allAnnotations)
            
            if let status = response.response?.statusCode {
                if status == 200
                {
                    if let result = response.result.value {
                        if let items = [StreetLevelCrime].deserialize(from: result)
                        {
                            if(items.count > 0)
                            {
                                self.addItemsToMap(items: items)
                            }
                            else
                            {
                                
                                self.showError(error: "Empty crime data list")
                            }
                        }
                    }
                    else
                    {
                        self.showError(error: "Error, response is broken \(response)")
                    }
                }
                else
                {
                    self.showError(error: "Error, status code is \(status)")
                }
            }
            else
            {
                self.showError(error: "Catastrophic failure \(response)")
            }
        }
    }
    
    func addItemsToMap(items: [StreetLevelCrime?]){
        
        var previousLatitude: Double = 0
        var previousLongitude: Double = 0
        
        var annotation = CustomAnnotation()
        
        for crimeReport in items
        {
            let unwrappedReport = crimeReport!
            
            let latitude = Double(unwrappedReport.location.latitude)!
            let longitude = Double(unwrappedReport.location.longitude)!
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let title = String(describing: self.crimeCategories[unwrappedReport.category]!)
            
            var subtitle: String
            if(unwrappedReport.outcome_status.category.characters.count > 0){
                subtitle = unwrappedReport.outcome_status.category
            }
            else{
                subtitle = "Outcome unknown"
            }
            
            annotation.title = unwrappedReport.location.street.name
            
            let newReport = "(\(annotation.count)) " +  title+" - "+subtitle
            
            annotation.subtitleLong = annotation.subtitleLong + newReport
            
            let reuseAnnotation = latitude == previousLatitude && longitude == previousLongitude
            
            if reuseAnnotation
            {
                annotation.count = annotation.count + 1
                annotation.subtitleLong = annotation.subtitleLong + "\n\n"
            }
            else
            {
                annotation = CustomAnnotation()
                annotation.coordinate = coordinate
                self.mapView.addAnnotation(annotation)
            }
            
            previousLatitude = annotation.coordinate.latitude
            previousLongitude = annotation.coordinate.longitude
        }
        
        hideLoading()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        
        let customAnnotation = annotation as? CustomAnnotation
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: customAnnotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.animatesDrop = false
        }
        else {
            pinView!.annotation = customAnnotation
        }
        
        if(customAnnotation!.count > 1)
        {
            pinView?.pinTintColor = .red
        }
        else
        {
            pinView?.pinTintColor = .blue
        }
        
        let label = UILabel()
        label.font = label.font.withSize(10)
        label.numberOfLines = 0
        label.text = customAnnotation?.subtitleLong
        
        pinView?.detailCalloutAccessoryView = label
        
        return pinView
    }
    
    class CustomAnnotation: MKPointAnnotation
    {
        var count: Int = 1
        
        var subtitleLong: String = ""
        
        required override init() {
        }
    }
    @IBAction func myLocationButtonCLicked(_ sender: Any) {
        checkLocationAuthorizationStatus()
    }
}
