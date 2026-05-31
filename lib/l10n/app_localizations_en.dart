// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DocScanner';

  @override
  String get scanDocument => 'Scan Document';

  @override
  String get scan => 'Scan';

  @override
  String scanNPages(int count) {
    return 'Scan ($count page)';
  }

  @override
  String scanNPages_plural(int count) {
    return 'Scan ($count pages)';
  }

  @override
  String get back => 'Back';

  @override
  String get torchOn => 'Torch on';

  @override
  String get torchOff => 'Torch off';

  @override
  String get torchNotAvailable => 'Torch not available on this device';

  @override
  String get bwMode => 'B&W mode';

  @override
  String get colorMode => 'Color mode';

  @override
  String get doneScanning => 'Done scanning';

  @override
  String get capturePhoto => 'Capture photo';

  @override
  String get cameraPermissionDenied =>
      'Camera permission is permanently denied. Please enable it in app settings.';

  @override
  String get cameraPermissionNeeded => 'Camera permission needed';

  @override
  String get cameraPermissionRationale =>
      'DocScanner needs access to your camera to scan documents. No photos are taken without your action.';

  @override
  String get deny => 'Deny';

  @override
  String get allow => 'Allow';

  @override
  String get cameraPermissionRequired =>
      'Camera permission is required to scan documents.';

  @override
  String get noCameraFound => 'No camera found';

  @override
  String get failedOpenCamera => 'Failed to open camera. Please try again.';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get goBack => 'Go back';

  @override
  String get retry => 'Retry';

  @override
  String get discardPages => 'Discard pages?';

  @override
  String discardPagesBody(int count) {
    return 'You have $count page in progress. Discard them?';
  }

  @override
  String discardPagesBody_plural(int count) {
    return 'You have $count pages in progress. Discard them?';
  }

  @override
  String get stay => 'Stay';

  @override
  String get discard => 'Discard';

  @override
  String get failedProcessPage => 'Failed to process page. Please try again.';

  @override
  String get failedCapture =>
      'Something went wrong while capturing. Please try again.';

  @override
  String get pagesReordered => 'Pages reordered';

  @override
  String get discardChanges => 'Discard changes?';

  @override
  String get discardChangesBody =>
      'You have unsaved changes to the page order.';

  @override
  String get keepEditing => 'Keep editing';

  @override
  String get reorderPages => 'Reorder pages';

  @override
  String get done => 'Done';

  @override
  String get selectPages => 'Select pages';

  @override
  String get deleteSelected => 'Delete selected';

  @override
  String get cancelSelection => 'Cancel selection';

  @override
  String get cancelReorder => 'Cancel reorder';

  @override
  String get noPages => 'No pages';

  @override
  String get noPagesBody => 'This document has no pages';

  @override
  String get addPage => 'Add page';

  @override
  String pageN(int index) {
    return 'Page $index';
  }

  @override
  String get cannotDeleteAllPages =>
      'Cannot delete all pages. Delete the document instead.';

  @override
  String get noPagesSelected => 'No pages selected';

  @override
  String get deleteDocument => 'Delete document';

  @override
  String get deletePages => 'Delete pages';

  @override
  String deleteNPages(int count) {
    return 'Delete $count page?';
  }

  @override
  String deleteNPages_plural(int count) {
    return 'Delete $count pages?';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String nPagesDeleted(int count) {
    return '$count page deleted';
  }

  @override
  String nPagesDeleted_plural(int count) {
    return '$count pages deleted';
  }

  @override
  String get delete => 'Delete';

  @override
  String get selectDocuments => 'Select documents';

  @override
  String nSelected(int count) {
    return '$count selected';
  }

  @override
  String get deselectAll => 'Deselect all';

  @override
  String get selectAll => 'Select all';

  @override
  String get changeTheme => 'Change theme';

  @override
  String get themeMode => 'Theme mode';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get showOnboarding => 'Show onboarding';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get searchDocuments => 'Search documents...';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get noDocumentsMatch => 'No documents match';

  @override
  String get scanADocument => 'Scan a document';

  @override
  String get deleteDocuments => 'Delete documents';

  @override
  String deleteNDocuments(int count) {
    return 'Delete $count document? This cannot be undone.';
  }

  @override
  String deleteNDocuments_plural(int count) {
    return 'Delete $count documents? This cannot be undone.';
  }

  @override
  String nDocumentsDeleted(int count) {
    return '$count document deleted';
  }

  @override
  String nDocumentsDeleted_plural(int count) {
    return '$count documents deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String get pagesAdded => 'Pages added';

  @override
  String get documentSaved => 'Document saved';

  @override
  String get renameDocument => 'Rename document';

  @override
  String get documentName => 'Document name';

  @override
  String get rename => 'Rename';

  @override
  String deleteDocumentConfirm(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String nameDeleted(String name) {
    return '\"$name\" deleted';
  }

  @override
  String get generatingPdf => 'Generating PDF...';

  @override
  String get failedExportPdf => 'Failed to export PDF. Please try again.';

  @override
  String get auto => 'Auto';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get noDocumentsYet => 'No documents yet';

  @override
  String get scanFirstDocument => 'Scan your first document\nto get started';

  @override
  String get arcade => 'Arcade';

  @override
  String get kawaii => 'Kawaii';

  @override
  String get professional => 'Professional';

  @override
  String get textExtractionFailed =>
      'Text extraction failed. Please try again.';

  @override
  String get extractedText => 'Extracted Text';

  @override
  String nTextBlocksFound(int count) {
    return '$count text block found';
  }

  @override
  String nTextBlocksFound_plural(int count) {
    return '$count text blocks found';
  }

  @override
  String get copyToClipboard => 'Copy to Clipboard';

  @override
  String get textCopiedToClipboard => 'Text copied to clipboard';

  @override
  String get preview => 'Preview';

  @override
  String get discardCropChanges =>
      'You have made adjustments to the crop area. Do you want to discard them?';

  @override
  String get adjustAndConfirm => 'Adjust & Confirm';

  @override
  String get resetCorners => 'Reset corners';

  @override
  String get extractTextFromPage => 'Extract text from this page';

  @override
  String get takePhotoAgain => 'Take photo again';

  @override
  String get saveScan => 'Save scan';

  @override
  String get processingFailedUsingOriginal =>
      'Processing failed. Using original image.';

  @override
  String get failedProcessImage => 'Failed to process image. Please try again.';

  @override
  String reviewNPages(int count) {
    return 'Review ($count page)';
  }

  @override
  String reviewNPages_plural(int count) {
    return 'Review ($count pages)';
  }

  @override
  String get deleteAll => 'Delete all';

  @override
  String get saving => 'Saving...';

  @override
  String get saveAsDocument => 'Save as document';

  @override
  String get deleteAllPages => 'Delete all pages?';

  @override
  String get deleteAllPagesBody => 'All captured pages will be discarded.';

  @override
  String get saveAs => 'Save as';

  @override
  String documentAlreadyExists(String name) {
    return 'A document named \"$name\" already exists.';
  }

  @override
  String get save => 'Save';

  @override
  String nKb(int size) {
    return '$size KB';
  }

  @override
  String get editPage => 'Edit page';

  @override
  String get deletePage => 'Delete page';

  @override
  String get failedSaveDocument => 'Failed to save document. Please try again.';

  @override
  String get onboardingScanTitle => 'Scan Documents';

  @override
  String get onboardingScanDesc =>
      'Capture documents with your camera. Auto-crop and enhance them for a clean result.';

  @override
  String get onboardingAdjustTitle => 'Adjust & Refine';

  @override
  String get onboardingAdjustDesc =>
      'Fine-tune corners, adjust perspective, and enhance the image for a crisp, clean scan.';

  @override
  String get onboardingOcrTitle => 'Extract Text';

  @override
  String get onboardingOcrDesc =>
      'Extract text from any scanned document. Just tap and copy the result.';

  @override
  String get onboardingExportTitle => 'Export & Share';

  @override
  String get onboardingExportDesc =>
      'Export documents as PDF, rename, or share them directly from the app.';

  @override
  String get skip => 'Skip';

  @override
  String get getStarted => 'Get Started';

  @override
  String get next => 'Next';

  @override
  String get tapToReload => 'Tap to reload';

  @override
  String nPages(int count) {
    return '$count page';
  }

  @override
  String nPages_plural(int count) {
    return '$count pages';
  }

  @override
  String get renameLabel => 'Rename';

  @override
  String viewPages(int count) {
    return 'View pages ($count)';
  }

  @override
  String get share => 'Share';

  @override
  String get nameCannotBeEmpty => 'Name cannot be empty';

  @override
  String get nameTooLong => 'Name is too long';

  @override
  String get nameInvalidChars => 'Name contains invalid characters';

  @override
  String get jan => 'Jan';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Apr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Aug';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dec';
}
