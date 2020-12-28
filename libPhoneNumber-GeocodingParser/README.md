# **libPhoneNumber-iOS Geocoding File Parser**

An Objective-C program that converts Google's libPhoneNumber geocoding information into SQLite databases that 
can be used in the libPhoneNumber-iOS library for geocoding functionality. This program downloads Google's
libPhoneNumber repository and iterates through each language folder of geocoding metadata and creates an 
individual SQLite database file for each language. The program creates individual tables for each country code of 
geocoding region data provided for each language. 

## Usage

This program has 1 required input arguments for ```main.m```:

1) The local system directory path to the desired destination to save the SQLite database files.
Example: /Users/JohnDoe/Documents

## Updating libPhoneNumber-iOS GeocodingMetadata.bundle 

libPhoneNumber's geocoding metadata files are periodically updated by contributors. Please fetch the most recently
updated geocoding data files by using this program and replace the current database files in 
GeocodingMetadata.bundle, found in the [libPhoneNumberGeocoding target](https://github.com/iziz/libPhoneNumber-iOS/tree/master/libPhoneNumberGeocoding/Metadata).

Please contribute to libPhoneNumber-iOS library by creating a pull request to replace outdated databases with the
up-to-date SQLite databases produced by this program. 


##### Visit [libphonenumber](https://github.com/google/libphonenumber) for more information
