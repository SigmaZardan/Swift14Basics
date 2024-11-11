//
//  HomeScreen.swift
//  Swift14Basics
//
//  Created by Bibek Bhujel on 10/11/2024.
//
import StoreKit
import CoreImage
import CoreImage.CIFilterBuiltins
import CoreImage.CIFilter
import PhotosUI
import SwiftUI

struct HomeScreen: View {
    @State private var processedImage: Image?
    @State private var filterIntensity = 0.5
    @State private var radiusIntensity = 100.0
    @State private var scaleIntensity = 50.0
    @State private var selectedItem: PhotosPickerItem?
    @State private var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    @State private var showFilterOptions = false

    @AppStorage("filterCount") var filterCount = 0
    @Environment(\.requestReview) var requestReview

    var imageSelected: Bool {
        processedImage != nil
    }


    var hasInputScale: Bool {
        currentFilter.attributes["inputScale"] != nil
    }

    var hasInputIntensity: Bool {
        currentFilter.attributes["inputIntensity"] != nil
    }

    var hasInputRadius: Bool {
        currentFilter.attributes["inputRadius"] != nil
    }

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                // image area
                PhotosPicker(selection: $selectedItem){
                    if let processedImage {
                        processedImage
                            .resizable()
                            .scaledToFit()
                    } else {
                        ContentUnavailableView(
                            "No Picture",
                            systemImage: "photo.badge.plus",
                            description: Text("Tap to import a photo")
                        )
                    }
                }.onChange(of: selectedItem, loadImage)
                Spacer()

                if imageSelected {
                    VStack {
                        if hasInputIntensity {
                            VStack {
                                Text("Filter intensity")
                                    .font(.caption)
                                Slider(value: $filterIntensity)
                                    .onChange(of: filterIntensity, applyProcessing)
                            }
                        }

                        if hasInputRadius {
                            VStack {
                                Text("Radius intensity")
                                    .font(.caption)
                                Slider(value: $radiusIntensity, in: 0...200)
                                    .onChange(of: radiusIntensity, applyProcessing)
                            }
                        }


                        if hasInputScale{
                            VStack {
                                Text("Scale intensity")
                                    .font(.caption)
                                Slider(value: $scaleIntensity, in: 0...100)
                                    .onChange(of:scaleIntensity, applyProcessing)
                            }
                        }

                    }.padding()
                }


                HStack {
                    Button("Change Filter", action: changeFilter)
                        .disabled(!imageSelected)

                    Spacer()

                    //share the picture
                    if let processedImage {
                        ShareLink(
                            item: processedImage,
                            preview: SharePreview(
                                "Instafilter image",
                                image: processedImage
                            )
                        )
                    }
                }

            }
            .padding([.horizontal, .bottom])
            .confirmationDialog(
                       "Choose Filter",
                       isPresented: $showFilterOptions,
                       actions:  {
                           Button("Crystallize") { setFilter(CIFilter.crystallize()) }
                           Button("Gaussian Blur") { setFilter(CIFilter.gaussianBlur()) }
                           Button("Pixellate") { setFilter(CIFilter.pixellate()) }
                           Button("Sepia Tone") { setFilter(CIFilter.sepiaTone()) }
                           Button("Unsharp Mask") { setFilter(CIFilter.unsharpMask()) }
                           Button("Vignette") { setFilter(CIFilter.vignette()) }
                           Button("Color Invert") {
                               setFilter(CIFilter.colorInvert())
                           }
                           Button("Comic Effect") {
                               setFilter(CIFilter.comicEffect())
                           }

                           Button("Motion Blur") {
                               setFilter(CIFilter.motionBlur())
                           }
                           Button("Cancel", role: .cancel) { }
                       }
                   )

            .navigationTitle("Instafilter")
        }
    }

    func changeFilter() {
        showFilterOptions = true
    }

     func setFilter(_ filter: CIFilter) {
        currentFilter = filter
         print(currentFilter.attributes["inputScale"] ?? "No input scale")
         print(currentFilter.attributes["inputRadius"] ?? "No input radius")
         print(currentFilter.attributes["inputIntensity"] ?? "No input intensity")
        loadImage()
        // everytiime the user selects a new filter, we increment the filtercount
        filterCount += 1
        if filterCount >= 20 {
            requestReview()
            filterCount = 0
        }
    }


    func loadImage() {
        Task {
            guard let imageData = try await selectedItem?.loadTransferable(
                type: Data.self) else { return }
            guard let inputImage = UIImage(data: imageData) else { return }
            let beginImage = CIImage(image: inputImage)
            currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
            applyProcessing()
        }
    }


    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys

        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey) }
        if inputKeys
            .contains(kCIInputRadiusKey) {
            currentFilter.setValue(radiusIntensity, forKey: kCIInputRadiusKey)
        }
        if inputKeys
            .contains(kCIInputScaleKey) {
            currentFilter.setValue(scaleIntensity, forKey: kCIInputScaleKey)
        }

        guard let outputImage = currentFilter.outputImage else { return }
        guard let cgImage = context.createCGImage(
            outputImage,
            from: outputImage
                .extent) else { return }
                let uiImage = UIImage(cgImage: cgImage)
                processedImage = Image(uiImage: uiImage)
    }
}

#Preview {
    HomeScreen()
}
