![Logo Syncthing](https://syncthing.net/images/logo-horizontal.svg)

# Syncthing GUI for Mac

This is a Mac OS GUI for [Syncthing](https://syncthing.net) (an open-source, P2P, file syncing software on [GitHub](https://github.com/syncthing/syncthing)), made in Swift. 

Interactions with the REST API are following the [documentation](http://docs.syncthing.net/dev/rest.html).

I'm nowhere near experienced in Swift, and this project was intended as a way to learn Mac OS app development. Please excuse my use of the French language in the code, I didn't intend to share the code at first.

## Building

This project uses Swift 2.0 syntax. You'll need Xcode 7 to build it.

Open `Syncthing GUI.xcworkspace` and build. 

**Do not use `Syncthing GUI.xcodeproj` for building** 

This project uses [Cocoapods](https://cocoapods.org) to manage librairies, but everything is commited to the git repository, so **building should be as easy as pressing "Build" in Xcode** after a `git pull`.

### Current librairies in use:

1. **[Alamofire](https://github.com/Alamofire/Alamofire)** --- an HTTP networking library
2. **[SwiftyJSON](https://github.com/SwiftyJSON/SwiftyJSON)** --- a JSON manipulation library

## Status

### Operational:

* Syncthing communication system
* Basic folder layout
* Settings panel
* Periodic refresh (1 sec when front window)

### Broken: 

* The refresh button on the toolbar
* Path representation for Remote syncthing servers
* "Out of Sync" status (I just didn't implement it)

### WIP:

* File list view
* Periodic refresh in background

## Programming

Here I'll write the main ideas behind the structure of the code:

* Syncthing objects are in the `SyncthingObject.swift` file. The documentation doesn't provide very accurate descriptions, so (almost) all objects are based on examples from the documentation.
* The `RestApi.swift` file handles the REST interactions. It uses one main function that handles `GET` and `POST` requests to interact with Syncthing. They are called by functions that provide a callback function. 
* For ambiguous classes, variables and functions, I use the following syntax so that Xcode knows how to document the Quick Help : 

```swift
/** 
Description 

-parameter parameter1: Description
-returns returnType: Description
*/
func name(parameter1: Type...) -> ReturnType { ... }
``` 

* The `CustomStringConvertible` class provides the `var description: String` variable for use with log commands like `NSLog` and `print`.

## License

<center><a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a></br>
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/).
</center>