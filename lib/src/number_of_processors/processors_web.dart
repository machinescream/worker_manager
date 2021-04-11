import 'dart:html' show window;

int get numberOfProcessors => window.navigator.hardwareConcurrency ?? 0;
