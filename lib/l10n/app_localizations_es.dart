// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'DocScanner';

  @override
  String get scanDocument => 'Escanear documento';

  @override
  String get scan => 'Escanear';

  @override
  String scanNPages(int count) {
    return 'Escanear ($count página)';
  }

  @override
  String scanNPages_plural(int count) {
    return 'Escanear ($count páginas)';
  }

  @override
  String get back => 'Atrás';

  @override
  String get torchOn => 'Linterna encendida';

  @override
  String get torchOff => 'Linterna apagada';

  @override
  String get torchNotAvailable => 'Linterna no disponible en este dispositivo';

  @override
  String get bwMode => 'Modo B/N';

  @override
  String get colorMode => 'Modo color';

  @override
  String get doneScanning => 'Finalizar escaneo';

  @override
  String get capturePhoto => 'Capturar foto';

  @override
  String get cameraPermissionDenied =>
      'El permiso de cámara fue denegado permanentemente. Actívalo en los ajustes de la app.';

  @override
  String get cameraPermissionNeeded => 'Permiso de cámara necesario';

  @override
  String get cameraPermissionRationale =>
      'DocScanner necesita acceso a tu cámara para escanear documentos. No se toman fotos sin tu acción.';

  @override
  String get deny => 'Denegar';

  @override
  String get allow => 'Permitir';

  @override
  String get cameraPermissionRequired =>
      'El permiso de cámara es obligatorio para escanear documentos.';

  @override
  String get noCameraFound => 'No se encontró cámara';

  @override
  String get failedOpenCamera =>
      'Error al abrir la cámara. Inténtalo de nuevo.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String get goBack => 'Volver';

  @override
  String get retry => 'Reintentar';

  @override
  String get discardPages => '¿Descartar páginas?';

  @override
  String discardPagesBody(int count) {
    return 'Tienes $count página en curso. ¿Descartarla?';
  }

  @override
  String discardPagesBody_plural(int count) {
    return 'Tienes $count páginas en curso. ¿Descartarlas?';
  }

  @override
  String get stay => 'Permanecer';

  @override
  String get discard => 'Descartar';

  @override
  String get failedProcessPage =>
      'Error al procesar la página. Inténtalo de nuevo.';

  @override
  String get failedCapture =>
      'Ocurrió un error al capturar. Inténtalo de nuevo.';

  @override
  String get pagesReordered => 'Páginas reordenadas';

  @override
  String get discardChanges => '¿Descartar cambios?';

  @override
  String get discardChangesBody =>
      'Tienes cambios sin guardar en el orden de las páginas.';

  @override
  String get keepEditing => 'Seguir editando';

  @override
  String get reorderPages => 'Reordenar páginas';

  @override
  String get done => 'Hecho';

  @override
  String get selectPages => 'Seleccionar páginas';

  @override
  String get deleteSelected => 'Eliminar seleccionados';

  @override
  String get cancelSelection => 'Cancelar selección';

  @override
  String get cancelReorder => 'Cancelar reorden';

  @override
  String get noPages => 'Sin páginas';

  @override
  String get noPagesBody => 'Este documento no tiene páginas';

  @override
  String get addPage => 'Añadir página';

  @override
  String pageN(int index) {
    return 'Página $index';
  }

  @override
  String get cannotDeleteAllPages =>
      'No puedes eliminar todas las páginas. Elimina el documento en su lugar.';

  @override
  String get noPagesSelected => 'Ninguna página seleccionada';

  @override
  String get deleteDocument => 'Eliminar documento';

  @override
  String get deletePages => 'Eliminar páginas';

  @override
  String deleteNPages(int count) {
    return '¿Eliminar $count página?';
  }

  @override
  String deleteNPages_plural(int count) {
    return '¿Eliminar $count páginas?';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String nPagesDeleted(int count) {
    return '$count página eliminada';
  }

  @override
  String nPagesDeleted_plural(int count) {
    return '$count páginas eliminadas';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get selectDocuments => 'Seleccionar documentos';

  @override
  String nSelected(int count) {
    return '$count seleccionados';
  }

  @override
  String get deselectAll => 'Deseleccionar todo';

  @override
  String get selectAll => 'Seleccionar todo';

  @override
  String get changeTheme => 'Cambiar tema';

  @override
  String get themeMode => 'Modo de tema';

  @override
  String get exportPdf => 'Exportar PDF';

  @override
  String get showOnboarding => 'Mostrar introducción';

  @override
  String get somethingWentWrong => 'Algo salió mal';

  @override
  String get searchDocuments => 'Buscar documentos...';

  @override
  String get clearSearch => 'Limpiar búsqueda';

  @override
  String get noDocumentsMatch => 'Sin documentos coincidentes';

  @override
  String get scanADocument => 'Escanear un documento';

  @override
  String get deleteDocuments => 'Eliminar documentos';

  @override
  String deleteNDocuments(int count) {
    return '¿Eliminar $count documento? Esta acción no se puede deshacer.';
  }

  @override
  String deleteNDocuments_plural(int count) {
    return '¿Eliminar $count documentos? Esta acción no se puede deshacer.';
  }

  @override
  String nDocumentsDeleted(int count) {
    return '$count documento eliminado';
  }

  @override
  String nDocumentsDeleted_plural(int count) {
    return '$count documentos eliminados';
  }

  @override
  String get undo => 'Deshacer';

  @override
  String get pagesAdded => 'Páginas añadidas';

  @override
  String get documentSaved => 'Documento guardado';

  @override
  String get renameDocument => 'Renombrar documento';

  @override
  String get documentName => 'Nombre del documento';

  @override
  String get rename => 'Renombrar';

  @override
  String deleteDocumentConfirm(String name) {
    return '¿Estás seguro de que quieres eliminar \"$name\"?';
  }

  @override
  String nameDeleted(String name) {
    return '\"$name\" eliminado';
  }

  @override
  String get generatingPdf => 'Generando PDF...';

  @override
  String get failedExportPdf => 'Error al exportar PDF. Inténtalo de nuevo.';

  @override
  String get auto => 'Automático';

  @override
  String get light => 'Claro';

  @override
  String get dark => 'Oscuro';

  @override
  String get noDocumentsYet => 'Aún no hay documentos';

  @override
  String get scanFirstDocument => 'Escanea tu primer documento\npara empezar';

  @override
  String get arcade => 'Arcade';

  @override
  String get kawaii => 'Kawaii';

  @override
  String get professional => 'Profesional';

  @override
  String get textExtractionFailed =>
      'Error al extraer texto. Inténtalo de nuevo.';

  @override
  String get extractedText => 'Texto extraído';

  @override
  String nTextBlocksFound(int count) {
    return '$count bloque de texto encontrado';
  }

  @override
  String nTextBlocksFound_plural(int count) {
    return '$count bloques de texto encontrados';
  }

  @override
  String get copyToClipboard => 'Copiar al portapapeles';

  @override
  String get textCopiedToClipboard => 'Texto copiado al portapapeles';

  @override
  String get preview => 'Vista previa';

  @override
  String get discardCropChanges =>
      'Has ajustado el área de recorte. ¿Quieres descartar los cambios?';

  @override
  String get adjustAndConfirm => 'Ajustar y confirmar';

  @override
  String get resetCorners => 'Restablecer esquinas';

  @override
  String get extractTextFromPage => 'Extraer texto de esta página';

  @override
  String get takePhotoAgain => 'Volver a tomar foto';

  @override
  String get saveScan => 'Guardar escaneo';

  @override
  String get processingFailedUsingOriginal =>
      'Error al procesar. Usando imagen original.';

  @override
  String get failedProcessImage =>
      'Error al procesar la imagen. Inténtalo de nuevo.';

  @override
  String reviewNPages(int count) {
    return 'Revisar ($count página)';
  }

  @override
  String reviewNPages_plural(int count) {
    return 'Revisar ($count páginas)';
  }

  @override
  String get deleteAll => 'Eliminar todo';

  @override
  String get saving => 'Guardando...';

  @override
  String get saveAsDocument => 'Guardar como documento';

  @override
  String get deleteAllPages => '¿Eliminar todas las páginas?';

  @override
  String get deleteAllPagesBody =>
      'Todas las páginas capturadas serán descartadas.';

  @override
  String get saveAs => 'Guardar como';

  @override
  String documentAlreadyExists(String name) {
    return 'Ya existe un documento llamado \"$name\".';
  }

  @override
  String get save => 'Guardar';

  @override
  String nKb(int size) {
    return '$size KB';
  }

  @override
  String get editPage => 'Editar página';

  @override
  String get deletePage => 'Eliminar página';

  @override
  String get failedSaveDocument =>
      'Error al guardar el documento. Inténtalo de nuevo.';

  @override
  String get onboardingScanTitle => 'Escanea documentos';

  @override
  String get onboardingScanDesc =>
      'Captura documentos con tu cámara. Recorta y mejóralos automáticamente.';

  @override
  String get onboardingAdjustTitle => 'Ajusta y refina';

  @override
  String get onboardingAdjustDesc =>
      'Ajusta las esquinas, la perspectiva y mejora la imagen para un escaneo nítido.';

  @override
  String get onboardingOcrTitle => 'Extrae texto';

  @override
  String get onboardingOcrDesc =>
      'Extrae texto de cualquier documento escaneado. Solo tienes que tocar y copiar.';

  @override
  String get onboardingExportTitle => 'Exporta y comparte';

  @override
  String get onboardingExportDesc =>
      'Exporta documentos como PDF, renómbralos o compártelos directamente desde la app.';

  @override
  String get skip => 'Saltar';

  @override
  String get getStarted => 'Comenzar';

  @override
  String get next => 'Siguiente';

  @override
  String get tapToReload => 'Toca para recargar';

  @override
  String nPages(int count) {
    return '$count página';
  }

  @override
  String nPages_plural(int count) {
    return '$count páginas';
  }

  @override
  String get renameLabel => 'Renombrar';

  @override
  String viewPages(int count) {
    return 'Ver páginas ($count)';
  }

  @override
  String get share => 'Compartir';

  @override
  String get nameCannotBeEmpty => 'El nombre no puede estar vacío';

  @override
  String get nameTooLong => 'El nombre es demasiado largo';

  @override
  String get nameInvalidChars => 'El nombre contiene caracteres no válidos';

  @override
  String get jan => 'Ene';

  @override
  String get feb => 'Feb';

  @override
  String get mar => 'Mar';

  @override
  String get apr => 'Abr';

  @override
  String get may => 'May';

  @override
  String get jun => 'Jun';

  @override
  String get jul => 'Jul';

  @override
  String get aug => 'Ago';

  @override
  String get sep => 'Sep';

  @override
  String get oct => 'Oct';

  @override
  String get nov => 'Nov';

  @override
  String get dec => 'Dic';
}
