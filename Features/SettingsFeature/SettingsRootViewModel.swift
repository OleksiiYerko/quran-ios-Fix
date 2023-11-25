//
//  SettingsRootViewModel.swift
//
//
//  Created by Mohamed Afifi on 2023-06-26.
//

import Analytics
import AudioDownloadsFeature
import Combine
import Localization
import NoorUI
import QuranAudio
import QuranAudioKit
import ReadingSelectorFeature
import SettingsService
import TranslationsFeature
import UIKit
import UIx
import VLogging

@MainActor
final class SettingsRootViewModel: ObservableObject {
    // MARK: Lifecycle

    init(
        analytics: AnalyticsLibrary,
        reviewService: ReviewService,
        audioDownloadsBuilder: AudioDownloadsBuilder,
        translationsListBuilder: TranslationsListBuilder,
        readingSelectorBuilder: ReadingSelectorBuilder,
        navigationController: UINavigationController
    ) {
        theme = themeService.theme
        audioEnd = audioPreferences.audioEnd
        self.analytics = analytics
        self.reviewService = reviewService
        self.audioDownloadsBuilder = audioDownloadsBuilder
        self.translationsListBuilder = translationsListBuilder
        self.readingSelectorBuilder = readingSelectorBuilder
        self.navigationController = navigationController

        themeService.themePublisher.assign(to: &$theme)
        audioPreferences.$audioEnd.assign(to: &$audioEnd)
    }

    // MARK: Internal

    let analytics: AnalyticsLibrary
    let reviewService: ReviewService
    let audioDownloadsBuilder: AudioDownloadsBuilder
    let translationsListBuilder: TranslationsListBuilder
    let readingSelectorBuilder: ReadingSelectorBuilder

    let contactUsService = ContactUsService()
    let themeService = ThemeService.shared
    let audioPreferences = AudioPreferences.shared

    weak var navigationController: UINavigationController?

    @Published var audioEnd: AudioEnd

    @Published var theme: Theme {
        didSet {
            themeService.theme = theme
        }
    }

    func navigateToAudioEndSelector() {
        logger.info("Settings: presentAudioEndSelector")
        showSingleChoiceSelector(
            title: l("audio.download-play-amount"),
            sections: [SingleChoiceSection(
                header: l("audio.download-play-amount.description"),
                items: [AudioEnd.juz, .sura, .page]
            )],
            selected: audioPreferences.audioEnd,
            itemText: { $0.name },
            onSelection: { [weak self] item in
                self?.audioPreferences.audioEnd = item
            }
        )
    }

    func navigateToAudioManager() {
        logger.info("Settings: presentAudioDownloads")
        let viewController = audioDownloadsBuilder.build()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func navigateToTranslationsList() {
        logger.info("Settings: presentTranslationsList")
        let viewController = translationsListBuilder.build()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func navigateToReadingSelectors() {
        logger.info("Settings: navigateToReadingSelectors")
        let viewController = readingSelectorBuilder.build()
        navigationController?.pushViewController(viewController, animated: true)
    }

    func shareApp() {
        logger.info("Settings: Share the app.")
        let url = URL(validURL: "https://itunes.apple.com/app/id1118663303")
        let appName = "Quran - by Quran.com - قرآن"

        let activityViewController = UIActivityViewController(
            activityItems: [appName, url], applicationActivities: nil
        )
        let view = navigationController?.view
        let viewBound = view.map { CGRect(x: $0.bounds.midX, y: $0.bounds.midY, width: 0, height: 0) }
        activityViewController.modalPresentationStyle = .formSheet
        activityViewController.popoverPresentationController?.permittedArrowDirections = []
        activityViewController.popoverPresentationController?.sourceView = view
        activityViewController.popoverPresentationController?.sourceRect = viewBound ?? .zero
        navigationController?.present(activityViewController, animated: true)
    }

    func writeReview() {
        logger.info("Settings: Navigate to app store to write a review.")
        reviewService.openAppReview()
    }

    func contactUs() {
        logger.info("Settings: presentContactUs")
        let viewController = contactUsService.contactUsController()
        navigationController?.present(viewController, animated: true)
    }

    // MARK: Private

    private func showSingleChoiceSelector<T: Hashable>(
        title: String,
        sections: [SingleChoiceSection<T>],
        selected: T?,
        itemText: @escaping (T) -> String,
        onSelection: @escaping (T) -> Void
    ) {
        let viewController = singleChoiceSelector(
            sections: sections,
            selected: selected,
            itemText: itemText,
            onSelection: { [weak self] item in
                onSelection(item)
                self?.navigationController?.popViewController(animated: true)
            }
        )
        viewController.title = title
        navigationController?.pushViewController(viewController, animated: true)
    }
}
