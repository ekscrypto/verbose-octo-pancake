# verbose-octo-pancake
Demo application to query the Yelp API for searching businesses & view rankings

Specified criteria:
* Use Yelps Business Search API located here: https://www.yelp.ca/developers/documentation/v3/business_search

* Create an app which will allow a user to input a search location. The returned results should be displayed in a list. Each list item should include the business name, a thumbnail image and the amount of stars it has.

Reviewer instructions: 
* In order for this application to work as requested, please update the Secrets.swift file to inject your Yelp API Key
* For security reason, please do not commit your Yelp API Key to the Git repository

Notes:
* Due to limited time, the project is limited to iPhone -- it was not been tested on iPad.
* The "Dependencies" struct (HomeViewModel, YelpQuery) are for dependency injection -- for more information this specific compile-time validation check out https://medium.com/swift2go/swift-di-using-struct-dependencies-d272531f871
* Creative liberty was taken to better showcase the images for each location, so a larger image than a simple thumbnail was used
* Yelp logo downloaded from https://logos-world.net/yelp-logo/
* App icon provided under limited distribution by Encoded.Life - DO NOT USE IN YOUR OWN PROJECTS
