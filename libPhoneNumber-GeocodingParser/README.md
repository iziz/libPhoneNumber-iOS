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

## Updating libPhoneNumber-iOS GeocodingMetaData.bundle 

libPhoneNumber's geocoding metadata files are periodically updated by contributors. Please fetch the most recently
updated geocoding data files by using this program and replace the current database files in 
GeocodingMetaData.bundle, found in the [libPhoneNumberGeocoding target](https://github.com/iziz/libPhoneNumber-iOS/tree/master/libPhoneNumberGeocodingMetaData).

Please contribute to libPhoneNumber-iOS library by creating a pull request to replace outdated databases with the
up-to-date SQLite databases produced by this program. 


##### Visit [libphonenumber](https://github.com/google/libphonenumber) for more information

### Update Steps
1. Open the libPhoneNumber-GeocodingParser project in Xcode
2. Edit the libPhoneNumber-GeocodingParser Scheme
3. In the `Run` section go to the `Arguments` tab
4. Edit the version argument to be the desired version number
5. Add an argument specifying the output directory (ex. `/Users/john.doe/geocoding`)
6. Run the libPhoneNumber-GeocodingParser program in Xcode (`Cmd+R`) on your machine
7. Wait a few minutes for the program to complete
8. Copy the `*.db` files from your specified output directory to `libPhoneNumberGeocodingMetaData/GeocodingMetaData.bundle`
