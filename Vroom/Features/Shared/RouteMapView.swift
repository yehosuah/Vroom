import MapKit
import SwiftUI

enum RouteMapMode: Sendable, Hashable {
    case idle
    case live
    case completed
    case replay(progress: Double)
}

struct RouteMapView: UIViewRepresentable {
    let trace: [RoutePointSample]
    let events: [DrivingEvent]
    let mode: RouteMapMode
    let style: AppMapStyle

    init(
        trace: [RoutePointSample],
        events: [DrivingEvent],
        mode: RouteMapMode,
        style: AppMapStyle = .standard
    ) {
        self.trace = trace
        self.events = events
        self.mode = mode
        self.style = style
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.pointOfInterestFilter = .excludingAll
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isPitchEnabled = true
        mapView.layoutMargins = UIEdgeInsets(top: 60, left: 24, bottom: 60, right: 24)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.apply(
            presentation: RoutePresentationBuilder.build(
                trace: trace,
                events: events,
                replayProgress: {
                    if case .replay(let progress) = mode {
                        return progress
                    }
                    return nil
                }()
            ),
            mode: mode,
            style: style,
            to: mapView
        )
    }
}

extension RouteMapView {
    @MainActor
    final class Coordinator: NSObject, MKMapViewDelegate {
        private var lastStaticSignature: RouteMapStaticSignature?
        private var lastDynamicSignature: RouteMapDynamicSignature?
        private var lastStyle: AppMapStyle?
        private var userInterruptedLiveCamera = false
        private var replayAnnotation: RouteAnnotation?

        func apply(
            presentation: RoutePresentation,
            mode: RouteMapMode,
            style: AppMapStyle,
            to mapView: MKMapView
        ) {
            applyStyle(style, to: mapView)
            let staticSignature = RouteMapStaticSignature(
                path: presentation.path,
                markers: presentation.markers.filter { marker in
                    if case .replay = marker.kind {
                        return false
                    }
                    return true
                }
            )
            let dynamicSignature = RouteMapDynamicSignature(mode: mode, highlight: presentation.highlightedCoordinate)

            if staticSignature != lastStaticSignature {
                lastStaticSignature = staticSignature
                renderStaticRoute(presentation, on: mapView)
            }
            if dynamicSignature != lastDynamicSignature {
                lastDynamicSignature = dynamicSignature
                updateReplayMarker(for: presentation, on: mapView)
                updateCamera(for: presentation, mode: mode, on: mapView)
            }
        }

        func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
            if animated {
                return
            }
            userInterruptedLiveCamera = true
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? RouteAnnotation else { return nil }

            let identifier = "route-marker-\(annotation.kind)"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
                ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            view.annotation = annotation
            view.canShowCallout = true
            view.titleVisibility = .visible
            view.subtitleVisibility = annotation.subtitle == nil ? .hidden : .visible

            switch annotation.kind {
            case .start:
                view.markerTintColor = UIColor(RoadTheme.liveGreen)
                view.glyphImage = UIImage(systemName: "play.fill")
            case .finish:
                view.markerTintColor = UIColor(RoadTheme.warningRed)
                view.glyphImage = UIImage(systemName: "flag.checkered")
            case .replay:
                view.markerTintColor = UIColor(RoadTheme.signalAmber)
                view.glyphImage = UIImage(systemName: "point.topleft.down.curvedto.point.bottomright.up.fill")
            case .event(let type):
                view.markerTintColor = UIColor(accentColor(for: type))
                view.glyphImage = UIImage(systemName: glyphName(for: type))
            }
            return view
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor(RoadTheme.electricBlue)
                renderer.lineWidth = 5
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }

        private func applyStyle(_ style: AppMapStyle, to mapView: MKMapView) {
            guard lastStyle != style else { return }
            lastStyle = style

            switch style {
            case .standard:
                mapView.preferredConfiguration = MKStandardMapConfiguration(elevationStyle: .realistic)
            case .hybrid:
                mapView.preferredConfiguration = MKHybridMapConfiguration(elevationStyle: .realistic)
            case .imagery:
                mapView.preferredConfiguration = MKImageryMapConfiguration(elevationStyle: .realistic)
            }
        }

