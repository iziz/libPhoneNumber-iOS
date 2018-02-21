#!/usr/bin/swift

//
//  metadataGenerator.swift
//  libPhoneNumber-iOS
//
//  Created by Paween Itthipalkul on 2/16/18.
//  Copyright © 2018 Google LLC. All rights reserved.
//

import Darwin
import Foundation
import JavaScriptCore

enum GeneratorError: Error {
  case dataNotString
  case genericError
}

func synchronouslyLoadStringResource(from url: URL) throws -> String {
  let session = URLSession(configuration: .default)
  var resultData: Data?
  var resultError: Error?
  let semaphore = DispatchSemaphore(value: 0)

  let dataTask = session.dataTask(with: url) { data, _, error in
    resultData = data
    resultError = error
    semaphore.signal()
  }
  dataTask.resume()

  semaphore.wait()

  if let error = resultError {
    throw error
  }

  if let data = resultData {
    guard let string = String(data: data, encoding: .utf8) else {
      throw GeneratorError.dataNotString
    }

    return string
  }

  throw GeneratorError.genericError
}

func loadJS(from url: URL, to context: JSContext) {
  guard let script = try? synchronouslyLoadStringResource(from: url) else {
    fputs("Cannot load dependency at \(url)\n", __stderrp)
    exit(1)
  }

  context.evaluateScript(script)
}

// Create JavaScript context.
let context = JSContext()!
context.exceptionHandler = { _, exception in
  fputs("Javascript exception thrown: \(exception!)\n", __stderrp)
//  exit(1)
}

// Load required dependencies.
let googleClosure = URL(
  string: "http://cdn.rawgit.com/google/closure-library/master/closure/goog/base.js")!
loadJS(from: googleClosure, to: context)

let jQuery = URL(string: "http://code.jquery.com/jquery-1.8.3.min.js")!
loadJS(from: jQuery, to: context)

// Evaluate requires.
let requires = """
  goog.require('goog.proto2.Message');
  goog.require('goog.dom');
  goog.require('goog.json');
  goog.require('goog.array');
  goog.require('goog.proto2.ObjectSerializer');
  goog.require('goog.string.StringBuffer');
  goog.require('i18n.phonenumbers.metadata');
  """
context.evaluateScript(requires)

// Load metadata file from GitHub.
let phoneMetadata = URL(string: "https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/metadata.js")!
let phoneMetadataForTesting = URL(string: "https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/metadatafortesting.js")!
let shortNumberMetadata = URL(string: "https://raw.githubusercontent.com/googlei18n/libphonenumber/master/javascript/i18n/phonenumbers/shortnumbermetadata.js")!

let currentDir = FileManager.default.currentDirectoryPath
let baseURL = URL(fileURLWithPath: currentDir).appendingPathComponent("generatedJSON")

// Phone metadata.
do {
  let metadata = try synchronouslyLoadStringResource(from: phoneMetadata)
  context.evaluateScript(metadata)
  let result = context.evaluateScript("JSON.stringify(i18n.phonenumbers.metadata)")!.toString()!
  let url = baseURL.appendingPathComponent("PhoneNumberMetaData.json")
  try result.write(
    to: url,
    atomically: true,
    encoding: .utf8)
  // Clean up
  context.evaluateScript("i18n.phonenumbers.metadata = null")
} catch (let error) {
  fputs("Error loading phone number metadata \(error)\n", __stderrp)
  exit(1)
}

// Phone metadata for testing.
do {
  let metadata = try synchronouslyLoadStringResource(from: phoneMetadataForTesting)
  context.evaluateScript(metadata)
  let result = context.evaluateScript("JSON.stringify(i18n.phonenumbers.metadata)")!.toString()!
  let url = baseURL.appendingPathComponent("PhoneNumberMetaDataForTesting.json")
  try result.write(
    to: url,
    atomically: true,
    encoding: .utf8)
} catch (let error) {
  fputs("Error loading phone number metadata for testing \(error)\n", __stderrp)
  exit(1)
}

// Short number metadata.
do {
  let metadata = try synchronouslyLoadStringResource(from: shortNumberMetadata)
  context.evaluateScript(metadata)
  let result = context.evaluateScript(
    "JSON.stringify(i18n.phonenumbers.shortnumbermetadata)")!.toString()!
  let url = baseURL.appendingPathComponent("ShortNumberMetadata.json")
  try result.write(
    to: url,
    atomically: true,
    encoding: .utf8)
} catch (let error) {
  fputs("Error loading short number metadata \(error)\n", __stderrp)
  exit(1)
}

print("Done")
