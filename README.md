![Logo Syncthing](https://syncthing.net/images/logo-horizontal.svg)

# Syncthing GUI for Mac

This is a Mac OS GUI for [Syncthing](https://syncthing.net) (an open-source, P2P, file syncing software on [GitHub](https://github.com/syncthing/syncthing)), made in Swift. 

Interactions with the REST API are following the [documentation](http://docs.syncthing.net/dev/rest.html).

## Building

This project uses [Cocoapods](https://cocoapods.org) to manage librairies, but everything is commited to the git repository, so **building should be as easy as pressing "Build" in Xcode** after a `git pull`.

## Programming

Here I'll write the main ideas behind the structure of the code:

* Syncthing objects are in the `SyncthingObject.swift` file. The documentation doesn't provide very accurate descriptions, so (almost) all objects are based on examples from the documentation.
* The `RestApi.swift` file handles the REST interactions. It uses two main functions: a `GET` and a `POST` function to interact with Syncthing. They are called by functions that also provide a callback function. 


## License

<center><a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/"><img alt="Creative Commons License" style="border-width:0" src="https://i.creativecommons.org/l/by-nc-sa/4.0/88x31.png" /></a></br>
This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/).
</center>