        private func renderStaticRoute(_ presentation: RoutePresentation, on mapView: MKMapView) {
            mapView.removeOverlays(mapView.overlays)
            mapView.removeAnnotations(mapView.annotations)
            replayAnnotation = nil

            if !presentation.path.isEmpty {
                let coordinates = presentation.path.map(\.clCoordinate)
                mapView.addOverlay(MKPolyline(coordinates: coordinates, count: coordinates.count))
            }

            let annotations = presentation.markers.filter { marker in
                if case .replay = marker.kind {
                    return false
                }
                return true
            }.map { marker in
                RouteAnnotation(marker: marker)
            }
            mapView.addAnnotations(annotations)
        }

        private func updateReplayMarker(for presentation: RoutePresentation, on mapView: MKMapView) {
            let replayMarker = presentation.markers.first { marker in
                if case .replay = marker.kind {
                    return true
                }
                return false
            }

            guard let replayMarker else {
                if let replayAnnotation {
                    mapView.removeAnnotation(replayAnnotation)
                    self.replayAnnotation = nil
                }
                return
            }

            if let replayAnnotation {
                replayAnnotation.coordinate = replayMarker.coordinate.clCoordinate
            } else {
                let annotation = RouteAnnotation(marker: replayMarker)
                replayAnnotation = annotation
                mapView.addAnnotation(annotation)
            }
        }

        private func updateCamera(
            for presentation: RoutePresentation,
            mode: RouteMapMode,
            on mapView: MKMapView
        ) {
            guard !presentation.path.isEmpty else {
                let fallback = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: 34.0522, longitude: -118.2437),
                    span: MKCoordinateSpan(latitudeDelta: 0.35, longitudeDelta: 0.35)
                )
                mapView.setRegion(fallback, animated: false)
                return
            }

            switch mode {
            case .idle, .completed:
                userInterruptedLiveCamera = false
                mapView.setVisibleMapRect(
                    MKPolyline(coordinates: presentation.path.map(\.clCoordinate), count: presentation.path.count).boundingMapRect,
                    edgePadding: UIEdgeInsets(top: 80, left: 34, bottom: 120, right: 34),
                    animated: true
                )

            case .live:
                guard !userInterruptedLiveCamera, let last = presentation.path.last else { return }
                let region = MKCoordinateRegion(
                    center: last.clCoordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.015, longitudeDelta: 0.015)
                )
                mapView.setRegion(region, animated: true)

            case .replay:
                if let highlighted = presentation.highlightedCoordinate {
                    let region = MKCoordinateRegion(
                        center: highlighted.clCoordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                    )
                    mapView.setRegion(region, animated: false)
                }
            }
        }

        private func accentColor(for type: DrivingEventType) -> Color {
            switch type {
            case .hardBrake, .gForceSpike:
                return RoadTheme.warningRed
            case .hardAcceleration, .speedTrap:
                return RoadTheme.signalAmber
            case .cornering, .speedZone:
                return RoadTheme.electricBlue
            }
        }

        private func glyphName(for type: DrivingEventType) -> String {
            switch type {
            case .hardBrake:
                return "arrow.down.to.line"
            case .hardAcceleration:
                return "arrow.up.to.line"
            case .cornering:
                return "arrow.triangle.branch"
            case .gForceSpike:
                return "waveform.path.ecg"
            case .speedTrap:
                return "bolt.fill"
            case .speedZone:
                return "scope"
            }
        }
    }
}

private struct RouteMapStaticSignature: Hashable {
    let path: [GeoCoordinate]
    let markers: [RouteMarkerPresentation]
}

private struct RouteMapDynamicSignature: Hashable {
    let mode: RouteMapMode
    let highlight: GeoCoordinate?
}

private final class RouteAnnotation: NSObject, MKAnnotation {
    @objc dynamic var coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    let kind: RouteMarkerKind

    init(marker: RouteMarkerPresentation) {
        coordinate = marker.coordinate.clCoordinate
        title = marker.title
        subtitle = marker.subtitle
        kind = marker.kind
    }
}
